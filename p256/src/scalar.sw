library;

use utils::integer_utils::{adc, sbb, mac}; 
use utils::choice::*; //This wildcard import is needed because of importing ConstantTimeEq for u64 since it's a trait for a primitive type
use core::ops::{Add, Subtract, Multiply};


pub struct Scalar { 
  ls: [u64; 4] 
}
// Constant representing the modulus
// n = 115792089210356248762697446949407573529996955224135760342422259061068512044369
// n = FFFFFFFF 00000000 FFFFFFFF FFFFFFFF BCE6FAAD A7179E84 F3B9CAC2 FC632551 representing the order of the group/generator
pub const MODULUS: [u64;4] = [17562291160714782033, 13611842547513532036, 18446744073709551615, 18446744069414584320];

// MU = floor(2^512 / n)
//    = 115792089264276142090721624801893421302707618245269942344307673200490803338238
//    = 0x100000000fffffffffffffffeffffffff43190552df1a6c21012ffd85eedf9bfe
pub const MU: [u64; 5] = [85565669623438334, 4834901528447446049, 18446744069414584319, 4294967295, 1];

fn sub_inner(l: [u64; 5], r: [u64; 5]) -> Scalar {
    let (w0, borrow) = sbb(l[0], r[0], 0);
    let (w1, borrow) = sbb(l[1], r[1], borrow);
    let (w2, borrow) = sbb(l[2], r[2], borrow);
    let (w3, borrow) = sbb(l[3], r[3], borrow);
    let (_, borrow) = sbb(l[4], r[4], borrow);

    // If underflow occurred on the final limb, borrow = 0xfff...fff, otherwise
    // borrow = 0x000...000. Thus, we use it as a mask to conditionally add the
    // modulus.
    let (w0, carry) = adc(w0, MODULUS[0] & borrow, 0);
    let (w1, carry) = adc(w1, MODULUS[1] & borrow, carry);
    let (w2, carry) = adc(w2, MODULUS[2] & borrow, carry);
    let (w3, _) = adc(w3, MODULUS[3] & borrow, carry);

    Scalar{ls: [w0, w1, w2, w3]}
}

fn q1_times_mu_shift_five(q1: [u64; 5]) -> [u64; 5] {
    // Schoolbook multiplication.

    let (_w0, carry) = mac(0, q1[0], MU[0], 0);
    let (w1, carry) = mac(0, q1[0], MU[1], carry);
    let (w2, carry) = mac(0, q1[0], MU[2], carry);
    let (w3, carry) = mac(0, q1[0], MU[3], carry);
    let (w4, w5) = mac(0, q1[0], MU[4], carry);

    let (_w1, carry) = mac(w1, q1[1], MU[0], 0);
    let (w2, carry) = mac(w2, q1[1], MU[1], carry);
    let (w3, carry) = mac(w3, q1[1], MU[2], carry);
    let (w4, carry) = mac(w4, q1[1], MU[3], carry);
    let (w5, w6) = mac(w5, q1[1], MU[4], carry);

    let (_w2, carry) = mac(w2, q1[2], MU[0], 0);
    let (w3, carry) = mac(w3, q1[2], MU[1], carry);
    let (w4, carry) = mac(w4, q1[2], MU[2], carry);
    let (w5, carry) = mac(w5, q1[2], MU[3], carry);
    let (w6, w7) = mac(w6, q1[2], MU[4], carry);

    let (_w3, carry) = mac(w3, q1[3], MU[0], 0);
    let (w4, carry) = mac(w4, q1[3], MU[1], carry);
    let (w5, carry) = mac(w5, q1[3], MU[2], carry);
    let (w6, carry) = mac(w6, q1[3], MU[3], carry);
    let (w7, w8) = mac(w7, q1[3], MU[4], carry);

    let (_w4, carry) = mac(w4, q1[4], MU[0], 0);
    let (w5, carry) = mac(w5, q1[4], MU[1], carry);
    let (w6, carry) = mac(w6, q1[4], MU[2], carry);
    let (w7, carry) = mac(w7, q1[4], MU[3], carry);
    let (w8, w9) = mac(w8, q1[4], MU[4], carry);

    [w5, w6, w7, w8, w9]
}

