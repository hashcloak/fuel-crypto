library fp;

dep util;

//This wildcard import is needed because of importing ConstantTimeEq for u64 (since it's a trait for a primitive type)
use utils::choice::*; 
use util::*;
use std::{option::Option, u128::U128};
use core::ops::{Eq, Add, Subtract, Multiply};

// Little endian big integer with 6 limbs
// in Montgomery form
pub struct Fp{ls: [u64;6]}

/// p = 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787
pub const MODULUS: [u64; 6] = [
    0xb9fe_ffff_ffff_aaab,
    0x1eab_fffe_b153_ffff,
    0x6730_d2a0_f6b0_f624,
    0x6477_4b84_f385_12bf,
    0x4b1b_a7b6_434b_acd7,
    0x1a01_11ea_397f_e69a,
];

/// INV = -(P^{-1} mod 2^64) mod 2^64
pub const INV: u64 = 0x89f3_fffc_fffc_fffd;

/// R = 2^384 mod p
const R: Fp = Fp{ls: [
    0x7609_0000_0002_fffd,
    0xebf4_000b_c40c_0002,
    0x5f48_9857_53c7_58ba,
    0x77ce_5853_7052_5745,
    0x5c07_1a97_a256_ec6d,
    0x15f6_5ec3_fa80_e493,
]};

/// R2 = 2^(384*2) mod p
const R2: Fp = Fp{ls: [
    0xf4df_1f34_1c34_1746,
    0x0a76_e6a6_09d1_04f1,
    0x8de5_476c_4c95_b6d5,
    0x67eb_88a9_939d_83c0,
    0x9a79_3e85_b519_952d,
    0x1198_8fe5_92ca_e3aa,
]};

/// R3 = 2^(384*3) mod p
const R3: Fp = Fp{ls: [
    0xed48_ac6b_d94c_a1e0,
    0x315f_831e_03a7_adf8,
    0x9a53_352a_615e_29dd,
    0x34c0_4e5e_921e_1761,
    0x2512_d435_6572_4728,
    0x0aa6_3460_9175_5d4d,
]};

impl ConditionallySelectable for Fp {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: Fp, b: Fp, choice: Choice) -> Fp {
        Fp{ ls: [
            ~u64::conditional_select(a.ls[0], b.ls[0], choice),
            ~u64::conditional_select(a.ls[1], b.ls[1], choice),
            ~u64::conditional_select(a.ls[2], b.ls[2], choice),
            ~u64::conditional_select(a.ls[3], b.ls[3], choice),
            ~u64::conditional_select(a.ls[4], b.ls[4], choice),
            ~u64::conditional_select(a.ls[5], b.ls[5], choice),
        ]}
    }
}

// returns the binary not for u64
fn not(input: u64) -> u64 {
    ~u64::max() - input
}

impl ConstantTimeEq for Fp {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Fp) -> Choice {
        ~u64::ct_eq(self.ls[0], other.ls[0])
        & ~u64::ct_eq(self.ls[1], other.ls[1])
        & ~u64::ct_eq(self.ls[2], other.ls[2])
        & ~u64::ct_eq(self.ls[3], other.ls[3])
        & ~u64::ct_eq(self.ls[4], other.ls[4])
        & ~u64::ct_eq(self.ls[5], other.ls[5])
    }
}

impl Fp {
    pub fn zero() -> Fp {
        Fp{ ls: [0, 0, 0, 0, 0, 0] }
    }

    pub fn one() -> Fp {
        R
    }

