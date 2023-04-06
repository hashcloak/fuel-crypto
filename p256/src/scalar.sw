library;

use ::scalar64::{Scalar, barrett_reduce, scalar_add, scalar_sub, scalar_mul};
use utils::choice::*; //This wildcard import is needed because of importing ConstantTimeEq for u64 since it's a trait for a primitive type
use core::ops::{Add, Subtract, Multiply};

impl ConstantTimeEq for Scalar {
  // returns (self == other), as a choice
  fn ct_eq(self, other: Scalar) -> Choice {
      u64::ct_eq(self.ls[0], other.ls[0])
      & u64::ct_eq(self.ls[1], other.ls[1])
      & u64::ct_eq(self.ls[2], other.ls[2])
      & u64::ct_eq(self.ls[3], other.ls[3])
  }
}

impl Scalar {

  // Zero scalar
  fn zero() -> Scalar {
      Scalar{ls:[0,0,0,0]}
  }

  // Multiplicative identity.
  fn one() -> Scalar {
      Scalar{ls:[1,0,0,0]}
  }

}

impl Add for Scalar {
  fn add(self, other: Self) -> Self {
      scalar_add(self, other)
  }
}

impl Subtract for Scalar {
  fn subtract(self, other: Self) -> Self {
      scalar_sub(self, other)
  }
}

impl Multiply for Scalar {
  fn multiply(self, other: Self) -> Self {
      scalar_mul(self, other)
  }
}

impl Scalar {

  fn double(self) -> Self {
      self + self
  }

  fn square(self) -> Self {
      self * self
  }

}

impl Scalar {

  // returns self ^ exp mod p
  // exp is given in little endian
  fn pow_vartime(self, exp: [u64; 4]) -> Self {
      let mut res = Self::one();

      let mut i = 4;
      while i > 0 {
          i -= 1;

          let mut j = 64;
          while j > 0 {
              j -= 1;
              res = res.square();

              if ((exp[i] >> j) & 1) == 1 {
                  res = res.multiply(self);
              }
          }
      }
      res
  }

}

impl Scalar {

  // returns multiplicative inverse, does not check for input being zero
  fn invert_unchecked(self) -> Self {
      // We need to find b such that b * a ≡ 1 mod p. As we are in a prime
      // field, we can apply Fermat's Little Theorem:
      //
      //    a^p         ≡ a mod p
      //    a^(p-1)     ≡ 1 mod p
      //    a^(p-2) * a ≡ 1 mod p
      //
      // Thus inversion can be implemented with a single exponentiation.
      //
      // This is `n - 2`, so the top right two digits are `4f` instead of `51`.
      self.pow_vartime([
          0xf3b9_cac2_fc63_254f,
          0xbce6_faad_a717_9e84,
          0xffff_ffff_ffff_ffff,
          0xffff_ffff_0000_0000,
      ])
  }
}

impl Scalar {
  // returns multiplicative inverse of self mod p in the form CtOption(value: inverse, is_some: true)
  // If element is zero, the result is CtOption(value: xxx, is_some: false)
  pub fn scalar_invert(self) -> CtOption<Self> {
      CtOption::new(self.invert_unchecked(), !self.ct_eq(Self::zero()))
  }
}
