contract;

use p256::{
  field::FieldElement,
  scalar::*,
  affine::AffinePoint,
  projective::ProjectivePoint,
  ecdsa::Signature,
  verifyingkey::VerifyingKey
};

use utils::choice::CtOption;

abi MyContract {

  // field
    fn fe_from_montgomery(w: FieldElement) -> FieldElement;

  // verifying
    fn from_secret_scalar(scalar: Scalar) -> VerifyingKey;
    
    // Gives error: 'Unable to offset into the data section more than 2^12 bits. Unsupported data section length.'
    // fn verify_prehash_with_secret_scalar(scalar: Scalar, bytes: [u8;32], sig: Signature) -> bool;
    
    fn verify_prehash_with_pubkey(vk: VerifyingKey, bytes: [u8;32], sig: Signature) -> bool; 
}

impl MyContract for Contract {

  //field
    fn fe_from_montgomery(w: FieldElement) -> FieldElement {
      FieldElement::fe_from_montgomery(w)
    }

  // verifying
    fn from_secret_scalar(scalar: Scalar) -> VerifyingKey {
      VerifyingKey::from_secret_scalar(scalar)
    }

    // fn verify_prehash_with_secret_scalar(scalar: Scalar, bytes: [u8;32], sig: Signature) -> bool {
    //   VerifyingKey::verify_prehash_with_secret_scalar(scalar, bytes, sig)
    // }

    fn verify_prehash_with_pubkey(vk: VerifyingKey, bytes: [u8;32], sig: Signature) -> bool {
      vk.verify_prehash_with_pubkey(bytes, sig)
    }

}
