library field;

dep field64;

use field64::{FieldElement, fe_square, fe_mul};
use utils::{
  choice::*
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

  /// Returns the multiplicative inverse of self.
  ///
  /// Does not check that self is non-zero.
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

  /// Returns the square root of self mod p, or `None` if no square root exists.
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
  /// Returns the multiplicative inverse of self, if self is non-zero.
  pub fn invert(self) -> CtOption<Self> {
      CtOption::new(self.invert_unchecked(), !self.is_zero())
  }
}