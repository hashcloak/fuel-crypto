library field;

use utils::{
  integer_utils::{adc, sbb, mac},
  choice::* //This wildcard import is needed because of importing ConstantTimeEq for u64 since it's a trait for a primitive type
};
use core::ops::{Add, Subtract, Multiply};

// Little endian
// ls[0] + ls[1] * 2^64 + ls[2] * 2^128 + ls[3] * 2^192
// FieldElements should be in Montgomery form i.e., FieldElement(a) = aR mod p, with R = 2^256
pub struct FieldElement { 
  ls: [u64; 4] 
}

// 115792089210356248762697446949407573530086143415290314195533631308867097853951
// 18446744073709551615 + 4294967295 * 2ˆ64 + 18446744069414584321 * 2ˆ192
const modulus: [u64; 4] = [18446744073709551615, 4294967295, 0, 18446744069414584321];

// R^2 = 2^512 mod p = 134799733323198995502561713907086292154532538166959272814710328655875
const R_2: [u64; 4] = [3, 18446744056529682431, 18446744073709551614, 21474836477];

fn sub_inner(l: [u64; 5], r: [u64; 5]) -> FieldElement {
    let (w0, borrow0) = sbb(l[0], r[0], 0);
    let (w1, borrow1) = sbb(l[1], r[1], borrow0);
    let (w2, borrow2) = sbb(l[2], r[2], borrow1);
    let (w3, borrow3) = sbb(l[3], r[3], borrow2);
    let (_, borrow4) = sbb(l[4], r[4], borrow3);

    // If l[4] < r[4] then borrow = 11...11, otherwise borrow 00...00
    // If there was a borrow, 1x modulus has to bed added
    // borrow4 is used as a mask
    let (w0, carry0) = adc(w0, modulus[0] & borrow4, 0);
    let (w1, carry1) = adc(w1, modulus[1] & borrow4, carry0);
    let (w2, carry2) = adc(w2, modulus[2] & borrow4, carry1);
    let (w3, _) = adc(w3, modulus[3] & borrow4, carry2);
  
    FieldElement { ls: [w0, w1, w2, w3] }
}

impl FieldElement {

  // Zero element
  pub fn zero() -> Self {
    FieldElement{ls: [0,0,0,0]}
  }

  // Multiplicative identity.
  pub fn one() -> Self {
    FieldElement{ls:[1,0,0,0]}
  }

  pub fn from_u64(w: u64) -> Self {
    FieldElement{ls: [w,0,0,0]}
  }

  fn is_odd(self) -> Choice {
    Choice::from(self.ls[0] & 1)
  }

  fn fe_add(self, b: Self) -> Self {
      let (w0, carry0) = adc(self.ls[0], b.ls[0], 0);
      let (w1, carry1) = adc(self.ls[1], b.ls[1], carry0);
      let (w2, carry2) = adc(self.ls[2], b.ls[2], carry1);
      let (w3, w4) = adc(self.ls[3], b.ls[3], carry2);
      
      // To make sure result is within field, try to subtract modulus
      sub_inner(
          [w0, w1, w2, w3, w4],
          [modulus[0], modulus[1], modulus[2], modulus[3], 0],
      )
  }

  // Returns `a - b mod p`.
  fn fe_sub(self, b: Self) -> Self {
      sub_inner([self.ls[0], self.ls[1], self.ls[2], self.ls[3], 0], [b.ls[0], b.ls[1], b.ls[2], b.ls[3], 0])
  }
}

fn montgomery_reduce(r: [u64; 8]) -> FieldElement {

    let r0 = r[0];
    let r1 = r[1];
    let r2 = r[2];
    let r3 = r[3];
    let r4 = r[4];
    let r5 = r[5];
    let r6 = r[6];
    let r7 = r[7];

    let (r1, carry) = mac(r1, r0, modulus[1], r0);
    let (r2, carry) = adc(r2, 0, carry);
    let (r3, carry) = mac(r3, r0, modulus[3], carry);
    let (r4, carry2) = adc(r4, 0, carry);

    let (r2, carry) = mac(r2, r1, modulus[1], r1);
    let (r3, carry) = adc(r3, 0, carry);
    let (r4, carry) = mac(r4, r1, modulus[3], carry);
    let (r5, carry2) = adc(r5, carry2, carry);

    let (r3, carry) = mac(r3, r2, modulus[1], r2);
    let (r4, carry) = adc(r4, 0, carry);
    let (r5, carry) = mac(r5, r2, modulus[3], carry);
    let (r6, carry2) = adc(r6, carry2, carry);

    let (r4, carry) = mac(r4, r3, modulus[1], r3);
    let (r5, carry) = adc(r5, 0, carry);
    let (r6, carry) = mac(r6, r3, modulus[3], carry);
    let (r7, r8) = adc(r7, carry2, carry);

    sub_inner(
        [r4, r5, r6, r7, r8],
        [modulus[0], modulus[1], modulus[2], modulus[3], 0],
    )
}

