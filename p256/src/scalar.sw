library scalar;

dep scalar64;

use scalar64::*;

use scalar64::{Scalar, barrett_reduce};
use core::ops::{Add, Subtract, Multiply};

impl Scalar {

    // Zero scalar
    fn zero() -> Scalar {
        Scalar{ls:[0,0,0,0]}
    }

    // Multiplicative identity.
    fn one() -> Scalar {
        Scalar{ls:[1,0,0,0]}
    }

    fn add(self, rhs: Self) -> Self {
        scalar_add(self, rhs)
    }

    fn sub(self, rhs:  Self) -> Self {
        scalar_sub(self, rhs)
    }

    fn multiply(self, rhs: Self) -> Self {
        scalar_mul(self, rhs)
    }

}

impl Scalar {

    fn double(self) -> Self {
        self.add(self)
    }

    fn square(self) -> Self {
        self.multiply(self)
    }

}