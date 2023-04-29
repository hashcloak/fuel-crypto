contract;

use p256::{
  field::FieldElement,
  scalar::Scalar,
  affine::AffinePoint,
  projective::ProjectivePoint,
  signingkey::SigningKey,
  ecdsa::{try_sign_prehashed, verify_prehashed, Signature},
  hmac::generate_k,
  verifyingkey::VerifyingKey
};

use utils::choice::CtOption;

abi MyContract {

  // signing
    fn signingkey_from_bytes(b: [u8;32]) -> SigningKey;
    fn try_sign_prehashed(d: Scalar, k: Scalar, bytes: [u8;32]) -> Signature;
    fn try_sign(key: SigningKey, msg: Vec<u8>) -> Signature;

  // verifying
    fn verify_prehashed(a: AffinePoint, bytes: [u8;32], sig: Signature) -> bool;

  // other
    fn generate_k(data: Vec<u8>, x: [u8;32]) -> Scalar;
  
}

impl MyContract for Contract {
  
    // signing
    fn signingkey_from_bytes(b: [u8;32]) -> SigningKey {
      SigningKey::from_bytes(b)
    }

    fn try_sign_prehashed(d: Scalar, k: Scalar, bytes: [u8;32]) -> Signature {
      try_sign_prehashed(d, k, bytes)
    }

    fn try_sign(key: SigningKey, msg: Vec<u8>) -> Signature {
      key.try_sign(msg)
    }

    // verifying
    fn verify_prehashed(a: AffinePoint, bytes: [u8;32], sig: Signature) -> bool {
      verify_prehashed(a, bytes, sig)
    }

    // other
    fn generate_k(data: Vec<u8>, x: [u8;32]) -> Scalar {
      generate_k(data, x)
    }

}