    // returns -a mod p
    pub fn neg(self) -> Fp {
        let (d0, borrow) = sbb(MODULUS[0], self.ls[0], 0);
        let (d1, borrow) = sbb(MODULUS[1], self.ls[1], borrow);
        let (d2, borrow) = sbb(MODULUS[2], self.ls[2], borrow);
        let (d3, borrow) = sbb(MODULUS[3], self.ls[3], borrow);
        let (d4, borrow) = sbb(MODULUS[4], self.ls[4], borrow);
        let (d5, _) = sbb(MODULUS[5], self.ls[5], borrow);

        // The mask should be 0 when a==p, otherwise 2^65-1 (= 11..11) 
        // limbs = 0 when self = 0
        let limbs = (self.ls[0] | self.ls[1] | self.ls[2] | self.ls[3] | self.ls[4] | self.ls[5]);
        // p mod p = 0, so this checks whether self is p
        // a_is_p = 0 when self = 0, otherwise a_is_p = 1
        let a_is_p: u64 = is_zero_u64(limbs);
        // mask = a_is_p - 1. This will give either 1-1 (=0) or 0-1 (wrap around to 2^64-1)
        let mask = subtract_1_wrap(a_is_p);

        Fp {
            ls: [d0 & mask, d1 & mask, d2 & mask, d3 & mask, d4 & mask, d5 & mask]
        }
    }

    // If a >= p, return a-p, else return a
    pub fn subtract_p(self) -> Fp {
        let (r0, borrow) = sbb(self.ls[0], MODULUS[0], 0);
        let (r1, borrow) = sbb(self.ls[1], MODULUS[1], borrow);
        let (r2, borrow) = sbb(self.ls[2], MODULUS[2], borrow);
        let (r3, borrow) = sbb(self.ls[3], MODULUS[3], borrow);
        let (r4, borrow) = sbb(self.ls[4], MODULUS[4], borrow);
        let (r5, borrow) = sbb(self.ls[5], MODULUS[5], borrow);

        // The final borrow is 11..11 if there was underflow. Otherwise 0. Therefore, it's used as a mask
        let mut mask = borrow;
        let r0 = (self.ls[0] & mask) | (r0 & not(mask));
        let r1 = (self.ls[1] & mask) | (r1 & not(mask));
        let r2 = (self.ls[2] & mask) | (r2 & not(mask));
        let r3 = (self.ls[3] & mask) | (r3 & not(mask));
        let r4 = (self.ls[4] & mask) | (r4 & not(mask));
        let r5 = (self.ls[5] & mask) | (r5 & not(mask));

        Fp {
            ls: [r0, r1, r2, r3, r4, r5]
        }
    }
}

pub fn from_raw_unchecked(v: [u64; 6]) -> Fp {
    Fp{ ls: v }
}

impl Fp {
    // This goes in a separate impl, because if we use previously defined functions in Fp impl, 
    // Sway will not recognize them from inside the same impl

    pub fn is_zero(self) -> Choice {
        self.ct_eq(~Fp::zero())
    }

    /* 
    returns self + rhs mod p. 

    each limbs is added and the possible carry is carried over to next limb
    if needed, 1 reduction by p is done to make it mod p
    */ 
    fn add(self, rhs: Fp) -> Fp {
        let (d0, carry) = adc(self.ls[0], rhs.ls[0], 0);
        let (d1, carry) = adc(self.ls[1], rhs.ls[1], carry);
        let (d2, carry) = adc(self.ls[2], rhs.ls[2], carry);
        let (d3, carry) = adc(self.ls[3], rhs.ls[3], carry);
        let (d4, carry) = adc(self.ls[4], rhs.ls[4], carry);
        let (d5, _) = adc(self.ls[5], rhs.ls[5], carry);

        // Subtract p if necessary, so the element is always mod p
        (Fp{ ls: [d0, d1, d2, d3, d4, d5] }).subtract_p()
    }

