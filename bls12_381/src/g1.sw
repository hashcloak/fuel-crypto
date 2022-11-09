library g1;

dep fp;

use fp::{Fp, from_raw_unchecked};
use utils::choice::{Choice, CtOption, ConditionallySelectable, ConstantTimeEq};
use core::ops::{Eq, Add, Subtract};

// Comment from zkcrypto
/// This is an element of $\mathbb{G}_1$ represented in the affine coordinate space.
/// It is ideal to keep elements in this representation to reduce memory usage and
/// improve performance through the use of mixed curve model arithmetic.
///
/// Values of `G1Affine` are guaranteed to be in the $q$-order subgroup unless an
/// "unchecked" API was misused.
pub struct G1Affine {
    x: Fp,
    y: Fp,
    infinity: Choice,
}

pub const B: Fp = from_raw_unchecked([
    0xaa27_0000_000c_fff3,
    0x53cc_0032_fc34_000a,
    0x478f_e97a_6b0a_807f,
    0xb1d3_7ebe_e6ba_24d7,
    0x8ec9_733b_bf78_ab2f,
    0x09d6_4551_3d83_de7e,
]);

fn mul_by_3b(a: Fp) -> Fp {
    let a = a + a; // 2
    let a = a + a; // 4
    a + a + a // 12
}

impl ConstantTimeEq for G1Affine {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Self) -> Choice {
        // Comment from zkcrypto
        // The only cases in which two points are equal are
        // 1. infinity is set on both
        // 2. infinity is not set on both, and their coordinates are equal
        self.infinity.binary_and(other.infinity)
        .binary_or(
                (self.infinity.not())
                .binary_and(other.infinity.not())
                .binary_and(self.x.ct_eq(other.x))
                .binary_and(self.y.ct_eq(other.y))
                )
    }
}

pub trait FROM_PROJ {
    fn from(p: G1Projective) -> Self;
}

fn unwrap_or(input: CtOption<Fp>, default: Fp) -> Fp {
    match input.is_some()  {
        true => input.unwrap(),
        false => default,
    }   
}

//TODO
// - needs fp invert, which is not working yet
// - will use already created fn `unwrap_or` since adding unwrap_or to trait CtOption can't work yet
// impl FROM_PROJ for G1Affine {
//     fn from(p: G1Projective) -> Self {
// ..
//     }
// }

impl ConditionallySelectable for G1Affine {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        G1Affine {
            x: Fp::conditional_select(a.x, b.x, choice),
            y: Fp::conditional_select(a.y, b.y, choice),
            infinity: Choice::conditional_select(a.infinity, b.infinity, choice),
        }
    }
}

impl Eq for G1Affine {
    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }
}

impl G1Affine {
    /// Returns the identity of the group: the point at infinity.
    fn identity() -> G1Affine {
        G1Affine {
            x: Fp::zero(),
            y: Fp::one(),
            infinity: Choice::from(1u8),
        }
    }

    // returns true if this is the point at infinity
    fn is_identity(self) -> Choice {
        self.infinity
    }

    // TODO TEST WHEN POSSIBLE: Uses mul_by_x on G1Projective which uses double, which can't compile
    // fn is_torsion_free(self) -> Choice {
        // Comment from zkcrypto
    //     // Algorithm from Section 6 of https://eprint.iacr.org/2021/1130
    //     // Updated proof of correctness in https://eprint.iacr.org/2022/352
    //     //
    //     // Check that endomorphism_p(P) == -[x^2] P

    //     let minus_x_squared_times_p = from(self).mul_by_x().mul_by_x().neg();
    //     let endomorphism_p = endomorphism(self);
    //     minus_x_squared_times_p.ct_eq(from(endomorphism_p))
    // }

    //Errors to Immediate18TooLarge
    // fn is_on_curve(self) -> Choice {
    //     // y^2 - x^3 ?= 4
    //     (self.y.square() - (self.x.square() * self.x)).ct_eq(B) | self.infinity
    // }

    // returns a fixed generator of the group 
    // see notes of zkcrypto on how this was chosen [here at paragraph `Fixed generators`](https://github.com/zkcrypto/bls12_381/blob/main/src/notes/design.rs)
    fn generator() -> G1Affine {
        G1Affine {
            x: from_raw_unchecked([
                0x5cb3_8790_fd53_0c16,
                0x7817_fc67_9976_fff5,
                0x154f_95c7_143b_a1c1,
                0xf0ae_6acd_f3d0_e747,
                0xedce_6ecc_21db_f440,
                0x1201_7741_9e0b_fb75,
            ]),
            y: from_raw_unchecked([
                0xbaac_93d5_0ce7_2271,
                0x8c22_631a_7918_fd8e,
                0xdd59_5f13_5707_25ce,
                0x51ac_5829_5040_5194,
                0x0e1c_8c3f_ad00_59c0,
                0x0bbc_3efc_5008_a26a,
            ]),
            infinity: Choice::from(0u8),
        }
    }

