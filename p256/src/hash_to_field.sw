library;

use ::field::FieldElement;
use std::hash::sha256;
use std::bytes::Bytes;
use std::u256::U256;

/*
In this file hash_to_field is implemented as specified in https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.3
Specifically for the usecase of P256, using SHA256.

Helper function `expand_message` specification: https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.4.1
*/

// const DST: [u8; 44] = [81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116, 104, 45, 80, 50, 53, 54, 95, 88, 77, 68, 58, 83, 72, 65, 45, 50, 53, 54, 95, 83, 83, 87, 85, 95, 82, 79, 95];

// Needed to extract bytes from hash, comes from answer on Fuel forum
// https://forum.fuel.network/t/how-can-i-transform-b256-into-u8-32/1124/2?u=elena
fn decompose(val: b256) -> (u64, u64, u64, u64) {
    asm(r1: __addr_of(val)) { r1: (u64, u64, u64, u64) }
}

// expand message using SHA256 `expand_message_xmd` https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.4.1
// returns 2 hashes (b_1, b_2)
fn expand_message(data: Vec<u8>) -> (b256, b256, b256) {
  // Note: This implementation is specific for P256

// len_in_bytes = 48
// b_in_bytes = 32
// ell = 3

/*
   1.  ell = ceil(len_in_bytes / b_in_bytes)
   2.  ABORT if ell > 255
*/
// ell = 3 so we're OK.

/*
   3.  DST_prime = DST || I2OSP(len(DST), 1)
   4.  Z_pad = I2OSP(0, r_in_bytes)
   5.  l_i_b_str = I2OSP(len_in_bytes, 2)
   6.  msg_prime = Z_pad || msg || l_i_b_str || I2OSP(0, 1) || DST_prime
*/
  // 3. I2OSP(44,1) = 0x2c, so below is hardcoded the DST array with 0x2c added at the end
  let DST_prime: [u8; 45] = [81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116, 104, 45, 80, 50, 53, 54, 95, 88, 77, 68, 58, 83, 72, 65, 45, 50, 53, 54, 95, 83, 83, 87, 85, 95, 82, 79, 95, 0x2c];
  // 4. for SHA-256, r_in_bytes = 64
  // let Z_pad = [0u8; 64]; commented out because will be directly pushed to byte array
  // 5. len_in_bytes = 48 * 2 = 96
  // let l_i_b_str = [0x00, 0x60]; commented out because will be directly pushed to byte array

  // 6. 
  let mut msg_prime = Bytes::new();
  let mut i = 0;
  // add z_pad
  while i < 64 {
    msg_prime.push(0u8);
    i += 1;
  }
  i = 0;
  // add msg
  while i < data.len() {
    msg_prime.push(data.get(i).unwrap());
    i += 1;
  }

  // len_in_bytes = 96
  // add l_i_b_str = I2OSP(len_in_bytes, 2) 
  // this gives len_in_bytes represented in 2 bytes
  msg_prime.push(0x00);
  msg_prime.push(0x60);
  // I2OSP(0, 1) 
  msg_prime.push(0x00);

  i = 0;
  // add DST_prime
  while i < 45 {
    msg_prime.push(DST_prime[i]);
    i += 1;
  }

  // 7.  b_0 = H(msg_prime)
  let b_0 = msg_prime.sha256();

  // 8.  b_1 = H(b_0 || I2OSP(1, 1) || DST_prime)
  let mut input_second_hash = Bytes::new();
  let (b0_0, b0_1, b0_2, b0_3) = decompose(b_0);

  let mut i = 0; 
  while i < 8 {
    input_second_hash.push(b0_0 >> 8*i);
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_second_hash.push(b0_1 >> 8*i);
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_second_hash.push(b0_2 >> 8*i);
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_second_hash.push(b0_3 >> 8*i);
    i = i + 1;
  }

  input_second_hash.push(0x01);
  i = 0;
  // add DST_prime
  while i < 45 {
    input_second_hash.push(DST_prime[i]);
    i += 1;
  }

  let b_1 = input_second_hash.sha256();

/*
   9.  for i in (2, ..., ell):
   10.    b_i = H(strxor(b_0, b_(i - 1)) || I2OSP(i, 1) || DST_prime)

   Here, ell = 3 so we only have:
   b_2 = H(strxor(b_0, b_1) || I2OSP(2, 1) || DST_prime)
   b_3 = H(strxor(b_0, b_2) || I2OSP(3, 1) || DST_prime)
*/
// Calculate b_2
  let mut input_third_hash = Bytes::new();
  // for strxor(b_0, b_1), xor each u64 separately and add to bytearray
  let (b0_0, b0_1, b0_2, b0_3) = decompose(b_0);
  let (b1_0, b1_1, b1_2, b1_3) = decompose(b_1);

  // fix -> push has input u8 and these are u64. So the u64 has to be decomposed in u8's and then pushed
  // u64 right shifted every 8 bit and then xor is done and then pushed.
  i = 0;
  while i < 8 {
    input_third_hash.push((b0_0 >> (8*i)) ^ (b1_0 >> (8*i)));
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_third_hash.push((b0_1 >> (8*i)) ^ (b1_1 >> (8*i)));
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_third_hash.push((b0_2 >> (8*i)) ^ (b1_2 >> (8*i)));
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_third_hash.push((b0_3 >> (8*i)) ^ (b1_3 >> (8*i)));
    i = i + 1;
  }
  
  
  // I2OSP(2, 1)
  input_third_hash.push(0x02);
  i = 0;
  while i < 45 {
    input_third_hash.push(DST_prime[i]);
    i += 1;
  }

  let b_2 = input_third_hash.sha256();

  //----------------------4th hash from here------------
  // Calculate b_3
  // b_3 = H(strxor(b_0, b_2) || I2OSP(3, 1) || DST_prime)
  let mut input_fourth_hash = Bytes::new();
  let (b2_0, b2_1, b2_2, b2_3) = decompose(b_2);

  i = 0;
  while i < 8 {
    input_fourth_hash.push((b0_0 >> (8*i)) ^ (b2_0 >> (8*i)));
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_fourth_hash.push((b0_1 >> (8*i)) ^ (b2_1 >> (8*i)));
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_fourth_hash.push((b0_2 >> (8*i)) ^ (b2_2 >> (8*i)));
    i = i + 1;
  }
  i = 0;
  while i < 8 {
    input_fourth_hash.push((b0_3 >> (8*i)) ^ (b2_3 >> (8*i)));
    i = i + 1;
  }
  
  // I2OSP(3, 1)
  input_fourth_hash.push(0x03);
  i = 0;
  while i < 45 {
    input_fourth_hash.push(DST_prime[i]);
    i += 1;
  }
  let b_3 = input_fourth_hash.sha256();

  (b_1, b_2, b_3)
}

