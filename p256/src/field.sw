library;

use utils::{
  integer_utils::{adc, sbb, mac},
  choice::{Choice, CtOption, ConditionallySelectable, ConstantTimeEq}
};
use core::ops::{Add, Subtract, Multiply};
use ::modular_helper::{sub_inner, mul_wide, add, ct_eq, conditional_select, to_bytes};

// Little endian
// ls[0] + ls[1] * 2^64 + ls[2] * 2^128 + ls[3] * 2^192
// FieldElements should be in Montgomery form i.e., FieldElement(a) = aR mod p, with R = 2^256
pub struct FieldElement { 
  ls: [u64; 4] 
}

// 115792089210356248762697446949407573530086143415290314195533631308867097853951
// 18446744073709551615 + 4294967295 * 2ˆ64 + 18446744069414584321 * 2ˆ192
const MODULUS_FE: [u64; 4] = [18446744073709551615, 4294967295, 0, 18446744069414584321];

// R^2 = 2^512 mod p = 134799733323198995502561713907086292154532538166959272814710328655875
const R_2: [u64; 4] = [3, 18446744056529682431, 18446744073709551614, 21474836477];

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

  pub fn is_odd(self) -> Choice {
    Choice::from(self.ls[0] & 1)
  }

  // Returns `a + b mod p`.
  fn fe_add(self, b: Self) -> Self {
    FieldElement {ls: add(self.ls, b.ls, MODULUS_FE)}
  }

  // Returns `a - b mod p`.
  fn fe_sub(self, b: Self) -> Self {
    FieldElement{ls: sub_inner([self.ls[0], self.ls[1], self.ls[2], self.ls[3], 0], [b.ls[0], b.ls[1], b.ls[2], b.ls[3], 0], MODULUS_FE)}
  }

  // normalize and convert to bytes
  pub fn to_bytes(self) -> [u8;32] {
    to_bytes([self.ls[0], self.ls[1], self.ls[2], self.ls[3], 0], MODULUS_FE)
  }
}

fn montgomery_reduce(r: [u64; 8]) -> FieldElement {
  // Ref: https://github.com/RustCrypto/elliptic-curves/blob/81cb7e11afbde1b8753d56fa27238369209b2e65/p256/src/arithmetic/field/field64.rs#L118
  let r0 = r[0];
  let r1 = r[1];
  let r2 = r[2];
  let r3 = r[3];
  let r4 = r[4];
  let r5 = r[5];
  let r6 = r[6];
  let r7 = r[7];

  let (r1, carry) = mac(r1, r0, MODULUS_FE[1], r0);
  let (r2, carry) = adc(r2, 0, carry);
  let (r3, carry) = mac(r3, r0, MODULUS_FE[3], carry);
  let (r4, carry2) = adc(r4, 0, carry);

  let (r2, carry) = mac(r2, r1, MODULUS_FE[1], r1);
  let (r3, carry) = adc(r3, 0, carry);
  let (r4, carry) = mac(r4, r1, MODULUS_FE[3], carry);
  let (r5, carry2) = adc(r5, carry2, carry);

  let (r3, carry) = mac(r3, r2, MODULUS_FE[1], r2);
  let (r4, carry) = adc(r4, 0, carry);
  let (r5, carry) = mac(r5, r2, MODULUS_FE[3], carry);
  let (r6, carry2) = adc(r6, carry2, carry);

  let (r4, carry) = mac(r4, r3, MODULUS_FE[1], r3);
  let (r5, carry) = adc(r5, 0, carry);
  let (r6, carry) = mac(r6, r3, MODULUS_FE[3], carry);
  let (r7, r8) = adc(r7, carry2, carry);

  FieldElement{ls: sub_inner(
    [r4, r5, r6, r7, r8],
    [MODULUS_FE[0], MODULUS_FE[1], MODULUS_FE[2], MODULUS_FE[3], 0],
    MODULUS_FE
  )}
}

impl FieldElement {

  /// Returns `a * b mod p`.
  pub fn fe_mul(self, b: Self) -> Self {
    montgomery_reduce(mul_wide(self.ls, b.ls))
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
    ct_eq(self.ls, other.ls)
  }
}

impl FieldElement {
  // Has to be in a separate impl Fe, so it can be used in next methods
  /// Returns self^(2^n) mod p
  fn sqn(self, n: u64) -> Self {
    let mut x = self;
    let mut i = 0;
    while i < n {
      x = x.square();
      i += 1;
    }
    x
  }

  pub fn one_montgomery_form() -> Self {
    FieldElement{ls: [1, 18446744069414584320, 18446744073709551615, 4294967294]}
  }
}

impl FieldElement {

  pub fn double(self) -> Self {
    self + self
  }

  // returns multiplicative inverse, does not check for input being zero
  pub fn invert_unchecked(self) -> Self {
    // Ref: https://github.com/RustCrypto/elliptic-curves/blob/81cb7e11afbde1b8753d56fa27238369209b2e65/p256/src/arithmetic/field.rs#L65
    let t111 = self.multiply(self.multiply(self.square()).square());
    let t111111 = t111.multiply(t111.sqn(3));
    let x15 = t111111.sqn(6).multiply(t111111).sqn(3).multiply(t111);
    let x16 = x15.square().multiply(self);
    let i53 = x16.sqn(16).multiply(x16).sqn(15);
    let x47 = x15.multiply(i53);
    x47.multiply(i53.sqn(17).multiply(self).sqn(143).multiply(x47).sqn(47))
        .sqn(2)
        .multiply(self)
  }

  // returns square root of self mod p in the form CtOption(value: square_root, is_some: true)
  // If there is no such element, the result is CtOption(value: xxx, is_some: false)
  pub fn sqrt(self) -> CtOption<Self> {
    // Ref: https://github.com/RustCrypto/elliptic-curves/blob/81cb7e11afbde1b8753d56fa27238369209b2e65/p256/src/arithmetic/field.rs#L87
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
    // all the input for field functions are assumed to be in montgomery form.
    // hence, also taking the multiplicative identity in montgomery form
    let mut res = Self::one_montgomery_form();

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

impl ConditionallySelectable for FieldElement {
  // Select a if choice == 1 or select b if choice == 0, in constant time.
  fn conditional_select(self, b: Self, choice: Choice) -> Self {
    FieldElement{ ls: conditional_select(self.ls, b.ls, choice)}
  }
}