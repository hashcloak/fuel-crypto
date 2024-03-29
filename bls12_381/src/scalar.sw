library scalar;

dep util;

use utils::{choice::*, integer_utils::adc}; 
use util::*;

use core::ops::{Eq, Add, Subtract, Multiply};

// element of scalar field Fq
// Montgomery form: aR mod q, where R = 2^256
pub struct Scalar { ls: [u64; 4] }

/// Constant representing the modulus
/// q = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
pub const MODULUS_SCALAR: Scalar = Scalar{ ls: [
    0xffff_ffff_0000_0001,
    0x53bd_a402_fffe_5bfe,
    0x3339_d808_09a1_d805,
    0x73ed_a753_299d_7d48,
]};

/// The modulus as u32 limbs.
const MODULUS_LIMBS_32: [u32; 8] = [
    0x0000_0001,
    0xffff_ffff,
    0xfffe_5bfe,
    0x53bd_a402,
    0x09a1_d805,
    0x3339_d808,
    0x299d_7d48,
    0x73ed_a753,
];

// The number of bits needed to represent the modulus.
const MODULUS_BITS: u32 = 255;

// GENERATOR = 7 
// Explanation from zkcrypto: multiplicative generator of r-1 order, that is also quadratic nonresidue
const GENERATOR: Scalar = Scalar{ ls: [
    0x0000_000e_ffff_fff1,
    0x17e3_63d3_0018_9c0f,
    0xff9c_5787_6f84_57b0,
    0x3513_3220_8fc5_a8c4,
]};

/// INV = -(q^{-1} mod 2^64) mod 2^64
const INV: u64 = 0xffff_fffe_ffff_ffff;

/// R = 2^256 mod q
const R: Scalar = Scalar{ ls: [
    0x0000_0001_ffff_fffe,
    0x5884_b7fa_0003_4802,
    0x998c_4fef_ecbc_4ff5,
    0x1824_b159_acc5_056f,
]};

/// R^2 = 2^512 mod q
pub const R2: Scalar = Scalar{ ls: [
    0xc999_e990_f3f2_9c6d,
    0x2b6c_edcb_8792_5c23,
    0x05d3_1496_7254_398f,
    0x0748_d9d9_9f59_ff11,
]};

/// R^3 = 2^768 mod q
const R3: Scalar = Scalar{ ls: [
    0xc62c_1807_439b_73af,
    0x1b3e_0d18_8cf0_6990,
    0x73d1_3c71_c7b5_f418,
    0x6e2a_5bb9_c8db_33e9,
]};

// 2^S * t = MODULUS - 1 with t odd
const S: u32 = 32;

// Explanation from zkcrypto:
/// GENERATOR^t where t * 2^s + 1 = q
/// with t odd. In other words, this
/// is a 2^s root of unity.
///
/// `GENERATOR = 7 mod q` is a generator
/// of the q - 1 order multiplicative
/// subgroup.
const ROOT_OF_UNITY: Scalar = Scalar{ ls: [
    0xb9b5_8d8c_5f0e_466a,
    0x5b1b_4c80_1819_d7ec,
    0x0af5_3ae3_52a3_1e64,
    0x5bf3_adda_19e9_b27b,
]};

impl ConditionallySelectable for Scalar {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        Scalar{ ls: [
            ~u64::conditional_select(a.ls[0], b.ls[0], choice),
            ~u64::conditional_select(a.ls[1], b.ls[1], choice),
            ~u64::conditional_select(a.ls[2], b.ls[2], choice),
            ~u64::conditional_select(a.ls[3], b.ls[3], choice),
        ]}
    }
}

impl ConstantTimeEq for Scalar {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Self) -> Choice {
        ~u64::ct_eq(self.ls[0], other.ls[0])
        & ~u64::ct_eq(self.ls[1], other.ls[1])
        & ~u64::ct_eq(self.ls[2], other.ls[2])
        & ~u64::ct_eq(self.ls[3], other.ls[3])
    }
}

impl Scalar {
    fn zero() -> Scalar {
        Scalar{ ls: [0, 0, 0, 0]}
    }

    fn one() -> Scalar {
        R
    }

