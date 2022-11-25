library fp6;

dep fp2;
dep fp;

use fp::Fp;
use fp2::Fp2;

use utils::choice::{Choice, ConditionallySelectable, ConstantTimeEq, CtOption};
use core::ops::{Add, Eq, Multiply, Subtract};
// Element in F_{p^6}
pub struct Fp6 {
    c0: Fp2,
    c1: Fp2,
    c2: Fp2,
}
impl ConstantTimeEq for Fp6 {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Self) -> Choice {
        self.c0.ct_eq(other.c0) & self.c1.ct_eq(other.c1) & self.c2.ct_eq(other.c2)
    }
}
impl ConditionallySelectable for Fp6 {
    // Select a if choice == 1 or select b if choice == 0, in constant time
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        Fp6 {
            c0: Fp2::conditional_select(a.c0, b.c0, choice),
            c1: Fp2::conditional_select(a.c1, b.c1, choice),
            c2: Fp2::conditional_select(a.c2, b.c2, choice),
        }
    }
}

impl Eq for Fp6 {
    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }
}

impl Add for Fp6 {
    //TODO: Testing. Has no dedicated tests in zkcrypto
    fn add(self, rhs: Fp6) -> Fp6 {
        Fp6 {
            c0: self.c0 + rhs.c0,
            c1: self.c1 + rhs.c1,
            c2: self.c2 + rhs.c2,
        }
    }
}

impl Fp6 {
    fn from(f: Fp) -> Self {//TODO is it possibly to have multiple functions with same name and different arguments?
        Fp6 {
            c0: Fp2::from(f),
            c1: Fp2::zero(),
            c2: Fp2::zero(),
        }
    }
    fn from(f: Fp2) -> Self {
        Fp6 {
            c0: f,
            c1: Fp2::zero(),
            c2: Fp2::zero(),
        }
    }
    fn zero() -> Self {
        Fp6 {
            c0: Fp2::zero(),
            c1: Fp2::zero(),
            c2: Fp2::zero(),
        }
    }
    fn one() -> Self {
        Fp6 {
            c0: Fp2::one(),
            c1: Fp2::zero(),
            c2: Fp2::zero(),
        }
    }

    fn is_zero(self) -> Choice {
        self.c0.is_zero().binary_and(self.c1.is_zero()).binary_and(self.c2.is_zero())
    }

    pub fn mul_by_nonresidue(self) -> Self {
        // Explanation from zkcrypto
        // Given a + bv + cv^2, this produces
        //     av + bv^2 + cv^3
        // but because v^3 = u + 1, we have
        //     c(u + 1) + av + v^2
        Fp6 {
            c0: self.c2.mul_by_nonresidue(),
            c1: self.c0,
            c2: self.c1,
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
    fn neg(self) -> Fp6 {
        Fp6 {
            c0: self.c0.neg(),
            c1: self.c1.neg(),
            c2: self.c2.neg(),
        }
    }

    pub fn mul_interleaved(self, b: Self) -> Self {
        let a = self;
        let b10_p_b11 = b.c1.c0 + b.c1.c1;
        let b10_m_b11 = b.c1.c0 - b.c1.c1;
        let b20_p_b21 = b.c2.c0 + b.c2.c1;
        let b20_m_b21 = b.c2.c0 - b.c2.c1;

        Fp6 {
            c0: Fp2 {
                c0: Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1.neg(), a.c1.c0, a.c1.c1.neg(), a.c2.c0, a.c2.c1.neg()],
                    [b.c0.c0, b.c0.c1, b20_m_b21, b20_p_b21, b10_m_b11, b10_p_b11],
                ),
                c1: Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
                    [b.c0.c1, b.c0.c0, b20_p_b21, b20_m_b21, b10_p_b11, b10_m_b11],
                ),
            },
            c1: Fp2 {
                c0: Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1.neg(), a.c1.c0, a.c1.c1.neg(), a.c2.c0, a.c2.c1.neg()],
                    [b.c1.c0, b.c1.c1, b.c0.c0, b.c0.c1, b20_m_b21, b20_p_b21],
                ),
                c1: Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
                    [b.c1.c1, b.c1.c0, b.c0.c1, b.c0.c0, b20_p_b21, b20_m_b21],
                ),
            },
            c2: Fp2 {
                c0: Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1.neg(), a.c1.c0, a.c1.c1.neg(), a.c2.c0, a.c2.c1.neg()],
                    [b.c2.c0, b.c2.c1, b.c1.c0, b.c1.c1, b.c0.c0, b.c0.c1],
                ),
                c1: Fp::sum_of_products_6(
                    [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
                    [b.c2.c1, b.c2.c0, b.c1.c1, b.c1.c0, b.c0.c1, b.c0.c0],
                ),
            },
        }
    }
}

impl Subtract for Fp6 {
    fn subtract(self, other: Self) -> Self {
        self.sub(other)
    }
}

impl Multiply for Fp6 {
    fn multiply(self, other: Self) -> Self {
        self.mul_interleaved(other)
    }
}

impl Fp6 {
    pub fn square(self) -> Self {
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
    }
}
