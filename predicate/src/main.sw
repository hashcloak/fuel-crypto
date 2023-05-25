predicate;

use p256::{
    modular_helper::to_bytes,
    field::FieldElement,
    scalar::Scalar,
    affine::AffinePoint,
    ecdsa::Signature,
    verifyingkey::{
        PublicKey,
        VerifyingKey,
    }
};

configurable {
    PUBKEY: [u8; 64] = [0u8; 64]
}

pub fn bytes_to_u64s(bytes: [u8; 32]) -> [u64;4] {
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
    u64s
}


pub struct signature_bytes {
    msg: b256,
    r: b256,
    s: b256,
}

pub fn decompose(val: b256) -> (u64, u64, u64, u64) {
  asm(r1: __addr_of(val)) { r1: (u64, u64, u64, u64) }
}

// TODO this should verify signature for pubkey
fn main(sig: signature_bytes ) -> bool {

    let (r0, r1, r2, r3) = decompose(sig.r);
    let (s0, s1, s2, s3) = decompose(sig.s);

    let (m0, m1, m2, m3) = decompose(sig.msg);
    let reduced = [m3, m2, m1, m0];

    let mut msg_bytes: [u8;32] = [0u8;32];
  
  let mut i = 4;
  let mut j = 0;
  while j < 32 {
    i -= 1; // to prevent overflow at last run
    msg_bytes[j] = reduced[i] >> 56;
    msg_bytes[j + 1] = reduced[i] >> 48;
    msg_bytes[j + 2] = reduced[i] >> 40;
    msg_bytes[j + 3] = reduced[i] >> 32;
    msg_bytes[j + 4] = reduced[i] >> 24;
    msg_bytes[j + 5] = reduced[i] >> 16;
    msg_bytes[j + 6] = reduced[i] >> 8;
    msg_bytes[j + 7] = reduced[i];        
    j += 8;
  }

    let r = Scalar{ls: [r3, r2, r1, r0]};
    let s = Scalar{ls: [s3, s2, s1, s0]};

    let sign = Signature {r: r, s: s};

    let mut pub_x_bytes = [0u8;32];
    let mut pub_y_bytes = [0u8;32];

    let mut i = 0; 
    while i < 32 {
        pub_x_bytes[i] = PUBKEY[i];
        pub_y_bytes[i] = PUBKEY[i+32];
        i = i + 1;
    }

    let pub_x = FieldElement{ls: bytes_to_u64s(pub_x_bytes)};
    let pub_y = FieldElement{ls: bytes_to_u64s(pub_y_bytes)};

    let public_key = AffinePoint{x: pub_x, y: pub_y, infinity: 0};
    let vk = VerifyingKey {
        inner: PublicKey {
            point: public_key,
        },
    };

    VerifyingKey::verify_prehash_with_pubkey(vk, msg_bytes, sign)
    // PUBKEY[0] == pubkey[0]
}