    /*
    returns self * rhs mod p

    schoolbook mult, followed by montgomery reduction
    */
    pub fn mul(self, rhs: Fp) -> Fp {
        let self0 = self.ls[0];
        let self1 = self.ls[1];
        let self2 = self.ls[2];
        let self3 = self.ls[3];
        let self4 = self.ls[4];
        let self5 = self.ls[5];

        let rhs0 = rhs.ls[0];
        let rhs1 = rhs.ls[1];
        let rhs2 = rhs.ls[2];
        let rhs3 = rhs.ls[3];
        let rhs4 = rhs.ls[4];
        let rhs5 = rhs.ls[5];

        let (t0, carry) = mac(0, self0, rhs0, 0);
        let (t1, carry) = mac(0, self0, rhs1, carry);
        let (t2, carry) = mac(0, self0, rhs2, carry);
        let (t3, carry) = mac(0, self0, rhs3, carry);
        let (t4, carry) = mac(0, self0, rhs4, carry);
        let (t5, t6) = mac(0, self0, rhs5, carry);

        let (t1, carry) = mac(t1, self1, rhs0, 0);
        let (t2, carry) = mac(t2, self1, rhs1, carry);
        let (t3, carry) = mac(t3, self1, rhs2, carry);
        let (t4, carry) = mac(t4, self1, rhs3, carry);
        let (t5, carry) = mac(t5, self1, rhs4, carry);
        let (t6, t7) = mac(t6, self1, rhs5, carry);

        let (t2, carry) = mac(t2, self2, rhs0, 0);
        let (t3, carry) = mac(t3, self2, rhs1, carry);
        let (t4, carry) = mac(t4, self2, rhs2, carry);
        let (t5, carry) = mac(t5, self2, rhs3, carry);
        let (t6, carry) = mac(t6, self2, rhs4, carry);
        let (t7, t8) = mac(t7, self2, rhs5, carry);

        let (t3, carry) = mac(t3, self3, rhs0, 0);
        let (t4, carry) = mac(t4, self3, rhs1, carry);
        let (t5, carry) = mac(t5, self3, rhs2, carry);
        let (t6, carry) = mac(t6, self3, rhs3, carry);
        let (t7, carry) = mac(t7, self3, rhs4, carry);
        let (t8, t9) = mac(t8, self3, rhs5, carry);

        let (t4, carry) = mac(t4, self4, rhs0, 0);
        let (t5, carry) = mac(t5, self4, rhs1, carry);
        let (t6, carry) = mac(t6, self4, rhs2, carry);
        let (t7, carry) = mac(t7, self4, rhs3, carry);
        let (t8, carry) = mac(t8, self4, rhs4, carry);
        let (t9, t10) = mac(t9, self4, rhs5, carry);

        let (t5, carry) = mac(t5, self5, rhs0, 0);
        let (t6, carry) = mac(t6, self5, rhs1, carry);
        let (t7, carry) = mac(t7, self5, rhs2, carry);
        let (t8, carry) = mac(t8, self5, rhs3, carry);
        let (t9, carry) = mac(t9, self5, rhs4, carry);
        let (t10, t11) = mac(t10, self5, rhs5, carry);

        let res: [u64;12] = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11];
        montgomery_reduce(res)
    }

    // returns self^2 mod p 
    pub fn square(self) -> Fp {
        let (t1, carry) = mac(0, self.ls[0], self.ls[1], 0);
        let (t2, carry) = mac(0, self.ls[0], self.ls[2], carry);
        let (t3, carry) = mac(0, self.ls[0], self.ls[3], carry);
        let (t4, carry) = mac(0, self.ls[0], self.ls[4], carry);
        let (t5, t6) = mac(0, self.ls[0], self.ls[5], carry);

        let (t3, carry) = mac(t3, self.ls[1], self.ls[2], 0);
        let (t4, carry) = mac(t4, self.ls[1], self.ls[3], carry);
        let (t5, carry) = mac(t5, self.ls[1], self.ls[4], carry);
        let (t6, t7) = mac(t6, self.ls[1], self.ls[5], carry);

        let (t5, carry) = mac(t5, self.ls[2], self.ls[3], 0);
        let (t6, carry) = mac(t6, self.ls[2], self.ls[4], carry);
        let (t7, t8) = mac(t7, self.ls[2], self.ls[5], carry);

        let (t7, carry) = mac(t7, self.ls[3], self.ls[4], 0);
        let (t8, t9) = mac(t8, self.ls[3], self.ls[5], carry);

        let (t9, t10) = mac(t9, self.ls[4], self.ls[5], 0);

        let t11 = t10 >> 63;
        let t10 = (t10 << 1) | (t9 >> 63);
        let t9 = (t9 << 1) | (t8 >> 63);
        let t8 = (t8 << 1) | (t7 >> 63);
        let t7 = (t7 << 1) | (t6 >> 63);
        let t6 = (t6 << 1) | (t5 >> 63);
        let t5 = (t5 << 1) | (t4 >> 63);
        let t4 = (t4 << 1) | (t3 >> 63);
        let t3 = (t3 << 1) | (t2 >> 63);
        let t2 = (t2 << 1) | (t1 >> 63);
        let t1 = t1 << 1;

        let (t0, carry) = mac(0, self.ls[0], self.ls[0], 0);
        let (t1, carry) = adc(t1, 0, carry);
        let (t2, carry) = mac(t2, self.ls[1], self.ls[1], carry);
        let (t3, carry) = adc(t3, 0, carry);
        let (t4, carry) = mac(t4, self.ls[2], self.ls[2], carry);
        let (t5, carry) = adc(t5, 0, carry);
        let (t6, carry) = mac(t6, self.ls[3], self.ls[3], carry);
        let (t7, carry) = adc(t7, 0, carry);
        let (t8, carry) = mac(t8, self.ls[4], self.ls[4], carry);
        let (t9, carry) = adc(t9, 0, carry);
        let (t10, carry) = mac(t10, self.ls[5], self.ls[5], carry);
        let (t11, _) = adc(t11, 0, carry);

        let res: [u64;12] = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11];
        montgomery_reduce(res)
    }
}

