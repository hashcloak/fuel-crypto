library fp;

use std::{option::*, u128::*, vec::Vec};

// Little endian big integer with 6 limbs
// in Montgomery form (!)
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

fn not(input: u64) -> u64 {
    ~u64::max() - input
}

// TODO rewrite without if branch
// If x >= y: x-y, else max::U128 - (y-x)
pub fn subtract_wrap(x: U128, y: U128) -> U128 {
    if y > x {
        ~U128::max() - (y - x - U128 {
            lower: 1, upper: 0
        })
    } else {
        x - y
    }
}

// TODO rewrite without if branch
// If x >= y: x-y, else max::U64 - (y-x)
pub fn subtract_wrap_64(x: u64, y: u64) -> u64 {
    if y > x {
        ~u64::max() - (y - x - 1)
    } else {
        x - y
    }
}

/// Compute a - (b + borrow), returning the result and the new borrow (0 or 1).
pub fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64) {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let borrow_128: U128 = ~U128::from(0, borrow);

    let res: U128 = subtract_wrap(a_128, b_128 + borrow_128);
    (res.lower, res.upper >> 63) //(result, borrow)
}

//TODO this function is also in edwards25519/src/field_element.sw (called add64). Where do we want to place these overlapping functions?
//returns sum with carry of a and b
pub fn adc(a: u64, b: u64, carry: u64) -> (u64, u64) {
    let a_128: U128 =  ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let carry_128: U128 =  ~U128::from(0, carry);

    let sum: u64 = (a_128 + b_128 + carry_128).lower;
    let carry_res = ((a & b) | ((a | b) & not(sum))) >> 63;

    (sum, carry_res)
}


//returns the result and new carry of a + b*c + carry
pub fn mac(a: u64, b: u64, c: u64, carry: u64) -> (u64, u64) {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let c_128: U128 = ~U128::from(0, c);
    let carry_128: U128 = ~U128::from(0, carry);

    let res: U128 = a_128 + (b_128 * c_128) + carry_128;
    (res.lower, res.upper)
}

//returns a*b mod(2^64)
pub fn multiply_wrap(a: u64, b: u64) -> u64 {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);

    (a_128 * b_128).lower
}

impl Fp {
    pub fn zero() -> Fp {
        Fp{ls: [0, 0, 0, 0, 0, 0]}
    }

    pub fn one() -> Fp {
        R
    }

    // TODO the u64 should be compared with ct_eq, but is not existing in Sway (yet)
    fn ct_eq(self, other: Self) -> bool {
        (self.ls[0] == other.ls[0])
            && (self.ls[1] == other.ls[1])
            && (self.ls[2] == other.ls[2])
            && (self.ls[3] == other.ls[3])
            && (self.ls[4] == other.ls[4])
            && (self.ls[5] == other.ls[5])
    }

    pub fn neg(self) -> Fp {
        let(d0, borrow) = sbb(MODULUS[0], self.ls[0], 0);
        let(d1, borrow) = sbb(MODULUS[1], self.ls[1], borrow);
        let(d2, borrow) = sbb(MODULUS[2], self.ls[2], borrow);
        let(d3, borrow) = sbb(MODULUS[3], self.ls[3], borrow);
        let(d4, borrow) = sbb(MODULUS[4], self.ls[4], borrow);
        let(d5, _) = sbb(MODULUS[5], self.ls[5], borrow);

        // We need a mask that's 0 when a==p and 2^65-1 otherwise
        // TODO improve this
        let mut a_is_p = 0;
        if (self.ls[0] | self.ls[1] | self.ls[2] | self.ls[3] | self.ls[4] | self.ls[5] == 0) {
            a_is_p = 1; //don't know is there's a native conversion
        } else {
            a_is_p = 0;
        }

        let mask = subtract_wrap_64(a_is_p, 1);

        Fp {
            ls: [d0 & mask, d1 & mask, d2 & mask, d3 & mask, d4 & mask, d5 & mask]
        }
    }

