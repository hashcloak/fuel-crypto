library fp12;

dep fp6;

use fp6::Fp6;
use choice::{ConstantTimeEq};
use core::ops::{Eq, Add, Subtract, Multiply};

// Element in F_{p^12}
pub struct Fp12 {
    c0: Fp6,
    c1: Fp6,
}

impl ConditionallySelectable for Fp12 {
    // Select a if choice == 1 or select b if choice == 0, in constant time
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        Fp12 {
            c0: ~Fp6::conditional_select(a.c0, b.c0, choice),
            c1: ~Fp6::conditional_select(a.c1, b.c1, choice),
        }
    }
}

impl ConstantTimeEq for Fp12 {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Self) -> Choice {
        self.c0.ct_eq(other.c0) & self.c1.ct_eq(other.c1)
    }
}

impl Fp12 {
    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }

    pub fn zero() -> Self {
        Fp12 {
            c0: ~Fp6::zero(),
            c1: ~Fp6::zero(),
        }
    }

    pub fn one() -> Self {
        Fp12 {
            c0: ~Fp6::one(),
            c1: ~Fp6::zero(),
        }
    }

    fn from(f: Fp) -> Fp12 {
        Fp12 {
            c0: ~Fp6::from(f),
            c1: ~Fp6::zero(),
        }
    }

    fn from(f: Fp2) -> Fp12 {
        Fp12 {
            c0: ~Fp6::from(f),
            c1: ~Fp6::zero(),
        }
    }

    fn from(f: Fp6) -> Fp12 {
        Fp12 {
            c0: f,
            c1: ~Fp6::zero(),
        }
    }

    fn is_zero(self) -> Choice {
        self.c0.is_zero().binary_and(self.c1.is_zero())
    }

    fn neg(self) -> Self {
        Fp12 {
            c0: self.c0.neg(),
            c1: self.c1.neg(),
        }
    }

    fn add(self, rhs: Fp12) -> Self {
        Fp12 {
            c0: self.c0 + rhs.c0,
            c1: self.c1 + rhs.c1,
        }
    }

    fn sub(self, rhs: Fp12) -> Self {
        Fp12 {
            c0: self.c0 - rhs.c0,
            c1: self.c1 - rhs.c1,
        }
    }
}

impl Eq for Fp12 {
    fn eq(self, other: Self) -> bool {
        self.eq(other)
    }
}

impl Add for Fp12 {
    fn add(self, other: Fp12) -> Self {
        self.add(other)
    }
}

impl Subtract for Fp12 {
    fn subtract(self, other: Fp12) -> Self {
        self.sub(other)
    }
}