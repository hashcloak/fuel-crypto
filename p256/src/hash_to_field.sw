library;

use ::field::FieldElement;
use std::hash::sha256;
use std::bytes::Bytes;
use std::u256::U256;
use std::logging::log;

/*
In this file hash_to_field is implemented as specified in https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.3
Specifically for the usecase of P256, using SHA256.

Helper function `expand_message` specification: https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.4.1
*/

// expand message using SHA256 `expand_message_xmd` https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-11#section-5.4.1
// returns 2 hashes (b_1, b_2)
pub fn expand_message(data: Vec<u8>) -> (b256, b256, b256) {
  // Note: This implementation is specific for P256

// len_in_bytes = 48
// b_in_bytes = 32
// ell = 3

/*
   1.  ell = ceil(len_in_bytes / b_in_bytes)
   2.  ABORT if ell > 255
   3.  DST_prime = DST || I2OSP(len(DST), 1)
   4.  Z_pad = I2OSP(0, r_in_bytes)
   5.  l_i_b_str = I2OSP(len_in_bytes, 2)
   6.  msg_prime = Z_pad || msg || l_i_b_str || I2OSP(0, 1) || DST_prime
*/
  // 3. I2OSP(44,1) = 0x2c, so below is hardcoded the DST array with 0x2c added at the end
  // length is 38
  // "QUUX-V01-CS02-with-expander-SHA256-128"
  let DST_prime: [u8; 39] = [81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116, 104, 45, 101, 120, 112, 97, 110, 100, 101, 114, 45, 83, 72, 65, 50, 53, 54, 45, 49, 50, 56, 38];

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
  msg_prime.push(0);
  msg_prime.push(32);
  // I2OSP(0, 1) 
  msg_prime.push(0x00);

  i = 0;
  // add DST_prime
  while i < 39 {
    msg_prime.push(DST_prime[i]);
    i += 1;
  }

  // 7.  b_0 = H(msg_prime)
  let b_0 = msg_prime.sha256();
  // 8.  b_1 = H(b_0 || I2OSP(1, 1) || DST_prime)
  let mut input_second_hash = Bytes::new();
  let b0_bytes = into_bytes(b_0).into_vec_u8();

  let mut i = 0;
  while i < 32 {
    input_second_hash.push(b0_bytes.get(i).unwrap());
    i = i + 1;
  }

  input_second_hash.push(0x01);
  i = 0;
  // add DST_prime
  while i < 39 {
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
  let b1_bytes = into_bytes(b_1).into_vec_u8();

  i = 0;
  while i < 32 {
    input_third_hash.push(b0_bytes.get(i).unwrap().binary_xor(b1_bytes.get(i).unwrap()));
    i = i + 1;
  }

  // I2OSP(2, 1)
  input_third_hash.push(0x02);
  i = 0;
  while i < 39 {
    input_third_hash.push(DST_prime[i]);
    i += 1;
  }

  let b_2 = input_third_hash.sha256();

  //----------------------4th hash from here------------
  // Calculate b_3
  // b_3 = H(strxor(b_0, b_2) || I2OSP(3, 1) || DST_prime)
  let mut input_fourth_hash = Bytes::new();
  let b2_bytes = into_bytes(b_2).into_vec_u8();

  i = 0;
  while i < 32 {
    input_fourth_hash.push(b0_bytes.get(i).unwrap().binary_xor(b2_bytes.get(i).unwrap()));
    i = i + 1;
  }
  
  // I2OSP(3, 1)
  input_fourth_hash.push(0x03);
  i = 0;
  while i < 39 {
    input_fourth_hash.push(DST_prime[i]);
    i += 1;
  }
  let b_3 = input_fourth_hash.sha256();

  (b_1, b_2, b_3)
}

pub fn from_okm(data: [u8; 48]) -> FieldElement {
  let mut i = 0;
  let mut data_u64: [u64; 6] = [0u64; 6];
  let mut j = 0;
  while i < 48 {
    data_u64[j] = (data[i + 0] << 56).binary_or(data[i + 1] << 48).binary_or(data[i + 2] << 40).binary_or(data[i + 3] << 32).binary_or(data[i + 4] << 24).binary_or(data[i + 5] << 16).binary_or(data[i + 6] << 8).binary_or(data[i + 7]);
    i += 8;
    j += 1;
  }

  // value from reference repo: 0x00000000000000030000000200000000fffffffffffffffefffffffeffffffff
  // equals: 18831305209083045566509456472951307377184560236057732317183
  // in u64's: [18446744069414584319, 18446744073709551614, 8589934592, 3]
  let F_2_192: FieldElement = FieldElement {ls: [18446744069414584319, 18446744073709551614, 8589934592, 3]};

  // 192 bits per field element
  // ls[0] + ls[1] * 2^64 + ls[2] * 2^128 + ls[3] * 2^192
  let mut d0 = FieldElement { ls: [data_u64[2], data_u64[1], data_u64[0], 0]}.fe_to_montgomery();
  let mut d1 = FieldElement { ls: [data_u64[5], data_u64[4], data_u64[3], 0]}.fe_to_montgomery();

  d0 * F_2_192 + d1
}

// from https://forum.fuel.network/t/how-can-i-transform-b256-into-u8-32/1124/2
fn into_bytes(b: b256) -> Bytes {
  let mut bytes = Bytes::with_capacity(32);
  bytes.len = 32;

  // Copy bytes from contract_id into the buffer of the target bytes
  __addr_of(b).copy_bytes_to(bytes.buf.ptr, 32);

  bytes
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
  // L = 48
  // count = 2 (can be seen in the function call in hash2curve in ref impl, it expects an output of 2 FieldElements)
  // m = 1 (working over a prime field)
  // len_in_bytes = 256 * 2 // len_in_bytes = 2*48 = 96

  let (b1, b2, b3) = expand_message(data);

  // received 3 hashes of 256 bits: 768 in total. 
  // 2 arrays of 384 bits are converted into a FieldElement each
  // 384 bits = 6 u64's

  // Convert the 3 hashes of 256 bits into 2 arrays of 48 bytes
  let b1_bytes = into_bytes(b1).into_vec_u8();
  let b2_bytes = into_bytes(b2).into_vec_u8();
  let b3_bytes = into_bytes(b3).into_vec_u8();

  let mut first_array: [u8; 48] = [0u8; 48];
  let mut second_array: [u8; 48] = [0u8; 48];
  let mut i = 0;
  while i < 32 {
    first_array[i] = b1_bytes.get(i).unwrap();
    i += 1; 
  }
  i = 0;
  while i < 16 {
    first_array[i + 32] = b2_bytes.get(i).unwrap();
    i += 1;
  }
  while i < 32 {
    second_array[i - 16] = b2_bytes.get(i).unwrap();
    i += 1; 
  }
  i = 0;
  while i < 32 {
    second_array[i + 16] = b3_bytes.get(i).unwrap();
    i += 1; 
  }

  let fe_b1 = from_okm(first_array);
  let fe_b2 = from_okm(second_array);
  [fe_b1, fe_b2]
}
