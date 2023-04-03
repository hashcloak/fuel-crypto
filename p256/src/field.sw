library field;

dep field64;

use field64::{FieldElement, fe_square, fe_mul, fe_to_montgomery, fe_from_montgomery};
use utils::{
  choice::* //This wildcard import is needed because of importing ConstantTimeEq for u64 since it's a trait for a primitive type
  // choice::{CtOption, Choice, ConstantTimeEq}
};

impl ConstantTimeEq for FieldElement {
  // returns (self == other), as a choice
  fn ct_eq(self, other: FieldElement) -> Choice {
      u64::ct_eq(self.ls[0], other.ls[0])
      & u64::ct_eq(self.ls[1], other.ls[1])
      & u64::ct_eq(self.ls[2], other.ls[2])
      & u64::ct_eq(self.ls[3], other.ls[3])
  }
}

impl FieldElement {
  // Has to be in a separate impl Fe, so it can be used in next methods
  /// Returns self^(2^n) mod p
  fn sqn(self, n: u64) -> Self {
      let mut x = self;
      let mut i = 0;
      while i < n {
        let new_x = fe_square(x);
        x = new_x;
        i += 1;
      }
      x
  }
}

impl FieldElement {

  // Zero element
  fn zero() -> Self {
    FieldElement{ls: [0,0,0,0]}
  }

  // Multiplicative identity.
  fn one() -> Self {
    FieldElement{ls:[1,0,0,0]}
  }

  fn is_odd(self) -> Choice {
    Choice::from(self.ls[0] & 1)
  }

  fn square(self) -> Self {
    self * self
  }

  // returns multiplicative inverse, does not check for input being zero
  pub fn invert_unchecked(self) -> Self {
    let t111 = self.multiply(fe_square(self.multiply(fe_square(self))));
    let t111111 = t111.multiply(t111.sqn(3));
    let x15 = t111111.sqn(6).multiply(t111111).sqn(3).multiply(t111);
    let x16 = fe_square(x15).multiply(self);
    let i53 = x16.sqn(16).multiply(x16).sqn(15);
    let x47 = x15.multiply(i53);
    x47.multiply(i53.sqn(17).multiply(self).sqn(143).multiply(x47).sqn(47))
        .sqn(2)
        .multiply(self)
  }

  // returns square root of self mod p in the form CtOption(value: square_root, is_some: true)
  // If there is no such element, the result is CtOption(value: xxx, is_some: false)
  pub fn sqrt(self) -> CtOption<Self> {
    let t111 = self * fe_square(self);
    let t1111 = t111 * t111.sqn(2);
    let t11111111 = t1111 * t1111.sqn(4);
    let x16 = t11111111.sqn(8) * t11111111;
    let sqrt = x16.sqn(16)
      .multiply(x16)
      .sqn(32)
      .multiply(self)
      .sqn(96)
      .multiply(self)
      .sqn(94);

    CtOption::new(sqrt, (sqrt * sqrt).ct_eq(self))
  }
}

impl FieldElement {
  // returns multiplicative inverse of self mod p in the form CtOption(value: inverse, is_some: true)
  // If the input is zero, the result is CtOption(value: xxx, is_some: false)
  pub fn invert(self) -> CtOption<Self> {
      CtOption::new(self.invert_unchecked(), !self.is_zero())
  }

  pub fn is_even(self) -> Choice {
        !self.is_odd()
    }

  pub fn pow_vartime(self, exp: [u64; 4]) -> Self {
    let mut res = Self::one();

    let mut i = 4;
    while i > 0 {
      i -= 1;

      let mut j = 64;
      while j > 0 {
        j -= 1;
        // res = fe_to_montgomery(res);
        res = res.square();
        // res = fe_from_montgomery(res);

        if ((exp[i] >> j) & 1) == 1 {
          // res = fe_to_montgomery(res);
          res = res.multiply(self);
          // res = fe_from_montgomery(res);
        }
      }
    }
    res
  }

}