impl Fp {
    // This goes in a separate impl, because if we use previously defined functions in Fp impl, 
    // Sway will not recognize them from inside the same impl

    // returns self - rhs mod p
    fn sub(self, rhs: Fp) -> Fp {
        (rhs.neg()).add(self)
    }

// TODO implement when performing *many* squares is possible
    pub fn pow_vartime(self, by: [u64; 6]) -> Self {
        // let mut res = Self::one();
        // for e in by.iter().rev() {
        //     for i in (0..64).rev() {
        //         res = res.square();

        //         if ((*e >> i) & 1) == 1 {
        //             res *= self;
        //         }
        //     }
        // }
        // res
        ~Fp::zero()
    }

    /*
    returns c = a.zip(b).fold(0, |acc, (a_i, b_i)| acc + a_i * b_i)

    according to zkcrypto this implements Algorithm 2 from Patrick Longa's
    [ePrint 2022-367](https://eprint.iacr.org/2022/367) §3

    EXTRA NOTE: In the zkcrypto repo (Rust) this is implemented as sum_of_products for T, but this is not possible in Sway. Since specifically T=2 and T=6 is used, we implement both of them separately
    */
    pub fn sum_of_products_6(a: [Fp; 6], b: [Fp; 6]) -> Fp { 
        let mut u1 = 0;
        let mut u2 = 0;
        let mut u3 = 0;
        let mut u4 = 0;
        let mut u5 = 0;
        let mut u6 = 0;

        let mut j = 0;
        
        // Algorithm 2, line 3. For all pairs (a_i, b_j) calculate the sum of products
        while j < 6 {
            let mut t0 = u1;
            let mut t1 = u2;
            let mut t2 = u3;
            let mut t3 = u4;
            let mut t4 = u5;
            let mut t5 = u6;
            let mut t6 = 0;            
            
            let mut i = 0;
            while i < 6 {
                let (t0_temp, carry) = mac(t0, a[i].ls[j], b[i].ls[0], 0);
                let (t1_temp, carry) = mac(t1, a[i].ls[j], b[i].ls[1], carry);
                let (t2_temp, carry) = mac(t2, a[i].ls[j], b[i].ls[2], carry);
                let (t3_temp, carry) = mac(t3, a[i].ls[j], b[i].ls[3], carry);
                let (t4_temp, carry) = mac(t4, a[i].ls[j], b[i].ls[4], carry);
                let (t5_temp, carry) = mac(t5, a[i].ls[j], b[i].ls[5], carry);
                let (t6_temp, _) = adc(t6, 0, carry);
                // assigning directly to t0..t6 in the tuples didn't work, so we assign manually here
                t0 = t0_temp;
                t1 = t1_temp;
                t2 = t2_temp;
                t3 = t3_temp;
                t4 = t4_temp;
                t5 = t5_temp;
                t6 = t6_temp;
                i += 1;
            }
            
            // Algorithm 2, lines 4-5
            let k = wrapping_mul(t0, INV);
            let (_, carry) = mac(t0, k, MODULUS[0], 0);
            let (u1_temp, carry) = mac(t1, k, MODULUS[1], carry);
            let (u2_temp, carry) = mac(t2, k, MODULUS[2], carry);
            let (u3_temp, carry) = mac(t3, k, MODULUS[3], carry);
            let (u4_temp, carry) = mac(t4, k, MODULUS[4], carry);
            let (u5_temp, carry) = mac(t5, k, MODULUS[5], carry);
            let (u6_temp, _) = adc(t6, 0, carry);
            // assigning directly to u1..u6 in the tuples didn't work, so we assign manually here
            u1 = u1_temp;
            u2 = u2_temp;
            u3 = u3_temp;
            u4 = u4_temp;
            u5 = u5_temp;
            u6 = u6_temp;
            j += 1;
        }

        // Subtract p if necessary, so the element is always mod p
        (Fp{ ls: [u1, u2, u3, u4, u5, u6] }).subtract_p()
    }