fn q3_times_n_keep_five(q3: [u64; 5]) -> [u64; 5] {
    // Schoolbook multiplication.

    let (w0, carry) = mac(0, q3[0], MODULUS[0], 0);
    let (w1, carry) = mac(0, q3[0], MODULUS[1], carry);
    let (w2, carry) = mac(0, q3[0], MODULUS[2], carry);
    let (w3, carry) = mac(0, q3[0], MODULUS[3], carry);
    let (w4, _) = mac(0, q3[0], 0, carry);

    let (w1, carry) = mac(w1, q3[1], MODULUS[0], 0);
    let (w2, carry) = mac(w2, q3[1], MODULUS[1], carry);
    let (w3, carry) = mac(w3, q3[1], MODULUS[2], carry);
    let (w4, _) = mac(w4, q3[1], MODULUS[3], carry);

    let (w2, carry) = mac(w2, q3[2], MODULUS[0], 0);
    let (w3, carry) = mac(w3, q3[2], MODULUS[1], carry);
    let (w4, _) = mac(w4, q3[2], MODULUS[2], carry);

    let (w3, carry) = mac(w3, q3[3], MODULUS[0], 0);
    let (w4, _) = mac(w4, q3[3], MODULUS[1], carry);

    let (w4, _) = mac(w4, q3[4], MODULUS[0], 0);

    [w0, w1, w2, w3, w4]
}

fn sub_inner_five(l: [u64; 5], r: [u64; 5]) -> [u64; 5] {
    let (w0, borrow) = sbb(l[0], r[0], 0);
    let (w1, borrow) = sbb(l[1], r[1], borrow);
    let (w2, borrow) = sbb(l[2], r[2], borrow);
    let (w3, borrow) = sbb(l[3], r[3], borrow);
    let (w4, _borrow) = sbb(l[4], r[4], borrow);

    // If underflow occurred on the final limb - don't care (= add b^{k+1}).
    [w0, w1, w2, w3, w4]
}

fn subtract_n_if_necessary(r0: u64, r1: u64, r2: u64, r3: u64, r4: u64) -> [u64; 5] {

    let (w0, borrow) = sbb(r0, MODULUS[0], 0);
    let (w1, borrow) = sbb(r1, MODULUS[1], borrow);
    let (w2, borrow) = sbb(r2, MODULUS[2], borrow);
    let (w3, borrow) = sbb(r3, MODULUS[3], borrow);
    let (w4, borrow) = sbb(r4, 0, borrow);

    // If underflow occurred on the final limb, borrow = 0xfff...fff, otherwise
    // borrow = 0x000...000. Thus, we use it as a mask to conditionally add the
    // modulus.
    let (w0, carry) = adc(w0, MODULUS[0] & borrow, 0);
    let (w1, carry) = adc(w1, MODULUS[1] & borrow, carry);
    let (w2, carry) = adc(w2, MODULUS[2] & borrow, carry);
    let (w3, carry) = adc(w3, MODULUS[3] & borrow, carry);
    let (w4, _carry) = adc(w4, 0, carry);

    [w0, w1, w2, w3, w4]
}

impl Scalar {
  // Zero scalar
  pub fn zero() -> Scalar {
      Scalar{ls:[0,0,0,0]}
  }

  // Multiplicative identity.
  fn one() -> Scalar {
      Scalar{ls:[1,0,0,0]}
  }

  // Returns a + b mod n
  pub fn scalar_add(self, b: Self) -> Self {
      let (w0, carry0) = adc(self.ls[0], b.ls[0], 0);
      let (w1, carry1) = adc(self.ls[1], b.ls[1], carry0);
      let (w2, carry2) = adc(self.ls[2], b.ls[2], carry1);
      let (w3, w4) = adc(self.ls[3], b.ls[3], carry2);
      
      // Attempt to subtract the modulus, to ensure the result is in the field.
      sub_inner(
          [w0, w1, w2, w3, w4],
          [MODULUS[0], MODULUS[1], MODULUS[2], MODULUS[3], 0],
      )
  }

