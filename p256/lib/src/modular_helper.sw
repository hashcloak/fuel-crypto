library;

use utils::{
  integer_utils::{adc, sbb, mac},
  choice::* //This wildcard import is needed because of importing ConstantTimeEq for u64 since it's a trait for a primitive type
};

pub fn sub_inner(l: [u64; 5], r: [u64; 5], MODULUS: [u64; 4]) -> [u64;4] {
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

  [w0, w1, w2, w3]
}

// returns a + b mod (modulus)
pub fn add(a: [u64; 4], b: [u64;4], modulus: [u64; 4]) -> [u64;4] {
  let (w0, carry0) = adc(a[0], b[0], 0);
  let (w1, carry1) = adc(a[1], b[1], carry0);
  let (w2, carry2) = adc(a[2], b[2], carry1);
  let (w3, w4) = adc(a[3], b[3], carry2);
  
  // To make sure result is within field, try to subtract modulus
  sub_inner(
      [w0, w1, w2, w3, w4],
      [modulus[0], modulus[1], modulus[2], modulus[3], 0],
      modulus
  )
}

// Multiplies two 256 bit number [u64; 4] without modulo reduction, producing up to a 512-bit number [u64; 8].
pub fn mul_wide(a: [u64; 4], b: [u64; 4]) -> [u64;8] {

  let (w0, carry) = mac(0, a[0], b[0], 0);
  let (w1, carry) = mac(0, a[0], b[1], carry);
  let (w2, carry) = mac(0, a[0], b[2], carry);
  let (w3, w4) = mac(0, a[0], b[3], carry);

  let (w1, carry) = mac(w1, a[1], b[0], 0);
  let (w2, carry) = mac(w2, a[1], b[1], carry);
  let (w3, carry) = mac(w3, a[1], b[2], carry);
  let (w4, w5) = mac(w4, a[1], b[3], carry);

  let (w2, carry) = mac(w2, a[2], b[0], 0);
  let (w3, carry) = mac(w3, a[2], b[1], carry);
  let (w4, carry) = mac(w4, a[2], b[2], carry);
  let (w5, w6) = mac(w5, a[2], b[3], carry);

  let (w3, carry) = mac(w3, a[3], b[0], 0);
  let (w4, carry) = mac(w4, a[3], b[1], carry);
  let (w5, carry) = mac(w5, a[3], b[2], carry);
  let (w6, w7) = mac(w6, a[3], b[3], carry);

  [w0, w1, w2, w3, w4, w5, w6, w7]
}

pub fn ct_eq(a: [u64;4], b: [u64;4]) -> Choice {
  u64::ct_eq(a[0], b[0])
  & u64::ct_eq(a[1], b[1])
  & u64::ct_eq(a[2], b[2])
  & u64::ct_eq(a[3], b[3])
}

pub fn conditional_select(a: [u64;4], b: [u64; 4], choice: Choice) -> [u64;4] {
  [
    u64::conditional_select(a[0], b[0], choice),
    u64::conditional_select(a[1], b[1], choice),
    u64::conditional_select(a[2], b[2], choice),
    u64::conditional_select(a[3], b[3], choice),
  ]
}

// returns bytes in big endian
pub fn to_bytes(limbs: [u64; 5], MODULUS: [u64; 4]) -> [u8;32] {
  let reduced = sub_inner(
      [limbs[0], limbs[1], limbs[2], limbs[3], 0],
      [MODULUS[0], MODULUS[1], MODULUS[2], MODULUS[3], 0],
      MODULUS
  );
  let mut res: [u8;32] = [0u8;32];
  
  let mut i = 4;
  let mut j = 0;
  while j < 32 {
    i -= 1; // to prevent overflow at last run
    res[j] = reduced[i] >> 56;
    res[j + 1] = reduced[i] >> 48;
    res[j + 2] = reduced[i] >> 40;
    res[j + 3] = reduced[i] >> 32;
    res[j + 4] = reduced[i] >> 24;
    res[j + 5] = reduced[i] >> 16;
    res[j + 6] = reduced[i] >> 8;
    res[j + 7] = reduced[i];        
    j += 8;
  }
  res
}