    // returns self - rhs mod q
    fn sub(self, rhs: Self) -> Self {
        let (d0, borrow) = sbb(self.ls[0], rhs.ls[0], 0);
        let (d1, borrow) = sbb(self.ls[1], rhs.ls[1], borrow);
        let (d2, borrow) = sbb(self.ls[2], rhs.ls[2], borrow);
        let (d3, borrow) = sbb(self.ls[3], rhs.ls[3], borrow);

        // The final borrow is 11..11 if there was underflow. Otherwise 0. Therefore, it's used as a mask
        let (d0, carry) = adc(d0, MODULUS_SCALAR.ls[0] & borrow, 0);
        let (d1, carry) = adc(d1, MODULUS_SCALAR.ls[1] & borrow, carry);
        let (d2, carry) = adc(d2, MODULUS_SCALAR.ls[2] & borrow, carry);
        let (d3, _) = adc(d3, MODULUS_SCALAR.ls[3] & borrow, carry);

        Scalar{ ls: [d0, d1, d2, d3]}
    }

    // returns -self mod q
    fn neg(self) -> Self {
        // Explanation from zkcrypto repo
        // Subtract `self` from `MODULUS` to negate. Ignore the final
        // borrow because it cannot underflow; self is guaranteed to
        // be in the field.
        let (d0, borrow) = sbb(MODULUS_SCALAR.ls[0], self.ls[0], 0);
        let (d1, borrow) = sbb(MODULUS_SCALAR.ls[1], self.ls[1], borrow);
        let (d2, borrow) = sbb(MODULUS_SCALAR.ls[2], self.ls[2], borrow);
        let (d3, _) = sbb(MODULUS_SCALAR.ls[3], self.ls[3], borrow);

        // The mask should be 0 when a==p and 2^65-1 otherwise        
        // limbs = 0 when self = 0
        let limbs = self.ls[0] | self.ls[1] | self.ls[2] | self.ls[3];
        // p mod p = 0, so this checks whether self is p
        let scalar_is_0_mod_p = is_zero_u64(limbs);
        // mask = a_is_p - 1. This will give either 1-1 (=0) or 0-1 (wrap around to 2^64-1)
        let mask = subtract_1_wrap(scalar_is_0_mod_p);

        Scalar{ ls: [d0 & mask, d1 & mask, d2 & mask, d3 & mask]}
    }
}

impl Scalar {
    // returns self + rhs mod q
    fn add(self, rhs: Self) -> Self {
        let (d0, carry) = adc(self.ls[0], rhs.ls[0], 0);
        let (d1, carry) = adc(self.ls[1], rhs.ls[1], carry);
        let (d2, carry) = adc(self.ls[2], rhs.ls[2], carry);
        let (d3, _) = adc(self.ls[3], rhs.ls[3], carry);

        // Subtract q to ensure the element is always mod q
        (Scalar{ls:[d0, d1, d2, d3]}).sub(MODULUS_SCALAR)
    }


    /*
    returns t mod q (as Scalar)

    according to zkcrypto repo this is based on Algorithm 14.32 in Handbook of Applied Cryptography
    <http://cacr.uwaterloo.ca/hac/about/chap14.pdf>
    */
    fn montgomery_reduce(
        r0: u64,
        r1: u64,
        r2: u64,
        r3: u64,
        r4: u64,
        r5: u64,
        r6: u64,
        r7: u64,
    ) -> Self {
        let k = wrapping_mul(r0, INV);
        let (_, carry) = mac(r0, k, MODULUS_SCALAR.ls[0], 0);
        let (r1, carry) = mac(r1, k, MODULUS_SCALAR.ls[1], carry);
        let (r2, carry) = mac(r2, k, MODULUS_SCALAR.ls[2], carry);
        let (r3, carry) = mac(r3, k, MODULUS_SCALAR.ls[3], carry);
        let (r4, carry2) = adc(r4, 0, carry);

        let k = wrapping_mul(r1, INV);
        let (_, carry) = mac(r1, k, MODULUS_SCALAR.ls[0], 0);
        let (r2, carry) = mac(r2, k, MODULUS_SCALAR.ls[1], carry);
        let (r3, carry) = mac(r3, k, MODULUS_SCALAR.ls[2], carry);
        let (r4, carry) = mac(r4, k, MODULUS_SCALAR.ls[3], carry);
        let (r5, carry2) = adc(r5, carry2, carry);

        let k = wrapping_mul(r2, INV);
        let (_, carry) = mac(r2, k, MODULUS_SCALAR.ls[0], 0);
        let (r3, carry) = mac(r3, k, MODULUS_SCALAR.ls[1], carry);
        let (r4, carry) = mac(r4, k, MODULUS_SCALAR.ls[2], carry);
        let (r5, carry) = mac(r5, k, MODULUS_SCALAR.ls[3], carry);
        let (r6, carry2) = adc(r6, carry2, carry);

        let k = wrapping_mul(r3, INV);
        let (_, carry) = mac(r3, k, MODULUS_SCALAR.ls[0], 0);
        let (r4, carry) = mac(r4, k, MODULUS_SCALAR.ls[1], carry);
        let (r5, carry) = mac(r5, k, MODULUS_SCALAR.ls[2], carry);
        let (r6, carry) = mac(r6, k, MODULUS_SCALAR.ls[3], carry);
        let (r7, _) = adc(r7, carry2, carry);

        // Subtract q to ensure the element is always mod q
        (Scalar{ ls:[r4, r5, r6, r7]}).sub(MODULUS_SCALAR)
    }
}