    pub fn sum_of_products_2(a: [Fp; 2], b: [Fp; 2]) -> Fp { 
        let mut u1 = 0;
        let mut u2 = 0;
        let mut u3 = 0;
        let mut u4 = 0;
        let mut u5 = 0;
        let mut u6 = 0;

        let mut j = 0;

        // Algorithm 2, line 3. For all pairs (a_i, b_j) calculate the sum of products
        while j < 6 {
            let mut t0 = u1;
            let mut t1 = u2;
            let mut t2 = u3;
            let mut t3 = u4;
            let mut t4 = u5;
            let mut t5 = u6;
            let mut t6 = 0;            
            
            let mut i = 0;
            while i < 2 {
                let (t0_temp, carry) = mac(t0, a[i].ls[j], b[i].ls[0], 0);
                let (t1_temp, carry) = mac(t1, a[i].ls[j], b[i].ls[1], carry);
                let (t2_temp, carry) = mac(t2, a[i].ls[j], b[i].ls[2], carry);
                let (t3_temp, carry) = mac(t3, a[i].ls[j], b[i].ls[3], carry);
                let (t4_temp, carry) = mac(t4, a[i].ls[j], b[i].ls[4], carry);
                let (t5_temp, carry) = mac(t5, a[i].ls[j], b[i].ls[5], carry);
                let (t6_temp, _) = adc(t6, 0, carry);
                // assigning directly to t0..t6 in the tuples didn't work, so we assign manually here
                t0 = t0_temp;
                t1 = t1_temp;
                t2 = t2_temp;
                t3 = t3_temp;
                t4 = t4_temp;
                t5 = t5_temp;
                t6 = t6_temp;
                i += 1;
            }

            // Algorithm 2, lines 4-5
            let k = wrapping_mul(t0, INV);
            let (_, carry) = mac(t0, k, MODULUS[0], 0);
            let (u1_temp, carry) = mac(t1, k, MODULUS[1], carry);
            let (u2_temp, carry) = mac(t2, k, MODULUS[2], carry);
            let (u3_temp, carry) = mac(t3, k, MODULUS[3], carry);
            let (u4_temp, carry) = mac(t4, k, MODULUS[4], carry);
            let (u5_temp, carry) = mac(t5, k, MODULUS[5], carry);
            let (u6_temp, _) = adc(t6, 0, carry);
            // assigning directly to u1..u6 in the tuples didn't work, so we assign manually here
            u1 = u1_temp;
            u2 = u2_temp;
            u3 = u3_temp;
            u4 = u4_temp;
            u5 = u5_temp;
            u6 = u6_temp;
            j += 1;
        }

        // Subtract p if necessary, so the element is always mod p
        (Fp{ ls: [u1, u2, u3, u4, u5, u6] }).subtract_p()
    }

