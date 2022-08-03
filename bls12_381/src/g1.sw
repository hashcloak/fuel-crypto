library g1;

// Comment from zkcrypto
/// This is an element of $\mathbb{G}_1$ represented in the affine coordinate space.
/// It is ideal to keep elements in this representation to reduce memory usage and
/// improve performance through the use of mixed curve model arithmetic.
///
/// Values of `G1Affine` are guaranteed to be in the $q$-order subgroup unless an
/// "unchecked" API was misused.
pub struct G1Affine {
    pub x: Fp,
    pub y: Fp,
    infinity: Choice,
}

pub struct G1Projective {
    pub x: Fp,
    pub y: Fp,
    pub z: Fp,
}

fn mul_by_3b(a: Fp) -> Fp {
    let a = a + a; // 2
    let a = a + a; // 4
    a + a + a // 12
}

// TODO: trying to get this to work, seems like a good starting point
// fn from(p: G1Projective) -> G1Affine {
//     let zinv = p.z.invert().unwrap_or(~Fp::zero());
//     let x = p.x * zinv;
//     let y = p.y * zinv;

//     let tmp = G1Affine {
//         x,
//         y,
//         infinity: Choice::from(0u8),
//     };

//     G1Affine::conditional_select(&tmp, &G1Affine::identity(), zinv.is_zero())
// }

impl G1Affine {
    /// Returns the identity of the group: the point at infinity.
    pub fn identity() -> G1Affine {
        G1Affine {
            x: Fp::zero(),
            y: Fp::one(),
            infinity: Choice::from(1u8),
        }
    }

    pub fn generator() -> G1Affine {
        G1Affine {
            x: ~Fp::from_raw_unchecked([
                0x5cb3_8790_fd53_0c16,
                0x7817_fc67_9976_fff5,
                0x154f_95c7_143b_a1c1,
                0xf0ae_6acd_f3d0_e747,
                0xedce_6ecc_21db_f440,
                0x1201_7741_9e0b_fb75,
            ]),
            y: ~Fp::from_raw_unchecked([
                0xbaac_93d5_0ce7_2271,
                0x8c22_631a_7918_fd8e,
                0xdd59_5f13_5707_25ce,
                0x51ac_5829_5040_5194,
                0x0e1c_8c3f_ad00_59c0,
                0x0bbc_3efc_5008_a26a,
            ]),
            infinity: ~Choice::from(0u8),
        }
    }
}


impl ConditionallySelectable for G1Projective {
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        G1Projective {
            x: ~Fp::conditional_select(a.x, b.x, choice),
            y: ~Fp::conditional_select(a.y, b.y, choice),
            z: ~Fp::conditional_select(a.z, b.z, choice),
        }
    }
}

impl G1Projective {
    /// Returns the identity of the group: the point at infinity.
    pub fn identity() -> G1Projective {
        G1Projective {
            x: ~Fp::zero(),
            y: ~Fp::one(),
            z: ~Fp::zero(),
        }
    }

    /// Returns a fixed generator of the group. See [`notes::design`](notes/design/index.html#fixed-generators)
    /// for how this generator is chosen.
    pub fn generator() -> G1Projective {
        G1Projective {
            x: ~Fp::from_raw_unchecked([
                0x5cb3_8790_fd53_0c16,
                0x7817_fc67_9976_fff5,
                0x154f_95c7_143b_a1c1,
                0xf0ae_6acd_f3d0_e747,
                0xedce_6ecc_21db_f440,
                0x1201_7741_9e0b_fb75,
            ]),
            y: ~Fp::from_raw_unchecked([
                0xbaac_93d5_0ce7_2271,
                0x8c22_631a_7918_fd8e,
                0xdd59_5f13_5707_25ce,
                0x51ac_5829_5040_5194,
                0x0e1c_8c3f_ad00_59c0,
                0x0bbc_3efc_5008_a26a,
            ]),
            z: ~Fp::one(),
        }
    }
/*
    /// Computes the doubling of this point.
    pub fn double(self) -> G1Projective {
        // Algorithm 9, https://eprint.iacr.org/2015/1060.pdf

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

        ~G1Projective::conditional_select(tmp, G1Projective::identity(), self.is_identity())
    }

    /// Adds this point to another point.
    pub fn add(self, rhs: G1Projective) -> G1Projective {
        // Algorithm 7, https://eprint.iacr.org/2015/1060.pdf

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
*/
}