library fp6;

dep fp2;
dep fp;
dep choice; 

use fp::Fp;
use fp2::Fp2;
use choice::{Choice, CtOption};

use core::ops::{Add, Multiply};

pub struct Fp6 {
    c0: Fp2,
    c1: Fp2,
    c2: Fp2,
}


impl Fp6 {
    fn from(f: Fp) -> Fp6 {
        Fp6 {
            c0: ~Fp2::from(f),
            c1: ~Fp2::zero(),
            c2: ~Fp2::zero(),
        }
    }

    fn from(f: Fp2) -> Fp6 {
        Fp6 {
            c0: f,
            c1: ~Fp2::zero(),
            c2: ~Fp2::zero(),
        }
    }

    pub fn zero() -> Self {
        Fp6 {
            c0: ~Fp2::zero(),
            c1: ~Fp2::zero(),
            c2: ~Fp2::zero(),
        }
    }

    pub fn one() -> Self {
        Fp6 {
            c0: ~Fp2::one(),
            c1: ~Fp2::zero(),
            c2: ~Fp2::zero(),
        }
    }/*

//TODO test (but zkcrypto doesnt have a dedicated test, so will be tested implicitly)
    pub fn mul_by_1(self, c1: Fp2) -> Fp6 {
        let b_b = self.c1 * c1;

        let t1 = (self.c1 + self.c2) * c1 - b_b;
        let t1 = t1.mul_by_nonresidue();

        let t2 = (self.c0 + self.c1) * c1 - b_b;

        Fp6 {
            c0: t1,
            c1: t2,
            c2: b_b,
        }
    }
    //TODO: Testing. Has no dedicated tests in zkcrypto
    pub fn mul_by_01(self, c0: Fp2, c1: Fp2) -> Fp6 {
        let a_a = self.c0 * c0;
        let b_b = self.c1 * c1;

        let t1 = (self.c1 + self.c2) * c1 - b_b;
        let t1 = t1.mul_by_nonresidue() + a_a;

        let t2 = (c0 + c1) * (self.c0 +self.c1) - a_a -b_b;

        let t3 = (self.c0 + self.c2) * c0 - a_a + b_b;

        Fp6 {
            c0: t1,
            c1: t2,
            c2: t3,
        }
    }
    */
    //TODO: Testing. Has no dedicated tests in zkcrypto
    pub fn add(self, rhs: Fp6) -> Fp6 {
        Fp6 {
            c0: self.c0 + rhs.c0,
            c1: self.c1 + rhs.c1,
            c2: self.c2 + rhs.c2,
        }
    }
    //TODO: Testing. Has no dedicated tests in zkcrypto
    pub fn sub(self, rhs: Fp6) -> Fp6 {
        Fp6 {
            c0: self.c0 - rhs.c0,
            c1: self.c1 - rhs.c1,
            c2: self.c2 - rhs.c2, 
        }
    }
    //TODO: Testing. Has no dedicated tests in zkcrypto
    pub fn neg(self) -> Fp6 {
        Fp6 {
            c0: self.c0.neg(),
            c1: self.c1.neg(),
            c2: self.c2.neg(),
        }
    }

