library;

use std::hash::sha256;
use std::bytes::Bytes;
use ::scalar::Scalar;
use utils::choice::Choice;

/*
  Documentation: https://datatracker.ietf.org/doc/html/rfc2104#section-2
  Note: this hmac implementation is for sha256 only!
    
  returns H(key XOR opad, H(key XOR ipad, data))
    where ipad = the byte 0x36 repeated 64 times, opad = the byte 0x5C repeated 64 times.
  
  - key: secret key of 32 bytes
  - data: variable length of bytes
*/
pub fn hmac(data: Vec<u8>, key: [u8;32]) -> [u8;32] {    
  // B = 64
  //ipad = the byte 0x36 repeated B times
  let mut ipad: u8 = 0x36;

  // opad = the byte 0x5C repeated B times
  let mut opad: u8 = 0x5c;

  // (1) append zeros to the end of K to create a B byte string
  //     (e.g., if K is of length 20 bytes and B=64, then K will be
  //      appended with 44 zero bytes 0x00)
  // (2) XOR (bitwise exclusive-OR) the B byte string computed in step
  //     (1) with ipad
  let mut key_xor_ipad: [u8;64] = [0u8; 64];

  let mut i = 0;
  while i < 32 {
    key_xor_ipad[i] = key[i] ^ ipad;
    i = i + 1;
  }

  while i < 64 {
    key_xor_ipad[i] = 0 ^ ipad;
    i = i + 1;
  }

  let mut data_appended = Bytes::new();

  i = 0;
  while i < 64 {
    data_appended.push(key_xor_ipad[i]);
    i = i + 1;
  }

  // (3) append the stream of data 'text' to the B byte string resulting
  //     from step (2)
  i = 0;
  while i < data.len() {
    data_appended.push(data.get(i).unwrap());
    i = i + 1;
  }
  
  // (4) apply H to the stream generated in step (3)
  let mut hash_data_append = data_appended.sha256();    
  let mut key_xor_opad: [u8;64] = [0u8;64];

  // (5) XOR (bitwise exclusive-OR) the B byte string computed in
  //     step (1) with opad
  i = 0;
  while i < 32 {
    key_xor_opad[i] = key[i] ^ opad;
    i = i + 1;
  }
  
  while i < 64 {
    key_xor_opad[i] = 0 ^ opad;
    i = i + 1;
  }

  let mut second_append = Bytes::new();

  i = 0; 
  while i < 64 {
    second_append.push(key_xor_opad[i]);
    i = i + 1;
  }

  // (6) append the H result from step (4) to the B byte string
  //     resulting from step (5)
  let hash_data_append_bytes = into_byte_array(hash_data_append);

  i = 0;
  while i < 32 {
    second_append.push(hash_data_append_bytes[i]);
    i = i + 1;
  }

  // (7) apply H to the stream generated in step (6) and output
  //     the result
  into_byte_array(second_append.sha256())
}

// Needed to extract bytes from hash, comes from answer on Fuel forum
// https://forum.fuel.network/t/how-can-i-transform-b256-into-u8-32/1124/2?u=elena
pub fn decompose(val: b256) -> (u64, u64, u64, u64) {
  asm(r1: __addr_of(val)) { r1: (u64, u64, u64, u64) }
}

// Comes from Fuel forum: https://forum.fuel.network/t/how-can-i-transform-b256-into-u8-32/1124/2?u=elena
pub fn compose(words: (u64, u64, u64, u64)) -> b256 {
  asm(r1: __addr_of(words)) { r1: b256 }
}

pub fn into_byte_array(b: b256) -> [u8;32] {
  let mut res = [0u8;32];
  let (b0, b1, b2, b3)  = decompose(b);
  let mut i = 0;
  let mut j = 0;
  let mut next_byte: u8 = 0;
  while i < 8 { 
    next_byte = b0 >> ((7-i)*8);
    res[j] = next_byte;
    i += 1;
    j += 1;
  }
  i = 0;
  while i < 8 { 
    next_byte = b1 >> ((7-i)*8);
    res[j] = next_byte;
    i += 1;
    j += 1;
  }
  i = 0;
  while i < 8 { 
    next_byte = b2 >> ((7-i)*8);
    res[j] = next_byte;
    i += 1;
    j += 1;
  }
  i = 0;
  while i < 8 {
    next_byte =  b3 >> ((7-i)*8);
    res[j] = next_byte;
    i += 1;
    j += 1;
  }
  res
}