impl Scalar {
    // returns self * rhs mod q
    fn mul(self, rhs: Self) -> Self {
        // Schoolbook multiplication
        let (r0, carry) = mac(0, self.ls[0], rhs.ls[0], 0);
        let (r1, carry) = mac(0, self.ls[0], rhs.ls[1], carry);
        let (r2, carry) = mac(0, self.ls[0], rhs.ls[2], carry);
        let (r3, r4) = mac(0, self.ls[0], rhs.ls[3], carry);

        let (r1, carry) = mac(r1, self.ls[1], rhs.ls[0], 0);
        let (r2, carry) = mac(r2, self.ls[1], rhs.ls[1], carry);
        let (r3, carry) = mac(r3, self.ls[1], rhs.ls[2], carry);
        let (r4, r5) = mac(r4, self.ls[1], rhs.ls[3], carry);

        let (r2, carry) = mac(r2, self.ls[2], rhs.ls[0], 0);
        let (r3, carry) = mac(r3, self.ls[2], rhs.ls[1], carry);
        let (r4, carry) = mac(r4, self.ls[2], rhs.ls[2], carry);
        let (r5, r6) = mac(r5, self.ls[2], rhs.ls[3], carry);

        let (r3, carry) = mac(r3, self.ls[3], rhs.ls[0], 0);
        let (r4, carry) = mac(r4, self.ls[3], rhs.ls[1], carry);
        let (r5, carry) = mac(r5, self.ls[3], rhs.ls[2], carry);
        let (r6, r7) = mac(r6, self.ls[3], rhs.ls[3], carry);

        ~Scalar::montgomery_reduce(r0, r1, r2, r3, r4, r5, r6, r7)
    }

    // returns self ^ 2 mod q
    fn square(self) -> Scalar {
        let (r1, carry) = mac(0, self.ls[0], self.ls[1], 0);
        let (r2, carry) = mac(0, self.ls[0], self.ls[2], carry);
        let (r3, r4) = mac(0, self.ls[0], self.ls[3], carry);

        let (r3, carry) = mac(r3, self.ls[1], self.ls[2], 0);
        let (r4, r5) = mac(r4, self.ls[1], self.ls[3], carry);

        let (r5, r6) = mac(r5, self.ls[2], self.ls[3], 0);

        let r7 = r6 >> 63;
        let r6 = (r6 << 1) | (r5 >> 63);
        let r5 = (r5 << 1) | (r4 >> 63);
        let r4 = (r4 << 1) | (r3 >> 63);
        let r3 = (r3 << 1) | (r2 >> 63);
        let r2 = (r2 << 1) | (r1 >> 63);
        let r1 = r1 << 1;

        let (r0, carry) = mac(0, self.ls[0], self.ls[0], 0);
        let (r1, carry) = adc(0, r1, carry);
        let (r2, carry) = mac(r2, self.ls[1], self.ls[1], carry);
        let (r3, carry) = adc(0, r3, carry);
        let (r4, carry) = mac(r4, self.ls[2], self.ls[2], carry);
        let (r5, carry) = adc(0, r5, carry);
        let (r6, carry) = mac(r6, self.ls[3], self.ls[3], carry);
        let (r7, _) = adc(0, r7, carry);

        ~Scalar::montgomery_reduce(r0, r1, r2, r3, r4, r5, r6, r7)
    }

