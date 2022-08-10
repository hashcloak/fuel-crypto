library fp2;

dep fp;
dep choice; 

use fp::Fp;
use core::ops::{Eq, Add, Subtract, Multiply};
use choice::*; 

pub struct Fp2 {
    c0: Fp,
    c1: Fp,
}

impl ConstantTimeEq for Fp2 {
    fn ct_eq(self, other: Self) -> Choice {
        self.c0.ct_eq(other.c0) & self.c1.ct_eq(other.c1)
    }
}

impl ConditionallySelectable for Fp2 {
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        Fp2 {
            c0: ~Fp::conditional_select(a.c0, b.c0, choice),
            c1: ~Fp::conditional_select(a.c1, b.c1, choice),
        }
    }
}

impl Fp2 {
    fn from(f: Fp) -> Fp2 {
        Fp2 {
            c0: f,
            c1: ~Fp::zero(),
        }
    }

    pub fn zero() -> Fp2 {
        Fp2 {
            c0: ~Fp::zero(),
            c1: ~Fp::zero(),
        }
    }

    pub fn one() -> Fp2 {
        Fp2 {
            c0: ~Fp::one(),
            c1: ~Fp::zero(),
        }
    }

    pub fn is_zero(self) -> Choice {
        self.c0.is_zero().binary_and(self.c1.is_zero())
    }

    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }

/*
    // not tested, gives Immediate18TooLarge error
    pub fn square(self) -> Fp2 {
        // Complex squaring:
        //
        // v0  = c0 * c1
        // c0' = (c0 + c1) * (c0 + \beta*c1) - v0 - \beta * v0
        // c1' = 2 * v0
        //
        // In BLS12-381's F_{p^2}, our \beta is -1 so we
        // can modify this formula:
        //
        // c0' = (c0 + c1) * (c0 - c1)
        // c1' = 2 * c0 * c1

        let a = self.c0 + self.c1;
        let b = self.c0 - self.c1;
        let c = self.c0 + self.c0;

        Fp2 {
            c0: a * b,
            c1: c * self.c1,
        }
    }
  */

    pub fn mul(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: ~Fp::sum_of_products_2([self.c0, self.c1.neg()], [rhs.c0, rhs.c1]),
            c1: ~Fp::sum_of_products_2([self.c0, self.c1], [rhs.c1, rhs.c0]),
        }
    }

    pub fn add(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: self.c0 + rhs.c0,
            c1: self.c1 + rhs.c1,
        }
    }

    pub fn sub(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: self.c0 - rhs.c0,
            c1: self.c1 - rhs.c1,
        }
    }

    pub fn neg(self) -> Fp2 {
        Fp2 {
            c0: (self.c0).neg(),
            c1: (self.c1).neg(),
        }
    }

    // Is not tested directly, but will be indirectly
    pub fn mul_by_nonresidue(self) -> Fp2 {
        // Multiply a + bu by u + 1, getting
        // au + a + bu^2 + bu
        // and because u^2 = -1, we get
        // (a - b) + (a + b)u

        Fp2 {
            c0: self.c0 - self.c1,
            c1: self.c0 + self.c1,
        }
    }

    pub fn conjugate(self) -> Fp2 {
        Fp2{
            c0: self.c0,
            c1: (self.c1).neg(),
        }
    }

    /// Raises this element to p.
    pub fn frobenius_map(self) -> Fp2 {
        //needs to be verified
        // This is always just a conjugation. If you're curious why, here's
        // an article about it: https://alicebob.cryptoland.net/the-frobenius-endomorphism-with-finite-fields/
        // self.conjugate() //showing error
        Fp2{
            c0: self.c0,
            c1: (self.c1).neg(),
        }
    }

}

impl Eq for Fp2 {
    fn eq(self, other: Self) -> bool {
        self.eq(other)
    }
}

impl Add for Fp2 {
    fn add(self, other: Self) -> Self {
        self.add(other)
    }
}

impl Subtract for Fp2 {
    fn subtract(self, other: Self) -> Self {
        self.sub(other)
    }
}

impl Multiply for Fp2 {
        fn multiply(self, other: Self) -> Self {
            self.mul(other)
        }
}