  // Returns `a - b mod n`.
  pub fn scalar_sub(self, b: Self) -> Self {
      sub_inner([self.ls[0], self.ls[1], self.ls[2], self.ls[3], 0], [b.ls[0], b.ls[1], b.ls[2], b.ls[3], 0])
  }

  pub fn barrett_reduce(self, h: Self) -> Self {
      let lo: [u64;4] = [self.ls[0], self.ls[1], self.ls[2], self.ls[3]];
      let hi: [u64;4] = [h.ls[0], h.ls[1], h.ls[2], h.ls[3]];
      let a0 = lo[0];
      let a1 = lo[1];
      let a2 = lo[2];
      let a3 = lo[3];
      let a4 = hi[0];
      let a5 = hi[1];
      let a6 = hi[2];
      let a7 = hi[3];
      let q1: [u64; 5] = [a3, a4, a5, a6, a7];
      let q3 = q1_times_mu_shift_five(q1);

      let r1: [u64; 5] = [a0, a1, a2, a3, a4];
      let r2: [u64; 5] = q3_times_n_keep_five(q3);
      let r: [u64; 5] = sub_inner_five(r1, r2);

      // Result is in range (0, 3*n - 1),
      // and 90% of the time, no subtraction will be needed.
      let r = subtract_n_if_necessary(r[0], r[1], r[2], r[3], r[4]);
      let r = subtract_n_if_necessary(r[0], r[1], r[2], r[3], r[4]);
      Scalar{ls: [r[0], r[1], r[2], r[3]]}
  }

  // Multiplies two scalars without modulo reduction, producing up to a 512-bit scalar.
  pub fn mul_wide(self, b: Self) -> [u64;8] {

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

      [w0, w1, w2, w3, w4, w5, w6, w7]
  }
}

impl Scalar {

  // Returns self * rhs mod n
  pub fn scalar_mul(self, b: Self) -> Self {
      let t: [u64; 8] = self.mul_wide(b);
      (Scalar{ls:[t[0], t[1], t[2], t[3]]}).barrett_reduce(Scalar{ls: [t[4], t[5], t[6], t[7]]})
  }

  // returns scalar from big endian byte array (32 bytes)
  pub fn from_bytes(bytes: [u8; 32]) -> Self {
    // Scalar: ls: [u64; 4] is in little endian
    let mut i = 0;
    let mut j = 4;
    let mut u64s: [u64;4] = [0;4];
    while i < 32 {
      u64s[j-1] = (bytes[i + 0] << 56)
        .binary_or(bytes[i + 1] << 48)
        .binary_or(bytes[i + 2] << 40)
        .binary_or(bytes[i + 3] << 32)
        .binary_or(bytes[i + 4] << 24)
        .binary_or(bytes[i + 5] << 16)
        .binary_or(bytes[i + 6] << 8)
        .binary_or(bytes[i + 7]);
      j -= 1;
      i += 8;
    }
    Scalar { ls: u64s}.scalar_add(Self::zero()) // trigger the mod q
  }
}

impl ConstantTimeEq for Scalar {
  // returns (self == other), as a choice
  fn ct_eq(self, other: Scalar) -> Choice {
      u64::ct_eq(self.ls[0], other.ls[0])
      & u64::ct_eq(self.ls[1], other.ls[1])
      & u64::ct_eq(self.ls[2], other.ls[2])
      & u64::ct_eq(self.ls[3], other.ls[3])
  }
}

impl Add for Scalar {
  fn add(self, other: Self) -> Self {
      self.scalar_add(other)
  }
}

impl Subtract for Scalar {
  fn subtract(self, other: Self) -> Self {
      self.scalar_sub(other)
  }
}

impl Multiply for Scalar {
  fn multiply(self, other: Self) -> Self {
      self.scalar_mul(other)
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