    /// Returns whether or not this element is strictly lexicographically
    /// larger than its negation.

    // returns whether self > -self, lexographically speaking
    pub fn lexicographically_largest(self) -> Choice {

        // Check whether self >= (p-1)/2. If this is the case, we return "true"
        // Subtract (p-1)/2 + 1. If there is no underflow, self was larger. 


        // Make sure it's mod p
        let tmp = montgomery_reduce(
            [self.ls[0], self.ls[1], self.ls[2], self.ls[3], self.ls[4], self.ls[5], 0, 0, 0, 0, 0, 0,]
        );

        // Subtract (p-1)/2 + 1
        let (_, borrow) = sbb(tmp.ls[0], 0xdcff_7fff_ffff_d556, 0);
        let (_, borrow) = sbb(tmp.ls[1], 0x0f55_ffff_58a9_ffff, borrow);
        let (_, borrow) = sbb(tmp.ls[2], 0xb398_6950_7b58_7b12, borrow);
        let (_, borrow) = sbb(tmp.ls[3], 0xb23b_a5c2_79c2_895f, borrow);
        let (_, borrow) = sbb(tmp.ls[4], 0x258d_d3db_21a5_d66b, borrow);
        let (_, borrow) = sbb(tmp.ls[5], 0x0d00_88f5_1cbf_f34d, borrow);

        // If there was underflow, borrow is 11..11. Otherwise, it is 0. 
        let borrow_u8: u8 = borrow;
        // Return "true" if there was no underflow. Otherwise return "false"
        ~Choice::from(borrow & 1).not()
    }

}

impl Fp {
    // This goes in a separate impl, because if we use previously defined functions in Fp impl, 
    // Sway will not recognize them from inside the same impl

//TODO pow_vartime has to be implemented for this to work
    // returns Some(self^-1 mod p) or None if self == 0
    pub fn invert(self) -> CtOption<Fp> {
        // Exponentiate by p - 2
        let t = self.pow_vartime([
            0xb9fe_ffff_ffff_aaa9,
            0x1eab_fffe_b153_ffff,
            0x6730_d2a0_f6b0_f624,
            0x6477_4b84_f385_12bf,
            0x4b1b_a7b6_434b_acd7,
            0x1a01_11ea_397f_e69a,
        ]);

        ~CtOption::new_from_bool(t, !self.is_zero().unwrap_as_bool())
    }
}

// Eq in Sway requires bool return type
impl Eq for Fp {
    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }
}

impl Add for Fp {
    fn add(self, other: Self) -> Self {
        self.add(other)
    }
}

impl Subtract for Fp {
    fn subtract(self, other: Self) -> Self {
        self.sub(other)
    }
}

impl Multiply for Fp {
    fn multiply(self, other: Self) -> Self {
        self.mul(other)
    }
}

