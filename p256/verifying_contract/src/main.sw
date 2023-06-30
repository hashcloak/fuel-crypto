contract;

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

abi P256SignatureVerification {
  #[storage()]
  fn verify_signature(pubkey: PublicKey, sign: Signature, msg: b256) -> bool;
}

pub struct signature_bytes {
    msg: b256,
    r: b256,
    s: b256,
}

pub fn decompose(val: b256) -> (u64, u64, u64, u64) {
  asm(r1: __addr_of(val)) { r1: (u64, u64, u64, u64) }
}

fn verify_msg(signature: Signature, verify_key: VerifyingKey, msg: b256) -> bool {
    
// returns bytes in big endian
    let (l0, l1, l2, l3) = decompose(msg);
    let mut res: [u8;32] = [0u8;32];
    let reduced: [u64;4] = [l3, l2, l1, l0];
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

    let result = VerifyingKey::verify_prehash_with_pubkey(verify_key, res, signature);
    
    result
}


impl P256SignatureVerification for Contract {

  fn verify_signature(pubkey: PublicKey, sign: Signature, msg: b256) -> bool {
    let vk = VerifyingKey {
        inner: pubkey,
    };
    let mut verified = false;
    verified = verify_msg(sign, vk, msg);

    verified
  }

}