    // If a >= p, return a-p, else return a
    pub fn subtract_p(self) -> Fp {
        let(r0, borrow) = sbb(self.ls[0], MODULUS[0], 0);
        let(r1, borrow) = sbb(self.ls[1], MODULUS[1], borrow);
        let(r2, borrow) = sbb(self.ls[2], MODULUS[2], borrow);
        let(r3, borrow) = sbb(self.ls[3], MODULUS[3], borrow);
        let(r4, borrow) = sbb(self.ls[4], MODULUS[4], borrow);
        let(r5, borrow) = sbb(self.ls[5], MODULUS[5], borrow);

        // If underflow occurred on the final limb, borrow = 1, otherwise
        // borrow = 0. We convert it into a mask.
        let mut mask = borrow * ~u64::max();
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

impl Fp {
    pub fn is_zero(self) -> bool {
        self.ct_eq(~Fp::zero())
    }

    fn add(self, rhs: Fp) -> Fp {
        let (d0, carry) = adc(self.ls[0], rhs.ls[0], 0);
        let (d1, carry) = adc(self.ls[1], rhs.ls[1], carry);
        let (d2, carry) = adc(self.ls[2], rhs.ls[2], carry);
        let (d3, carry) = adc(self.ls[3], rhs.ls[3], carry);
        let (d4, carry) = adc(self.ls[4], rhs.ls[4], carry);
        let (d5, _) = adc(self.ls[5], rhs.ls[5], carry);

        // Attempt to subtract the modulus, to ensure the value
        // is smaller than the modulus.
        (Fp{ls:[d0, d1, d2, d3, d4, d5]}).subtract_p()
    }

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

        let(t0, carry) = mac(0, self0, rhs0, 0);
        let(t1, carry) = mac(0, self0, rhs1, carry);
        let(t2, carry) = mac(0, self0, rhs2, carry);
        let(t3, carry) = mac(0, self0, rhs3, carry);
        let(t4, carry) = mac(0, self0, rhs4, carry);
        let(t5, t6) = mac(0, self0, rhs5, carry);

        let(t1, carry) = mac(t1, self1, rhs0, 0);
        let(t2, carry) = mac(t2, self1, rhs1, carry);
        let(t3, carry) = mac(t3, self1, rhs2, carry);
        let(t4, carry) = mac(t4, self1, rhs3, carry);
        let(t5, carry) = mac(t5, self1, rhs4, carry);
        let(t6, t7) = mac(t6, self1, rhs5, carry);

        let(t2, carry) = mac(t2, self2, rhs0, 0);
        let(t3, carry) = mac(t3, self2, rhs1, carry);
        let(t4, carry) = mac(t4, self2, rhs2, carry);
        let(t5, carry) = mac(t5, self2, rhs3, carry);
        let(t6, carry) = mac(t6, self2, rhs4, carry);
        let(t7, t8) = mac(t7, self2, rhs5, carry);

        let(t3, carry) = mac(t3, self3, rhs0, 0);
        let(t4, carry) = mac(t4, self3, rhs1, carry);
        let(t5, carry) = mac(t5, self3, rhs2, carry);
        let(t6, carry) = mac(t6, self3, rhs3, carry);
        let(t7, carry) = mac(t7, self3, rhs4, carry);
        let(t8, t9) = mac(t8, self3, rhs5, carry);

        let(t4, carry) = mac(t4, self4, rhs0, 0);
        let(t5, carry) = mac(t5, self4, rhs1, carry);
        let(t6, carry) = mac(t6, self4, rhs2, carry);
        let(t7, carry) = mac(t7, self4, rhs3, carry);
        let(t8, carry) = mac(t8, self4, rhs4, carry);
        let(t9, t10) = mac(t9, self4, rhs5, carry);

        let(t5, carry) = mac(t5, self5, rhs0, 0);
        let(t6, carry) = mac(t6, self5, rhs1, carry);
        let(t7, carry) = mac(t7, self5, rhs2, carry);
        let(t8, carry) = mac(t8, self5, rhs3, carry);
        let(t9, carry) = mac(t9, self5, rhs4, carry);
        let(t10, t11) = mac(t10, self5, rhs5, carry);

        let res: [u64;12] = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11];
        montgomery_reduce(res)
    }

// TODO fix.
// This is not giving the correct output, but I can't see any difference with the zkcrypto impl
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
    fn sub(self, rhs: Fp) -> Fp {
        (rhs.neg()).add(self)
    }
}