// Interpretation of what is necessary for calculating OS2IP(input) mod p
// See https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.3
// and https://datatracker.ietf.org/doc/html/rfc8017#section-4.2
// returns OS2IP(input) mod p
pub fn from_b256(input: [u64;6]) -> FieldElement {
  // let (a0, a1, a2, a3) = decompose(input);
  let mut fe = FieldElement{ls: [input[0], input[1], input[2], input[3]]};
  let mut fe2 = FieldElement{ls:[input[4], input[5], 0, 0]};
  let mut fe3 = FieldElement{ls:[0,0,0,1]};

  fe = fe + FieldElement::zero();
  fe2 = fe2 + FieldElement::zero();
  fe3 = fe3 + FieldElement::zero();

  //Need confirmation that whether we have to convert it into motngomery or not
  fe2 = fe2.fe_to_montgomery();
  fe3 = fe3.fe_to_montgomery();
  let input_mod_p = (fe2 * fe3).fe_from_montgomery() + fe;
  // let input_mod_p = fe + FieldElement::zero(); // trigger mod p
  //input_mod_p.fe_to_montgomery() // returning Montgomery form, not sure if this is needed
  input_mod_p   // since we are not doing any multiplication operation, as of now we can keep it in normal form for testing hash_to_field
}




pub fn from_okm(data: [u64; 6]) -> FieldElement {
  // value from reference repo: 0x00000000000000030000000200000000fffffffffffffffefffffffeffffffff
  // equals: 18831305209083045566509456472951307377184560236057732317183
  // in u64's: [18446744069414584319, 18446744073709551614, 8589934592, 3]
  let mut F_2_192: FieldElement = FieldElement {ls: [18446744069414584319, 18446744073709551614, 8589934592, 3]};
  F_2_192 = FieldElement::fe_to_montgomery(F_2_192);

  // 192 bits per field element
  // ls[0] + ls[1] * 2^64 + ls[2] * 2^128 + ls[3] * 2^192
  let mut d0 = FieldElement { ls: [data[0], data[1], data[2], 0]}.fe_to_montgomery();
  let mut d1 = FieldElement { ls: [data[3], data[4], data[5], 0]}.fe_to_montgomery();
  
  // should probably be converted to montgomery, but for debugging we can do the conversion in test and check both values, just in case
  // FieldElement::fe_from_montgomery((d0 * F_2_192 + d1))
  d0 * F_2_192 + d1
}

// input data is a Vec because Sway doesn't support variable length array (yet)
pub fn hash_to_field(data: Vec<u8>) -> [FieldElement; 2] {
  /*
  https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.3

   1. len_in_bytes = count * m * L
   2. uniform_bytes = expand_message(msg, DST, len_in_bytes)
   3. for i in (0, ..., count - 1): E: 0,1
   4.   for j in (0, ..., m - 1): E: 0
   5.     elm_offset = L * (j + i * m) E: 256 * (0+0*1) = 0, 256 * (0+1*1) = 256
   6.     tv = substr(uniform_bytes, elm_offset, L) E: 
   7.     e_j = OS2IP(tv) mod p E: ref https://datatracker.ietf.org/doc/html/rfc8017#section-4.2
   8.   u_i = (e_0, ..., e_(m - 1))
   9. return (u_0, ..., u_(count - 1))
  */

  // bits of info:
  //!!!!!!!!!!!!!NOTICE!!!!!!!!!!!!!!!!!
  // L = 256  //L = 48??
  // count = 2 (can be seen in the function call in hash2curve in ref impl, it expects an output of 2 FieldElements)
  // m = 1 (working over a prime field)
  // len_in_bytes = 256 * 2 // len_in_bytes = 2*48 = 96

  let (b1, b2, b3) = expand_message(data);

  // received 3 hashes of 256 bits: 768 in total. 
  // 2 arrays of 384 bits are converted into a FieldElement each
  // 384 bits = 6 u64's

  let (b10, b11, b12, b13) = decompose(b1);
  let (b20, b21, b22, b23) = decompose(b2);
  let (b30, b31, b32, b33) = decompose(b3);

  let fe_b1 = from_okm([b10, b11, b12, b13, b20, b21]);
  let fe_b2 = from_okm([b22, b23, b30, b31, b32, b33]);
  [fe_b1, fe_b2]
}