impl FieldElement {

  /// Returns `a * b mod p`.
  pub fn fe_mul(self, b: Self) -> Self {
      let (w0, carry) = mac(0, self.ls[0], b.ls[0], 0);
      let (w1, carry) = mac(0, self.ls[0], b.ls[1], carry);
      let (w2, carry) = mac(0, self.ls[0], b.ls[2], carry);
      let (w3, w4) = mac(0, self.ls[0], b.ls[3], carry);

      let (w1, carry) = mac(w1, self.ls[1], b.ls[0], 0);
      let (w2, carry) = mac(w2, self.ls[1], b.ls[1], carry);
      let (w3, carry) = mac(w3, self.ls[1], b.ls[2], carry);
      let (w4, w5) = mac(w4, self.ls[1], b.ls[3], carry);

      let (w2, carry) = mac(w2, self.ls[2], b.ls[0], 0);
      let (w3, carry) = mac(w3, self.ls[2], b.ls[1], carry);
      let (w4, carry) = mac(w4, self.ls[2], b.ls[2], carry);
      let (w5, w6) = mac(w5, self.ls[2], b.ls[3], carry);

      let (w3, carry) = mac(w3, self.ls[3], b.ls[0], 0);
      let (w4, carry) = mac(w4, self.ls[3], b.ls[1], carry);
      let (w5, carry) = mac(w5, self.ls[3], b.ls[2], carry);
      let (w6, w7) = mac(w6, self.ls[3], b.ls[3], carry);

      montgomery_reduce([w0, w1, w2, w3, w4, w5, w6, w7])
  }

  // Translate a field element out of the Montgomery domain.
  pub fn fe_from_montgomery(self) -> Self {
      montgomery_reduce([self.ls[0], self.ls[1], self.ls[2], self.ls[3], 0, 0, 0, 0])
  }

}

// Add arithmetic symbols support +, - , *

impl Add for FieldElement {
    fn add(self, other: Self) -> Self {
        self.fe_add(other)
    }
}

impl Subtract for FieldElement {
    fn subtract(self, other: Self) -> Self {
        self.fe_sub(other)
    }
}

impl Multiply for FieldElement {
    fn multiply(self, other: Self) -> Self {
        self.fe_mul(other)
    }
}

impl FieldElement {
  // Returns `-w mod p`
  pub fn fe_neg(self) -> Self {
    FieldElement::zero() - self
  }

  // Translate a field element into the Montgomery domain.
  pub fn fe_to_montgomery(self) -> Self {
      self * FieldElement{ls: R_2}
  }

  pub fn square(self) -> Self {
      self * self
  }
}


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
        let new_x = x.square();
        x = new_x;
        i += 1;
      }
      x
  }
}

impl FieldElement {

  pub fn double(self) -> Self {
    self + self
  }

  // returns multiplicative inverse, does not check for input being zero
  pub fn invert_unchecked(self) -> Self {
    let t111 = self * (self * self.square()).square();
    let t111111 = t111 * t111.sqn(3);
    let x15 = t111111.sqn(6) * t111111.sqn(3) * t111;
    let x16 = x15.square() * self; 
    let i53 = (x16.sqn(16) * x16).sqn(15);
    let x47 = x15 * i53;
    x47.multiply(i53.sqn(17).multiply(self).sqn(143).multiply(x47).sqn(47))
        .sqn(2)
        .multiply(self)
  }

  // returns square root of self mod p in the form CtOption(value: square_root, is_some: true)
  // If there is no such element, the result is CtOption(value: xxx, is_some: false)
  pub fn sqrt(self) -> CtOption<Self> {
    let t111 = self * self.square();
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

  pub fn is_zero(self) -> Choice {
      self.ct_eq(Self::zero())
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

  pub fn negate(self) -> Self {
      Self::zero().subtract(self)
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

impl ConditionallySelectable for FieldElement {
  // Select a if choice == 1 or select b if choice == 0, in constant time.
  fn conditional_select(self, b: Self, choice: Choice) -> Self {
      FieldElement{ ls: [
          u64::conditional_select(self.ls[0], b.ls[0], choice),
          u64::conditional_select(self.ls[1], b.ls[1], choice),
          u64::conditional_select(self.ls[2], b.ls[2], choice),
          u64::conditional_select(self.ls[3], b.ls[3], choice),
      ]}
  }
}