    // returns negation of point
    fn neg(self) -> G1Affine {//will be tested with subtraction (TODO)
        G1Affine {
            x: self.x,
            y: Fp::conditional_select(self.y.neg(), Fp::one(), self.infinity),
            infinity: self.infinity,
        }
    }
}

// Comment from zkcrypto
/// A nontrivial third root of unity in Fp
pub const BETA: Fp = from_raw_unchecked([
    0x30f1_361b_798a_64e8,
    0xf3b8_ddab_7ece_5a2a,
    0x16a8_ca3a_c615_77f7,
    0xc26a_2ff8_74fd_029b,
    0x3636_b766_6070_1c6e,
    0x051b_a4ab_241b_6160,
]);

// returns new point with coordinates (BETA * x, y)
fn endomorphism(p: G1Affine) -> G1Affine {
    // Comment from zkcrypto
    // Endomorphism of the points on the curve.
    // endomorphism_p(x,y) = (BETA * x, y)
    // where BETA is a non-trivial cubic root of unity in Fq.
    let mut res = p;
    res.x *= BETA;
    res
}

// Element of G1, represented with projective coordinates
pub struct G1Projective {
    x: Fp,
    y: Fp,
    z: Fp,
}


impl G1Projective {
    // Comment from zkcrypto
    /// Returns the identity of the group: the point at infinity.
    fn identity() -> G1Projective {
        G1Projective {
            x: Fp::zero(),
            y: Fp::one(),
            z: Fp::zero(),
        }
    }

    // returns true if self is the point at infinity
    fn is_identity(self) -> Choice {
        self.z.is_zero()
    }

    // returns point negation
    fn neg(self) -> G1Projective { //will be tested with subtraction (TODO)
        G1Projective {
            x: self.x,
            y: self.y.neg(),
            z: self.z,
        }
    }

    //Errors to Immediate18TooLarge
    // fn is_on_curve(self) -> Choice {
    //     // Y^2 Z = X^3 + b Z^3

    //     (self.y.square() * self.z).ct_eq(self.x.square() * self.x + self.z.square() * self.z * B)
    //         | self.z.is_zero()
    // }

    // returns a fixed generator of the group 
    // see notes of zkcrypto on how this was chosen [here at paragraph `Fixed generators`](https://github.com/zkcrypto/bls12_381/blob/main/src/notes/design.rs)
    fn generator() -> G1Projective {
        G1Projective {
            x: from_raw_unchecked([
                0x5cb3_8790_fd53_0c16,
                0x7817_fc67_9976_fff5,
                0x154f_95c7_143b_a1c1,
                0xf0ae_6acd_f3d0_e747,
                0xedce_6ecc_21db_f440,
                0x1201_7741_9e0b_fb75,
            ]),
            y: from_raw_unchecked([
                0xbaac_93d5_0ce7_2271,
                0x8c22_631a_7918_fd8e,
                0xdd59_5f13_5707_25ce,
                0x51ac_5829_5040_5194,
                0x0e1c_8c3f_ad00_59c0,
                0x0bbc_3efc_5008_a26a,
            ]),
            z: Fp::one(),
        }
    }
} 

impl ConditionallySelectable for G1Projective {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        G1Projective {
            x: Fp::conditional_select(a.x, b.x, choice),
            y: Fp::conditional_select(a.y, b.y, choice),
            z: Fp::conditional_select(a.z, b.z, choice),
        }
    }
}

impl Add for G1Projective {