pub fn montgomery_reduce(t: [u64;12]) -> Fp {
    let k = multiply_wrap(t[0], INV);

    let r0: (u64, u64) = mac(t[0], k, MODULUS[0], 0);
    let r1: (u64, u64) = mac(t[1], k, MODULUS[1], r0.1);
    let r2: (u64, u64) = mac(t[2], k, MODULUS[2], r1.1);
    let r3: (u64, u64) = mac(t[3], k, MODULUS[3], r2.1);
    let r4: (u64, u64) = mac(t[4], k, MODULUS[4], r3.1);
    let r5: (u64, u64) = mac(t[5], k, MODULUS[5], r4.1);
    let r6_7: (u64, u64) = adc(t[6], 0, r5.1);

    let k = multiply_wrap(r1.0, INV);
    let r0: (u64, u64) = mac(r1.0, k, MODULUS[0], 0);
    let r2: (u64, u64) = mac(r2.0, k, MODULUS[1], r0.1);
    let r3: (u64, u64) = mac(r3.0, k, MODULUS[2], r2.1);
    let r4: (u64, u64) = mac(r4.0, k, MODULUS[3], r3.1);
    let r5: (u64, u64) = mac(r5.0, k, MODULUS[4], r4.1);
    let r6: (u64, u64) = mac(r6_7.0, k, MODULUS[5], r5.1);
    let r7_8: (u64, u64) = adc(t[7], r6_7.1, r6.1);

    let k = multiply_wrap(r2.0, INV);
    let r0: (u64, u64) = mac(r2.0, k, MODULUS[0], 0);
    let r3: (u64, u64) = mac(r3.0, k, MODULUS[1], r0.1);
    let r4: (u64, u64) = mac(r4.0, k, MODULUS[2], r3.1);
    let r5: (u64, u64) = mac(r5.0, k, MODULUS[3], r4.1);
    let r6: (u64, u64) = mac(r6.0, k, MODULUS[4], r5.1);
    let r7: (u64, u64) = mac(r7_8.0, k, MODULUS[5], r6.1);
    let r8_9: (u64, u64) = adc(t[8], r7_8.1, r7.1);

    let k = multiply_wrap(r3.0, INV);
    let r0: (u64, u64) = mac(r3.0, k, MODULUS[0], 0);
    let r4: (u64, u64) = mac(r4.0, k, MODULUS[1], r0.1);
    let r5: (u64, u64) = mac(r5.0, k, MODULUS[2], r4.1);
    let r6: (u64, u64) = mac(r6.0, k, MODULUS[3], r5.1);
    let r7: (u64, u64) = mac(r7.0, k, MODULUS[4], r6.1);
    let r8: (u64, u64) = mac(r8_9.0, k, MODULUS[5], r7.1);
    let r9_10: (u64, u64) = adc(t[9], r8_9.1, r8.1);

    let k = multiply_wrap(r4.0, INV);
    let r0: (u64, u64) = mac(r4.0, k, MODULUS[0], 0);
    let r5: (u64, u64) = mac(r5.0, k, MODULUS[1], r0.1);
    let r6: (u64, u64) = mac(r6.0, k, MODULUS[2], r5.1);
    let r7: (u64, u64) = mac(r7.0, k, MODULUS[3], r6.1);
    let r8: (u64, u64) = mac(r8.0, k, MODULUS[4], r7.1);
    let r9: (u64, u64) = mac(r9_10.0, k, MODULUS[5], r8.1);
    let r10_11: (u64, u64) = adc(t[10], r9_10.1, r9.1);

    let k = multiply_wrap(r5.0, INV);
    let r0: (u64, u64) = mac(r5.0, k, MODULUS[0], 0);
    let r6: (u64, u64) = mac(r6.0, k, MODULUS[1], r0.1);
    let r7: (u64, u64) = mac(r7.0, k, MODULUS[2], r6.1);
    let r8: (u64, u64) = mac(r8.0, k, MODULUS[3], r7.1);
    let r9: (u64, u64) = mac(r9.0, k, MODULUS[4], r8.1);
    let r10: (u64, u64) = mac(r10_11.0, k, MODULUS[5], r9.1);
    let r11_12 = adc(t[11], r10_11.1, r10.1);

    (Fp { ls: [r6.0, r7.0, r8.0, r9.0, r10.0, r11_12.0]}).subtract_p()
}