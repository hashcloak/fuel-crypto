library fp;

use std::{u128::*};

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

// If a >= p, return a-p, else return a
pub fn subtract_p(a: Fp) -> Fp {
    let(r0, borrow) = sbb(a.ls[0], MODULUS[0], 0);
    let(r1, borrow) = sbb(a.ls[1], MODULUS[1], borrow);
    let(r2, borrow) = sbb(a.ls[2], MODULUS[2], borrow);
    let(r3, borrow) = sbb(a.ls[3], MODULUS[3], borrow);
    let(r4, borrow) = sbb(a.ls[4], MODULUS[4], borrow);
    let(r5, borrow) = sbb(a.ls[5], MODULUS[5], borrow);

    // If underflow occurred on the final limb, borrow = 1, otherwise
    // borrow = 0. We convert it into a mask.
    let mut mask = borrow * ~u64::max();
    let r0 = (a.ls[0] & mask) | (r0 & not(mask));
    let r1 = (a.ls[1] & mask) | (r1 & not(mask));
    let r2 = (a.ls[2] & mask) | (r2 & not(mask));
    let r3 = (a.ls[3] & mask) | (r3 & not(mask));
    let r4 = (a.ls[4] & mask) | (r4 & not(mask));
    let r5 = (a.ls[5] & mask) | (r5 & not(mask));

    Fp {
        ls: [r0, r1, r2, r3, r4, r5]
    }
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

impl Fp {
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
        if (self.ls[0] | self.ls[1] | self.ls[2] | self.ls[3] | self.ls[4] | self.ls[5]) == 0 {
            a_is_p = 1; //don't know is there's a native conversion
        } else {
            a_is_p = 0;
        }

        let mask = subtract_wrap_64(a_is_p, 1);

        Fp {
            ls: [d0 & mask, d1 & mask, d2 & mask, d3 & mask, d4 & mask, d5 & mask]
        }
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
        subtract_p(Fp{ls:[d0, d1, d2, d3, d4, d5]})
    }
}

impl Fp {
    fn sub(self, rhs: Fp) -> Fp {
        (rhs.neg()).add(self)
    }
}