    // return self + rhs
    // Uses Algorithm 7, https://eprint.iacr.org/2015/1060.pdf
    fn add(self, rhs: G1Projective) -> G1Projective {
        let t0 = self.x * rhs.x;
        let t1 = self.y * rhs.y;
        let t2 = self.z * rhs.z;
        let t3 = self.x + self.y;
        let t4 = rhs.x + rhs.y;
        let t3 = t3 * t4;
        let t4 = t0 + t1;
        let t3 = t3 - t4;
        let t4 = self.y + self.z;
        let x3 = rhs.y + rhs.z;
        let t4 = t4 * x3;
        let x3 = t1 + t2;
        let t4 = t4 - x3;
        let x3 = self.x + self.z;
        let y3 = rhs.x + rhs.z;
        let x3 = x3 * y3;
        let y3 = t0 + t2;
        let y3 = x3 - y3;
        let x3 = t0 + t0;
        let t0 = x3 + t0;
        let t2 = mul_by_3b(t2);
        let z3 = t1 + t2;
        let t1 = t1 - t2;
        let y3 = mul_by_3b(y3);
        let x3 = t4 * y3;
        let t2 = t3 * t1;
        let x3 = t2 - x3;
        let y3 = y3 * t0;
        let t1 = t1 * z3;
        let y3 = t1 + y3;
        let t0 = t0 * t3;
        let z3 = z3 * t4;
        let z3 = z3 + t0;

        G1Projective {
            x: x3,
            y: y3,
            z: z3,
        }
    }
}

impl G1Projective {

    // Not able to test this yet, doesn't terminate
    // returns doubling of point
    // uses Algorithm 9, https://eprint.iacr.org/2015/1060.pdf
    fn double(self) -> G1Projective {
        let t0 = self.y.square();
        let z3 = t0 + t0;
        let z3 = z3 + z3;
        let z3 = z3 + z3;
        let t1 = self.y * self.z;
        let t2 = self.z.square();
        let t2 = mul_by_3b(t2);
        let x3 = t2 * z3;
        let y3 = t0 + t2;
        let z3 = t1 * z3;
        let t1 = t2 + t2;
        let t2 = t1 + t2;
        let t0 = t0 - t2;
        let y3 = t0 * y3;
        let y3 = x3 + y3;
        let t1 = self.x * self.y;
        let x3 = t0 * t1;
        let x3 = x3 + x3;

        let tmp = G1Projective {
            x: x3,
            y: y3,
            z: z3,
        };

        G1Projective::conditional_select(tmp, G1Projective::identity(), self.is_identity())
    }

    // returns self added to another point that is in the affine representation
    // Uses Algorithm 8, https://eprint.iacr.org/2015/1060.pdf
    fn add_mixed(self, rhs: G1Affine) -> G1Projective {
        let t0 = self.x * rhs.x;
        let t1 = self.y * rhs.y;
        let t3 = rhs.x + rhs.y;
        let t4 = self.x + self.y;
        let t3 = t3 * t4;
        let t4 = t0 + t1;
        let t3 = t3 - t4;
        let t4 = rhs.y * self.z;
        let t4 = t4 + self.y;
        let y3 = rhs.x * self.z;
        let y3 = y3 + self.x;
        let x3 = t0 + t0;
        let t0 = x3 + t0;
        let t2 = mul_by_3b(self.z);
        let z3 = t1 + t2;
        let t1 = t1 - t2;
        let y3 = mul_by_3b(y3);
        let x3 = t4 * y3;
        let t2 = t3 * t1;
        let x3 = t2 - x3;
        let y3 = y3 * t0;
        let t1 = t1 * z3;
        let y3 = t1 + y3;
        let t0 = t0 * t3;
        let z3 = z3 * t4;
        let z3 = z3 + t0;

        let tmp = G1Projective {
            x: x3,
            y: y3,
            z: z3,
        };

        G1Projective::conditional_select(tmp, self, rhs.is_identity())
    }
}

pub trait FROM_AFF {
    fn from(p: G1Affine) -> Self;
}

impl FROM_AFF for G1Projective {
    fn from(p: G1Affine) -> Self {
        G1Projective {
            x: p.x,
            y: p.y,
            z: Fp::conditional_select(Fp::one(), Fp::zero(), p.infinity),
        }
    }
}

impl ConstantTimeEq for G1Projective {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Self) -> Choice {
        // Comments from zkcrypto
        // Is (xz, yz, z) equal to (x'z', y'z', z') when converted to affine?

        let x1 = self.x * other.z;
        let x2 = other.x * self.z;

        let y1 = self.y * other.z;
        let y2 = other.y * self.z;

        let self_is_zero = self.z.is_zero();
        let other_is_zero = other.z.is_zero();

        // they are equal if:
        // - both points are infinity
        // - neither is infinity, and coordinates are the same
        self_is_zero.binary_and(other_is_zero)
        .binary_or(
            ((Choice::not(self_is_zero)).binary_and(Choice::not(other_is_zero))
                .binary_and(x1.ct_eq(x2).binary_and(y1.ct_eq(y2))))
            )
    }
}

impl Eq for G1Projective {
    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }
}

impl Subtract for G1Projective {
    fn subtract(self, other: Self) -> Self {
        self + (other.neg())
    }
}