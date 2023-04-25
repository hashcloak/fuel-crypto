library;

use std::hash::sha256;
use std::bytes::Bytes;
use ::scalar::Scalar;
use utils::choice::Choice;

pub fn hmac(data: Vec<u8>, key: [u8;32]) -> Vec<u8> {
    //!!!!!!!!NOTICE!!!!!!!!!!
    // This hmac implementation is for sha256 only
    // Assumes that key size is at most 256bits (32 bytes) keeping in mind about p256 curve

    // https://datatracker.ietf.org/doc/html/rfc2104#section-2
    //    We assume H to be a cryptographic
    //    hash function where data is hashed by iterating a basic compression
    //    function on blocks of data.   We denote by B the byte-length of such
    //    blocks (B=64 for all the above mentioned examples of hash functions),
    //    and by L the byte-length of hash outputs (L=16 for MD5, L=20 for
    //    SHA-1) 
    
    // B = 64
    //ipad = the byte 0x36 repeated B times
    let mut ipad: u8 = 0x36;

    // opad = the byte 0x5C repeated B(32 time for sha256) times
    let mut opad: u8 = 0x5c;

    // (1) append zeros to the end of K to create a B byte string
    //     (e.g., if K is of length 20 bytes and B=64, then K will be
    //      appended with 44 zero bytes 0x00)
    // (2) XOR (bitwise exclusive-OR) the B byte string computed in step
    //     (1) with ipad
    // (3) append the stream of data 'text' to the B byte string resulting
    //     from step (2)
    // (4) apply H to the stream generated in step (3)
    // (5) XOR (bitwise exclusive-OR) the B byte string computed in
    //     step (1) with opad
    // (6) append the H result from step (4) to the B byte string
    //     resulting from step (5)
    // (7) apply H to the stream generated in step (6) and output
    //     the result

    
    let mut key_xor_ipad: [u8;64] = [0u8; 64];

    let mut i = 0;
    while i < 32 {
        key_xor_ipad[i] = key[i];
        i = i + 1;
    }

    i = 0;
    while i < 64 {
        key_xor_ipad[i] = key_xor_ipad[i] ^ ipad;
        i = i + 1;
    }

    let mut data_appended = Bytes::new();

    i = 0;
    while i < 64 {
        data_appended.push(key_xor_ipad[i]);
        i = i + 1;
    }

    i = 0;
    while i < data.len() {
        data_appended.push(data.get(i).unwrap());
        i = i + 1;
    }
    
    let mut hash_data_append = data_appended.sha256();

    
    let mut key_xor_opad: [u8;64] = [0u8;64];

    i = 0;
    while i < 32 {
        key_xor_opad[i] = key[i];
        i = i + 1;
    }
    
    i = 0;
    while i < 64 {
        key_xor_opad[i] = key_xor_opad[i] ^ opad;
        i = i + 1;
    }

    let mut second_append = Bytes::new();

    i = 0; 
    while i < 64 {
        second_append.push(key_xor_opad[i]);
        i = i + 1;
    }

    let hash_data_append_bytes = into_bytes(hash_data_append).into_vec_u8();

    i = 0;
    while i < 32 {
        second_append.push(hash_data_append_bytes.get(i).unwrap());
        i = i + 1;
    }
    

    into_bytes(second_append.sha256()).into_vec_u8()

}

// TODO
// decompose is also defined in hash_to_field.
// if we keep hash_to_field then instead of defining here we will directly call it.

// Needed to extract bytes from hash, comes from answer on Fuel forum
// https://forum.fuel.network/t/how-can-i-transform-b256-into-u8-32/1124/2?u=elena
fn decompose(val: b256) -> (u64, u64, u64, u64) {
    asm(r1: __addr_of(val)) { r1: (u64, u64, u64, u64) }
}

fn compose(words: (u64, u64, u64, u64)) -> b256 {
    asm(r1: __addr_of(words)) { r1: b256 }
}

// TODO
// into_bytes is also defined in hash_to_field.
// if we keep hash_to_field then instead of defining here we will directly call it.
pub fn into_bytes(b: b256) -> Bytes {
  let mut res = Bytes::new();
  let (b0, b1, b2, b3)  = decompose(b);
  let mut i = 0;
  let mut next_byte: u8 = 0;
  while i < 8 { 
    next_byte = b0 >> ((7-i)*8);
    res.push(next_byte);
    i += 1;
  }
  i = 0;
  while i < 8 { 
    next_byte = b1 >> ((7-i)*8);
    res.push(next_byte);
    i += 1;
  }
  i = 0;
  while i < 8 { 
    next_byte = b2 >> ((7-i)*8);
    res.push(next_byte);
    i += 1;
  }
  i = 0;
  while i < 8 {
    next_byte =  b3 >> ((7-i)*8);
    res.push(next_byte);
    i += 1;
  }
  res
}

