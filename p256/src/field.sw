library field;

dep field64;

use field64::{Fe, fe_square, fe_mul};
use utils::{
  choice::*
  // choice::{CtOption, Choice, ConstantTimeEq}
};

impl ConstantTimeEq for Fe {
  // returns (self == other), as a choice
  fn ct_eq(self, other: Fe) -> Choice {
      u64::ct_eq(self.ls[0], other.ls[0])
      & u64::ct_eq(self.ls[1], other.ls[1])
      & u64::ct_eq(self.ls[2], other.ls[2])
      & u64::ct_eq(self.ls[3], other.ls[3])
  }
}

impl Fe {
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

impl Fe {
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