/*
returns t mod p (as Fp)

according to zkcrypto repo this is based on Algorithm 14.32 in Handbook of Applied Cryptography
<http://cacr.uwaterloo.ca/hac/about/chap14.pdf>
*/
pub fn montgomery_reduce(t: [u64;12]) -> Fp {
    let k = wrapping_mul(t[0], INV);

    let r0: (u64, u64) = mac(t[0], k, MODULUS[0], 0);
    let r1: (u64, u64) = mac(t[1], k, MODULUS[1], r0.1);
    let r2: (u64, u64) = mac(t[2], k, MODULUS[2], r1.1);
    let r3: (u64, u64) = mac(t[3], k, MODULUS[3], r2.1);
    let r4: (u64, u64) = mac(t[4], k, MODULUS[4], r3.1);
    let r5: (u64, u64) = mac(t[5], k, MODULUS[5], r4.1);
    let r6_7: (u64, u64) = adc(t[6], 0, r5.1);

    let k = wrapping_mul(r1.0, INV);
    let r0: (u64, u64) = mac(r1.0, k, MODULUS[0], 0);
    let r2: (u64, u64) = mac(r2.0, k, MODULUS[1], r0.1);
    let r3: (u64, u64) = mac(r3.0, k, MODULUS[2], r2.1);
    let r4: (u64, u64) = mac(r4.0, k, MODULUS[3], r3.1);
    let r5: (u64, u64) = mac(r5.0, k, MODULUS[4], r4.1);
    let r6: (u64, u64) = mac(r6_7.0, k, MODULUS[5], r5.1);
    let r7_8: (u64, u64) = adc(t[7], r6_7.1, r6.1);

    let k = wrapping_mul(r2.0, INV);
    let r0: (u64, u64) = mac(r2.0, k, MODULUS[0], 0);
    let r3: (u64, u64) = mac(r3.0, k, MODULUS[1], r0.1);
    let r4: (u64, u64) = mac(r4.0, k, MODULUS[2], r3.1);
    let r5: (u64, u64) = mac(r5.0, k, MODULUS[3], r4.1);
    let r6: (u64, u64) = mac(r6.0, k, MODULUS[4], r5.1);
    let r7: (u64, u64) = mac(r7_8.0, k, MODULUS[5], r6.1);
    let r8_9: (u64, u64) = adc(t[8], r7_8.1, r7.1);

    let k = wrapping_mul(r3.0, INV);
    let r0: (u64, u64) = mac(r3.0, k, MODULUS[0], 0);
    let r4: (u64, u64) = mac(r4.0, k, MODULUS[1], r0.1);
    let r5: (u64, u64) = mac(r5.0, k, MODULUS[2], r4.1);
    let r6: (u64, u64) = mac(r6.0, k, MODULUS[3], r5.1);
    let r7: (u64, u64) = mac(r7.0, k, MODULUS[4], r6.1);
    let r8: (u64, u64) = mac(r8_9.0, k, MODULUS[5], r7.1);
    let r9_10: (u64, u64) = adc(t[9], r8_9.1, r8.1);

    let k = wrapping_mul(r4.0, INV);
    let r0: (u64, u64) = mac(r4.0, k, MODULUS[0], 0);
    let r5: (u64, u64) = mac(r5.0, k, MODULUS[1], r0.1);
    let r6: (u64, u64) = mac(r6.0, k, MODULUS[2], r5.1);
    let r7: (u64, u64) = mac(r7.0, k, MODULUS[3], r6.1);
    let r8: (u64, u64) = mac(r8.0, k, MODULUS[4], r7.1);
    let r9: (u64, u64) = mac(r9_10.0, k, MODULUS[5], r8.1);
    let r10_11: (u64, u64) = adc(t[10], r9_10.1, r9.1);

    let k = wrapping_mul(r5.0, INV);
    let r0: (u64, u64) = mac(r5.0, k, MODULUS[0], 0);
    let r6: (u64, u64) = mac(r6.0, k, MODULUS[1], r0.1);
    let r7: (u64, u64) = mac(r7.0, k, MODULUS[2], r6.1);
    let r8: (u64, u64) = mac(r8.0, k, MODULUS[3], r7.1);
    let r9: (u64, u64) = mac(r9.0, k, MODULUS[4], r8.1);
    let r10: (u64, u64) = mac(r10_11.0, k, MODULUS[5], r9.1);
    let r11_12 = adc(t[11], r10_11.1, r10.1);

    (Fp{ ls: [r6.0, r7.0, r8.0, r9.0, r10.0, r11_12.0] }).subtract_p()
}