// https://datatracker.ietf.org/doc/html/rfc6979#section-3
// generating `k`: ephemeral scalar value for deterministic ecdsa
// msg: data
// x: secretKey in big-endian format
pub fn generate_k(data: Vec<u8>, x: [u8;32]) -> Scalar {
    
    // This step might be redundant but is there because sha256 of sway is giving different value than expected 
    // hence converting into bytes in order to get desire result
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

    let mut V: Vec<u8> = Vec::new();
    i = 0;
    while i < 32 {
        V.push(0x01);
        i += 1;
    }
    let mut K: [u8; 32] = [0x00; 32];

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
    let x_int2octets = int2octets(x);
    while i < 32 {
        // pushing x
        data_v_x_h1.push(x_int2octets.get(i).unwrap());
        i = i + 1;
    }

    let h1_bits2octets = bits2octets(h1);
    i = 0;
    while i < 32 {
        // pushing h1
        data_v_x_h1.push(h1_bits2octets.get(i).unwrap());
        i = i + 1;
    }

    K = vec_to_array(hmac(data_v_x_h1, K));

    // e.  Set: V = HMAC_K(V)
    V = hmac(V, K);

    // f.  Set: K = HMAC_K(V || 0x01 || int2octets(x) || bits2octets(h1))
    // data2 = V || 0x01 || int2octets(x) || bits2octets(h1)
    // key = K 
    let mut data_2: Vec<u8> = Vec::new();

    i = 0;
    while i < 32 {
        data_2.push(V.get(i).unwrap());
        i = i + 1;
    }

    data_2.push(0x01);

    i = 0;
    while i < 32 {
        data_2.push(x_int2octets.get(i).unwrap());
        i = i + 1;
    }

    i = 0;
    while i < 32 {
        data_2.push(h1_bits2octets.get(i).unwrap());
        i = i + 1;
    }

    // f.  Set: K = HMAC_K(V || 0x01 || int2octets(x) || bits2octets(h1))
    K = vec_to_array(hmac(data_2, K));

    // g.  Set: V = HMAC_K(V)
    V = hmac(V , K);

    let mut t_found = false;
    let mut k_option = Scalar::zero();

    while !t_found {
      // T must have bitlength 256, which is the case after running HMAC once
      let T_array = vec_to_array(hmac(V , K));
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

      // TODO it should be checked that this k doesn't lead to gˆk mod p mod q being 0
      // the chance of this happening is really slim and the check quite expensive. Is this check already added along the way?

      if !t_found {
        let mut v_append_0: Vec<u8> = Vec::new();
        i = 0;
        while i < 32 {
          v_append_0.push(V.get(i).unwrap());
          i += 1;
        }
        v_append_0.push(0x00);
        K = vec_to_array(hmac(v_append_0, K));
        V = hmac(V, K);
      }
    }

    k_option
}

//used in generate_k
// TODO should have a different name because it only works for fixed length
// TODO should have an assert on the length of data
fn vec_to_array(data: Vec<u8>) -> [u8;32] {

    let mut result: [u8; 32] = [0u8; 32];

    let mut i = 0;
    while i < 32 {
        result[i] = data.get(i).unwrap();
        i = i + 1;
    }

    result
}


// https://datatracker.ietf.org/doc/html/rfc6979#section-2.3.7
fn int2octets(x: [u8;32]) -> Vec<u8> {
    // value x modulo q
    let x_reduced_Scalar: Scalar = Scalar::from_bytes(x);
    let mut x_256 = compose((x_reduced_Scalar.ls[3], x_reduced_Scalar.ls[2], x_reduced_Scalar.ls[1], x_reduced_Scalar.ls[0]));

    into_bytes(x_256).into_vec_u8()
}

fn bits2octets (h: b256) -> Vec<u8> {

    let  (b0, b1, b2, b3) = decompose(h);

    // value x modulo q
    let mut z2 = Scalar{ls: [b3, b2, b1, b0]};

    let mut z2_256 = compose((z2.ls[3], z2.ls[2], z2.ls[1], z2.ls[0]));

    into_bytes(z2_256).into_vec_u8()

}