    // // Is not tested
    // fn conditional_select(a: Fp6, b: Fp6, choice: Choice) -> Fp6 {
    //     Fp6 {
    //         c0: ~Fp2::conditional_select(a.c0, b.c0, choice),
    //         c1: ~Fp2::conditional_select(a.c1, b.c1, choice),
    //         c2: ~Fp2::conditional_select(a.c2, b.c2, choice),
    //     }
    // }
/* Can't compile if this is uncommented atm...
    fn mul_interleaved(self, b: Self) -> Self {
        // The intuition for this algorithm is that we can look at F_p^6 as a direct
        // extension of F_p^2, and express the overall operations down to the base field
        // F_p instead of only over F_p^2. This enables us to interleave multiplications
        // and reductions, ensuring that we don't require double-width intermediate
        // representations (with around twice as many limbs as F_p elements).

        // We want to express the multiplication c = a x b, where a = (a_0, a_1, a_2) is
        // an element of F_p^6, and a_i = (a_i,0, a_i,1) is an element of F_p^2. The fully
        // expanded multiplication is given by (2022-376 §5):
        //
        //   c_0,0 = a_0,0 b_0,0 - a_0,1 b_0,1 + a_1,0 b_2,0 - a_1,1 b_2,1 + a_2,0 b_1,0 - a_2,1 b_1,1
        //                                     - a_1,0 b_2,1 - a_1,1 b_2,0 - a_2,0 b_1,1 - a_2,1 b_1,0.
        //         = a_0,0 b_0,0 - a_0,1 b_0,1 + a_1,0 (b_2,0 - b_2,1) - a_1,1 (b_2,0 + b_2,1)
        //                                     + a_2,0 (b_1,0 - b_1,1) - a_2,1 (b_1,0 + b_1,1).
        //
        //   c_0,1 = a_0,0 b_0,1 + a_0,1 b_0,0 + a_1,0 b_2,1 + a_1,1 b_2,0 + a_2,0 b_1,1 + a_2,1 b_1,0
        //                                     + a_1,0 b_2,0 - a_1,1 b_2,1 + a_2,0 b_1,0 - a_2,1 b_1,1.
        //         = a_0,0 b_0,1 + a_0,1 b_0,0 + a_1,0(b_2,0 + b_2,1) + a_1,1(b_2,0 - b_2,1)
        //                                     + a_2,0(b_1,0 + b_1,1) + a_2,1(b_1,0 - b_1,1).
        //
        //   c_1,0 = a_0,0 b_1,0 - a_0,1 b_1,1 + a_1,0 b_0,0 - a_1,1 b_0,1 + a_2,0 b_2,0 - a_2,1 b_2,1
        //                                                                 - a_2,0 b_2,1 - a_2,1 b_2,0.
        //         = a_0,0 b_1,0 - a_0,1 b_1,1 + a_1,0 b_0,0 - a_1,1 b_0,1 + a_2,0(b_2,0 - b_2,1)
        //                                                                 - a_2,1(b_2,0 + b_2,1).
        //
        //   c_1,1 = a_0,0 b_1,1 + a_0,1 b_1,0 + a_1,0 b_0,1 + a_1,1 b_0,0 + a_2,0 b_2,1 + a_2,1 b_2,0
        //                                                                 + a_2,0 b_2,0 - a_2,1 b_2,1
        //         = a_0,0 b_1,1 + a_0,1 b_1,0 + a_1,0 b_0,1 + a_1,1 b_0,0 + a_2,0(b_2,0 + b_2,1)
        //                                                                 + a_2,1(b_2,0 - b_2,1).
        //
        //   c_2,0 = a_0,0 b_2,0 - a_0,1 b_2,1 + a_1,0 b_1,0 - a_1,1 b_1,1 + a_2,0 b_0,0 - a_2,1 b_0,1.
        //   c_2,1 = a_0,0 b_2,1 + a_0,1 b_2,0 + a_1,0 b_1,1 + a_1,1 b_1,0 + a_2,0 b_0,1 + a_2,1 b_0,0.
        //
        // Each of these is a "sum of products", which we can compute efficiently.

        let a = self;
        let b10_p_b11 = b.c1.c0 + b.c1.c1;
        let b10_m_b11 = b.c1.c0 - b.c1.c1;
        let b20_p_b21 = b.c2.c0 + b.c2.c1;
        let b20_m_b21 = b.c2.c0 - b.c2.c1;

        Fp6 {
            c0: Fp2 {
                c0: ~Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1.neg(), a.c1.c0, a.c1.c1.neg(), a.c2.c0, a.c2.c1.neg()],
                    [b.c0.c0, b.c0.c1, b20_m_b21, b20_p_b21, b10_m_b11, b10_p_b11],
                ),
                c1: ~Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
                    [b.c0.c1, b.c0.c0, b20_p_b21, b20_m_b21, b10_p_b11, b10_m_b11],
                ),
            },
            c1: Fp2 {
                c0: ~Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1.neg(), a.c1.c0, a.c1.c1.neg(), a.c2.c0, a.c2.c1.neg()],
                    [b.c1.c0, b.c1.c1, b.c0.c0, b.c0.c1, b20_m_b21, b20_p_b21],
                ),
                c1: ~Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
                    [b.c1.c1, b.c1.c0, b.c0.c1, b.c0.c0, b20_p_b21, b20_m_b21],
                ),
            },
            c2: Fp2 {
                c0: ~Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1.neg(), a.c1.c0, a.c1.c1.neg(), a.c2.c0, a.c2.c1.neg()],
                    [b.c2.c0, b.c2.c1, b.c1.c0, b.c1.c1, b.c0.c0, b.c0.c1],
                ),
                c1: ~Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
                    [b.c2.c1, b.c2.c0, b.c1.c1, b.c1.c0, b.c0.c1, b.c0.c0],
                ),
            },
        }
    }

    pub fn square(self) -> Fp6 {
        let s0 = self.c0.square();
        let ab = self.c0 * self.c1;
        let s1 = ab + ab;
        let s2 = (self.c0 - self.c1 + self.c2).square();
        let bc = self.c1 * self.c2;
        let s3 = bc + bc;
        let s4 = self.c2.square();

        Fp6 {
            c0: s3.mul_by_nonresidue() + s0,
            c1: s4.mul_by_nonresidue() + s1,
            c2: s1 + s2 + s3 - s0 - s4,
        }
    }*/

    pub fn frobenius_map(self) -> Fp6 {
        let c0 =  (self.c0).frobenius_map();
        let c1 =  (self.c1).frobenius_map();
        let c2 =  (self.c2).frobenius_map();

        // c1 = c1 * (u + 1)^((p - 1) / 3)

        let c1 = c1 * Fp2 {
            c0: ~Fp::zero(),
            c1: ~Fp::from_raw_unchecked([
                0xcd03_c9e4_8671_f071,
                0x5dab_2246_1fcd_a5d2,
                0x5870_42af_d385_1b95,
                0x8eb6_0ebe_01ba_cb9e,
                0x03f9_7d6e_83d0_50d2,
                0x18f0_2065_5463_8741,
            ]),
        };
        let c2 = c2 * Fp2 {
            c0: ~Fp::from_raw_unchecked([
               0x890d_c9e4_8675_45c3,
                0x2af3_2253_3285_a5d5,
                0x5088_0866_309b_7e2c,
                0xa20d_1b8c_7e88_1024,
                0x14e4_f04f_e2db_9068,
                0x14e5_6d3f_1564_853a, 
            ]),
            c1: ~Fp::zero(),
        };

        Fp6 {
            c0, c1, c2
        }
    }
}

impl Add for Fp6 {
    fn add(self, other: Self) -> Self {
        self.add(other)
    }
}

// impl Multiply for Fp6 {
//     fn multiply(self, other: Self) -> Self {
//         self.mul_interleaved(other)
//     }
// }