// Documentation https://datatracker.ietf.org/doc/html/rfc6979#section-3
// returns `k`, ephemeral scalar value for deterministic ecdsa
// - data: byte array over which k is calculated
// - x: secretKey in big-endian format
pub fn generate_k(data: Vec<u8>, x: [u8;32]) -> Scalar {
    
  /*
  sha256 does not give correct result for certain inputs in Sway.
  It seems to be working correctly for Bytes, therefore we do a conversion to Bytes to be safe.
  This should be removed whenever possible!
  */
  let mut m = Bytes::new();

  let mut i = 0;
  while i < data.len() {
    m.push(data.get(i).unwrap());
    i = i + 1;
  }
  //  a.  Process m through the hash function H, yielding:
  // h1 = H(m)
  // (h1 is a sequence of hlen(= 256) bits)
  let mut h1 = m.sha256();

  // b. set V = 0x01 0x01 0x01 ... 0x01 such that the length of V, in bits, is equal to 8*ceil(hlen/8)
  // c.  Set: K = 0x00 0x00 0x00 ... 0x00 such that the length of K, in bits, is equal to 8*ceil(hlen/8).

  let mut V: [u8; 32] = [0x01;32];
  let mut K: [u8; 32] = [0x00;32];

  // d.  Set: K = HMAC_K(V || 0x00 || int2octets(x) || bits2octets(h1))
  // data_v_x_h1 = V || 0x00 || int2octets(x) || bits2octets(h1)
  // key = K
  let mut data_v_x_h1: Vec<u8> = Vec::new();

  i = 0;
  while i < 32 {
    // pushing V
    data_v_x_h1.push(0x01);
    i = i + 1;
  }

  data_v_x_h1.push(0x00);

  i = 0;
  let x_int2octets: [u8;32] = int2octets(x);
  while i < 32 {
    // pushing x
    data_v_x_h1.push(x_int2octets[i]);
    i = i + 1;
  }

  let h1_bits2octets: [u8;32] = bits2octets(h1);
  i = 0;
  while i < 32 {
    // pushing h1
    data_v_x_h1.push(h1_bits2octets[i]);
    i = i + 1;
  }

  K = hmac(data_v_x_h1, K);

  // e.  Set: V = HMAC_K(V)
  V = hmac(arr_to_vec(V), K);

  // f.  Set: K = HMAC_K(V || 0x01 || int2octets(x) || bits2octets(h1))
  // data2 = V || 0x01 || int2octets(x) || bits2octets(h1)
  // key = K 
  let mut data_2: Vec<u8> = Vec::new();

  i = 0;
  while i < 32 {
    data_2.push(V[i]);
    i = i + 1;
  }

  data_2.push(0x01);

  i = 0;
  while i < 32 {
    data_2.push(x_int2octets[i]);
    i = i + 1;
  }

  i = 0;
  while i < 32 {
    data_2.push(h1_bits2octets[i]);
    i = i + 1;
  }

  // f.  Set: K = HMAC_K(V || 0x01 || int2octets(x) || bits2octets(h1))
  K = hmac(data_2, K);

  // g.  Set: V = HMAC_K(V)
  V = hmac(arr_to_vec(V), K);

  let mut t_found = false;
  let mut k_option = Scalar::zero();

  while !t_found {
    // T must have bitlength 256, which is the case after running HMAC once
    let T_array = hmac(arr_to_vec(V), K);
    i = 0;
    let mut j = 4;
    let mut u64s: [u64;4] = [0;4];
    while i < 32 {
      u64s[j-1] = (T_array[i + 0] << 56)
        .binary_or(T_array[i + 1] << 48)
        .binary_or(T_array[i + 2] << 40)
        .binary_or(T_array[i + 3] << 32)
        .binary_or(T_array[i + 4] << 24)
        .binary_or(T_array[i + 5] << 16)
        .binary_or(T_array[i + 6] << 8)
        .binary_or(T_array[i + 7]);
      j -= 1;
      i += 8;
    }
    
    k_option = Scalar { ls: u64s};
    let reduced_k_option = k_option + Scalar::zero();
    // check if k_option was already within range
    t_found = k_option.ct_eq(reduced_k_option).unwrap_as_bool();

    // TODO it should be checked that this k doesn't lead to kG mod p mod q being 0
    // the chance of this happening is really slim and the check quite expensive. 
    // @Mikerah Should we add it here, or add the check to try_sign_prehashed? There, the computation of kG is already done, so it would not be a performance burden.

    if !t_found {
      let mut v_append_0: Vec<u8> = Vec::new();
      i = 0;
      while i < 32 {
        v_append_0.push(V[i]);
        i += 1;
      }
      v_append_0.push(0x00);
      K = hmac(v_append_0, K);
      V = hmac(arr_to_vec(V), K);
    }
  }

  k_option
}

fn arr_to_vec(a: [u8;32]) -> Vec<u8> {
  let mut res = Vec::new();
  let mut i = 0;
  while i < 32 {
    res.push(a[i]);
    i += 1;
  }
  res
}

// Documentation: https://datatracker.ietf.org/doc/html/rfc6979#section-2.3.7
fn int2octets(x: [u8;32]) -> [u8;32] {
  // value x modulo q
  let x_reduced_scalar: Scalar = Scalar::from_bytes(x);
  x_reduced_scalar.to_bytes()
}

fn bits2octets(h: b256) -> [u8;32] {
  let (b0, b1, b2, b3) = decompose(h);

  // value x modulo q
  let mut z2 = Scalar{ls: [b3, b2, b1, b0]} + Scalar::zero();

  z2.to_bytes()
}