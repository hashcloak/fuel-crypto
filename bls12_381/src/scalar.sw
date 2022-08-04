library scalar;

dep choice; 
dep util;

use choice::*;
use util::*;

use core::ops::{Eq, Add, Subtract, Multiply};

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
const R2: Scalar = Scalar{ ls: [
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
const ls: u32 = 32;

const ROOT_OF_UNITY: Scalar = Scalar{ ls: [
    0xb9b5_8d8c_5f0e_466a,
    0x5b1b_4c80_1819_d7ec,
    0x0af5_3ae3_52a3_1e64,
    0x5bf3_adda_19e9_b27b,
]};

impl Scalar {

    pub fn zero() -> Scalar {
        Scalar{ ls: [0, 0, 0, 0]}
    }

    pub fn one() -> Scalar {
        R
    }

    // TODO to make this constant time the u64 should be compared with ct_eq, but is not existing in Sway (yet)
    pub fn eq(self, other: Self) -> bool {
        (self.ls[0] == other.ls[0])
            && (self.ls[1] == other.ls[1])
            && (self.ls[2] == other.ls[2])
            && (self.ls[3] == other.ls[3])
    }

    pub fn sub(self, rhs: Self) -> Self {
        let (d0, borrow) = sbb(self.ls[0], rhs.ls[0], 0);
        let (d1, borrow) = sbb(self.ls[1], rhs.ls[1], borrow);
        let (d2, borrow) = sbb(self.ls[2], rhs.ls[2], borrow);
        let (d3, borrow) = sbb(self.ls[3], rhs.ls[3], borrow);

        // If underflow occurred on the final limb, borrow = 0xfff...fff, otherwise
        // borrow = 0x000.. .ls00. Thus, we use it as a mask to conditionally add the modulus.
        let (d0, carry) = adc(d0, MODULUS_SCALAR.ls[0] & borrow, 0);
        let (d1, carry) = adc(d1, MODULUS_SCALAR.ls[1] & borrow, carry);
        let (d2, carry) = adc(d2, MODULUS_SCALAR.ls[2] & borrow, carry);
        let (d3, _) = adc(d3, MODULUS_SCALAR.ls[3] & borrow, carry);

        Scalar{ ls: [d0, d1, d2, d3]}
    }
}

impl Scalar {

    /// Adds `rhs` to `self`, returning the result.
    pub fn add(self, rhs: Self) -> Self {
        let (d0, carry) = adc(self.ls[0], rhs.ls[0], 0);
        let (d1, carry) = adc(self.ls[1], rhs.ls[1], carry);
        let (d2, carry) = adc(self.ls[2], rhs.ls[2], carry);
        let (d3, _) = adc(self.ls[3], rhs.ls[3], carry);

        // Attempt to subtract the modulus, to ensure the value
        // is smaller than the modulus.
        (Scalar{ls:[d0, d1, d2, d3]}).sub(MODULUS_SCALAR)
    }
}

impl ConditionallySelectable for Scalar {
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        Scalar{ ls: [
            ~u64::conditional_select(a.ls[0], b.ls[0], choice),
            ~u64::conditional_select(a.ls[1], b.ls[1], choice),
            ~u64::conditional_select(a.ls[2], b.ls[2], choice),
            ~u64::conditional_select(a.ls[3], b.ls[3], choice),
        ]}
    }
}

impl Add for Scalar {
    fn add(self, other: Self) -> Self {
        self.add(other)
    }
}