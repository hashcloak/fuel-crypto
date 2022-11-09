library fp2;

dep fp;

use fp::Fp;
use core::ops::{Eq, Add, Subtract, Multiply};
use utils::choice::*; 

// Element in the quadratic extension field F_{p^2}
pub struct Fp2 {
    c0: Fp,
    c1: Fp,
}

impl ConstantTimeEq for Fp2 {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Self) -> Choice {
        self.c0.ct_eq(other.c0) & self.c1.ct_eq(other.c1)
    }
}

impl ConditionallySelectable for Fp2 {
    // Select a if choice == 1 or select b if choice == 0, in constant time
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        Fp2 {
            c0: Fp::conditional_select(a.c0, b.c0, choice),
            c1: Fp::conditional_select(a.c1, b.c1, choice),
        }
    }
}

impl Eq for Fp2 {
    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }
}

impl Add for Fp2 {
    fn add(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: self.c0 + rhs.c0,
            c1: self.c1 + rhs.c1,
        }
    }
}

impl Fp2 {
    // in the zkcrypto repo this is implemented as trait From<Fp>, but this isn't possible in Sway
    fn from(f: Fp) -> Fp2 {
        Fp2 {
            c0: f,
            c1: Fp::zero(),
        }
    }

    fn zero() -> Fp2 {
        Fp2 {
            c0: Fp::zero(),
            c1: Fp::zero(),
        }
    }

    fn one() -> Fp2 {
        Fp2 {
            c0: Fp::one(),
            c1: Fp::zero(),
        }
    }

    fn is_zero(self) -> Choice {
        self.c0.is_zero().binary_and(self.c1.is_zero())
    }

/*
    // not tested, gives Immediate18TooLarge error
    fn square(self) -> Fp2 {
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

    fn mul(self, rhs: Fp2) -> Fp2 {
        // Explanation from zkcrypto repo:
        // F_{p^2} x F_{p^2} multiplication implemented with operand scanning (schoolbook)
        // computes the result as:
        //
        //   a·b = (a_0 b_0 + a_1 b_1 β) + (a_0 b_1 + a_1 b_0)i
        //
        // In BLS12-381's F_{p^2}, our β is -1, so the resulting F_{p^2} element is:
        //
        //   c_0 = a_0 b_0 - a_1 b_1
        //   c_1 = a_0 b_1 + a_1 b_0
        //
        // Each of these is a "sum of products", which we can compute efficiently.
        Fp2 {
            c0: Fp::sum_of_products_2([self.c0, self.c1.neg()], [rhs.c0, rhs.c1]),
            c1: Fp::sum_of_products_2([self.c0, self.c1], [rhs.c1, rhs.c0]),
        }
    }

    fn sub(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: self.c0 - rhs.c0,
            c1: self.c1 - rhs.c1,
        }
    }

    fn neg(self) -> Fp2 {
        Fp2 {
            c0: (self.c0).neg(),
            c1: (self.c1).neg(),
        }
    }

    // Is not tested directly, but will be indirectly in consequent extension fields
    fn mul_by_nonresidue(self) -> Fp2 {
        // Explanation from zkcrypto
        // Multiply a + bu by u + 1, getting
        // au + a + bu^2 + bu
        // and because u^2 = -1, we get
        // (a - b) + (a + b)u

        Fp2 {
            c0: self.c0 - self.c1,
            c1: self.c0 + self.c1,
        }
    }

    // returns whether self > -self, lexographically speaking
    fn lexicographically_largest(self) -> Choice {
        // lexicographically_largest(self.c1) || (self.c1 == 0 && lexicographically_largest(self.c0)) 
        self.c1.lexicographically_largest()
        .binary_or(self.c1.is_zero().binary_and(self.c0.lexicographically_largest()))
    }

    // returns (self.c0, -self.c1)
    fn conjugate(self) -> Fp2 {
        Fp2{
            c0: self.c0,
            c1: (self.c1).neg(),
        }
    }
}

impl Fp2 {
    // This goes in a separate impl, because if we use previously defined functions in Fp2 impl, 
    // Sway will not recognize them from inside the same impl

    /// returns self^p, the Frobenius map
    fn frobenius_map(self) -> Fp2 {
        // For fp2, self^p equals the conjugate.
        // Example explanation here: https://alicebob.modp.net/the-frobenius-endomorphism-with-finite-fields/
        self.conjugate()
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
