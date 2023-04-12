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

const DST: [u8; 44] = [81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116, 104, 45, 80, 50, 53, 54, 95, 88, 77, 68, 58, 83, 72, 65, 45, 50, 53, 54, 95, 83, 83, 87, 85, 95, 82, 79, 95];

// Needed to extract bytes from hash, comes from answer on Fuel forum
// https://forum.fuel.network/t/how-can-i-transform-b256-into-u8-32/1124/2?u=elena
fn decompose(val: b256) -> (u64, u64, u64, u64) {
    asm(r1: __addr_of(val)) { r1: (u64, u64, u64, u64) }
}

// expand message using SHA256 `expand_message_xmd` https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.4.1
// returns 2 hashes (b_1, b_2)
fn expand_message(data: Vec<u8>) -> (b256, b256) {
  // Note: This implementation is specific for P256

// len_in_bytes = 64
// b_in_bytes = 32
// ell = 2

/*
   1.  ell = ceil(len_in_bytes / b_in_bytes)
   2.  ABORT if ell > 255
*/
// ell = 2 so we're OK.

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
  // 5. len_in_bytes = 64
  // let l_i_b_str = [0x00, 0x40]; commented out because will be directly pushed to byte array

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
  // add l_i_b_str = I2OSP(len_in_bytes, 2) 
  // this gives len_in_bytes represented in 2 bytes
  msg_prime.push(0x00);
  msg_prime.push(0x40);
  // I2OSP(0, 1) 
  msg_prime.push(0x00);

  i = 0;
  // add DST_prime
  while i < 44 {
    msg_prime.push(DST_prime[i]);
    i += 1;
  }

  // 7.  b_0 = H(msg_prime)
  let b_0 = msg_prime.sha256();

  // 8.  b_1 = H(b_0 || I2OSP(1, 1) || DST_prime)
  let mut input_second_hash = Bytes::new();
  let (b0_0, b0_1, b0_2, b0_3) = decompose(b_0);
  input_second_hash.push(b0_0);
  input_second_hash.push(b0_1);
  input_second_hash.push(b0_2);
  input_second_hash.push(b0_3);
  input_second_hash.push(0x01);
  i = 0;
  // add DST_prime
  while i < 44 {
    input_second_hash.push(DST_prime[i]);
    i += 1;
  }

  let b_1 = input_second_hash.sha256();

/*
   9.  for i in (2, ..., ell):
   10.    b_i = H(strxor(b_0, b_(i - 1)) || I2OSP(i, 1) || DST_prime)

   Here, ell = 2 so we only have:
   b_2 = H(strxor(b_0, b_1) || I2OSP(2, 1) || DST_prime)
*/
  let mut input_third_hash = Bytes::new();
  // for strxor(b_0, b_1), xor each u64 separately and add to bytearray
  let (b0_0, b0_1, b0_2, b0_3) = decompose(b_0);
  let (b1_0, b1_1, b1_2, b1_3) = decompose(b_1);
  // TODO fix this! 
  // fix -> push has input u8 and these are u64. So the u64 has to be decomposed in u8's and then pushed
  // input_third_hash.push(b0_0 ^ b1_0);
  // input_third_hash.push(b0_1 ^ b1_1);
  // input_third_hash.push(b0_2 ^ b1_2);
  // input_third_hash.push(b0_3 ^ b1_3);
  
  // I2OSP(2, 1)
  input_third_hash.push(0x02);
  i = 0;
  while i < 44 {
    input_third_hash.push(DST_prime[i]);
    i += 1;
  }

  let b_2 = input_third_hash.sha256();
  (b_1, b_2)
}

// Interpretation of what is necessary for calculating OS2IP(input) mod p
// See https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.3
// and https://datatracker.ietf.org/doc/html/rfc8017#section-4.2
// returns OS2IP(input) mod p
pub fn from_b256(input: b256) -> FieldElement {
  let (a0, a1, a2, a3) = decompose(input);
  let fe = FieldElement{ls: [a0, a1, a2, a3]};
  let input_mod_p = fe + FieldElement::zero(); // trigger mod p
  input_mod_p.fe_to_montgomery() // returning Montgomery form, not sure if this is needed
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
  // L = 256
  // count = 2 (can be seen in the function call in hash2curve in ref impl, it expects an output of 2 FieldElements)
  // m = 1 (working over a prime field)
  // len_in_bytes = 256 * 2

  let (b1, b2) = expand_message(data);
  let fe_b1 = from_b256(b1);
  let fe_b2 = from_b256(b2);
  [fe_b1, fe_b2]
}