    // returns self + self mod q
    fn double(self) -> Scalar {
        // zkcrypto comment: TODO: This can be achieved more efficiently with a bitshift.
        self.add(self)
    }
}

impl Add for Scalar {
    fn add(self, other: Self) -> Self {
        self.add(other)
    }
}

impl Subtract for Scalar {
    fn subtract(self, other: Self) -> Self {
        self.sub(other)
    }
}

impl Multiply for Scalar {
        fn multiply(self, other: Self) -> Self {
            self.mul(other)
        }
}

impl Eq for Scalar {
    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }
}

impl Scalar {
    fn from(val: u64) -> Scalar {
        Scalar{ ls: [val, 0, 0, 0]} * R2
    }
}

impl Scalar {

    /// Exponentiates `self` by `by`, where `by` is a
    /// little-endian order integer exponent.
    ///
    /// **This operation is variable time with respect
    /// to the exponent.** If the exponent is fixed,
    /// this operation is effectively constant time.
    pub fn pow_vartime(self, by: [u64; 4]) -> Scalar {//TODO implement when possible, this gives an error when called from sqrt
        let mut res = ~Self::one();
        let mut i = 4;
        while i > 0 {
            let e = by[i -1];
            let mut j = 65;
            while j > 0 {
                res = res.square();

                if ((e >> (j-1)) & 1) == 1 {
                    res *= self;
                    // res.mul_assign(self);
                }
                j -= 1;
            }
            i -= 1;
        }
        res
    }
} 

impl Scalar {
/*
functions
- pow_vartime
- sqrt

will give Immediate18TooLarge

(It originally gave the error
error: Internal compiler error: Verification failed: Function anon_11103 return type must match its RET instructions.
Please file an issue on the repository and include the code that triggered this error.

Sept 12: new error = 
error: Internal compiler error: Verification failed: Function one_1 return type must match its RET instructions.
Please file an issue on the repository and include the code that triggered this error.
)
*/

    /// Computes the square root of this element, if it exists.
    pub fn sqrt(self) -> CtOption<Scalar> {
        // Tonelli-Shank's algorithm for q mod 16 = 1
        // https://eprint.iacr.org/2012/685.pdf (page 12, algorithm 5)

        // w = self^((t - 1) // 2)
        //   = self^6104339283789297388802252303364915521546564123189034618274734669823
        let w = self.pow_vartime([
            0x7fff_2dff_7fff_ffff,
            0x04d0_ec02_a9de_d201,
            0x94ce_bea4_199c_ec04,
            0x0000_0000_39f6_d3a9,
        ]);

        // let mut v = S;
        // let mut x = self * w;
        // let mut b = x * w;

        // // Initialize z as the 2^S root of unity.
        // let mut z = ROOT_OF_UNITY;

        // let mut max_v = S;

        // while max_v > 0 {
        //     let mut k = 1;
        //     let mut tmp = b.square();
        //     let mut j_less_than_v: Choice = ~Choice::from(1u8);

        //     let mut j = 2; // j in 2..max_v
        //     while j <= max_v {
        //         let tmp_is_one = ~Choice::from_bool(tmp.eq(~Scalar::one()));
        //         let squared = ~Scalar::conditional_select(tmp, z, tmp_is_one).square();
        //         tmp = ~Scalar::conditional_select(squared, tmp, tmp_is_one);
        //         let new_z = ~Scalar::conditional_select(z, squared, tmp_is_one);
        //         let j_less_than_v_bool = ~Choice::unwrap_as_bool(j_less_than_v) && j != v;
        //         j_less_than_v = ~Choice::from_bool(j_less_than_v_bool);
        //         k = ~u32::conditional_select(j, k, tmp_is_one);
        //         z = ~Scalar::conditional_select(z, new_z, j_less_than_v);

        //         j += 1;
        //     }

        //     let result = x * z;
        //     x = ~Scalar::conditional_select(result, x, ~Choice::from_bool(b.eq(~Scalar::one())));
        //     z = z.square();
        //     b *= z;
        //     v = k;

        //     max_v -= 1;
        // }

        // ~CtOption::new(
        //     x,
        //     (x * x).ct(self), // Only return Some if it's the square root.
        // )
        ~CtOption::new(self, ~Choice::from(1))
    }
}
