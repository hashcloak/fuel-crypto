contract;

use p256::{
  field::FieldElement,
  scalar::*,
  affine::AffinePoint,
  projective::ProjectivePoint,
  // hash_to_field::{hash_to_field, from_okm, expand_message, hash_to_scalar},
  // hash2curve::hash_to_curve,
  publickey::PublicKey,
  signingkey::SigningKey,
  ecdsa::{try_sign_prehashed, verify_prehashed, Signature},
  ecdsa::bits2field,
  hmac::{hmac, generate_k},
  verifyingkey::VerifyingKey
};

use utils::choice::CtOption;

abi MyContract {
  // // field
  //   fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement;
    fn fe_to_montgomery(w: FieldElement) -> FieldElement;
    fn fe_from_montgomery(w: FieldElement) -> FieldElement;
  //   fn sqrt(w: FieldElement) -> CtOption<FieldElement>;
  //   fn invert(w: FieldElement) -> CtOption<FieldElement>;
  //   fn pow_vartime(w: FieldElement, exp: [u64;4]) -> FieldElement;
  //   fn fe_to_bytes(a: FieldElement) -> [u8;32];

  // scalar
    fn scalar_add(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_sub(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_mul(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_invert(a: Scalar) -> CtOption<Scalar>;
    fn scalar_from_bytes(in: [u8; 32]) -> Scalar;

  // // point arithmetic
  //   fn affine_to_proj(p: AffinePoint) -> ProjectivePoint;
    fn proj_to_affine(p: ProjectivePoint) -> AffinePoint;
  //   fn proj_double(p: ProjectivePoint) -> ProjectivePoint;
  //   fn proj_add(p1: ProjectivePoint, p2: ProjectivePoint) -> ProjectivePoint;
  //   fn proj_aff_add(p1_proj: ProjectivePoint, p2_aff: AffinePoint) -> ProjectivePoint;
  //   fn proj_mul(p: ProjectivePoint, k: Scalar) -> ProjectivePoint;

  // // hash2curve
  //   fn hash_to_field(data: Vec<u8>) -> [FieldElement; 2];
  //   fn hash_to_curve(msg: Vec<u8>) -> ProjectivePoint;
  //   fn from_okm (data: [u8;48]) -> FieldElement;
  //   fn expand_message(data: Vec<u8>) -> (b256, b256, b256);

  // signing
    fn signingkey_from_bytes(b: [u8;32]) -> SigningKey;
    fn try_sign_prehashed(d: Scalar, k: Scalar, bytes: [u8;32]) -> Signature;
    fn try_sign(key: SigningKey, msg: Vec<u8>) -> Signature;

  // verifying
    fn verify_prehashed(a: AffinePoint, bytes: [u8;32], sig: Signature) -> bool;
    fn from_secret_scalar(scalar: Scalar) -> VerifyingKey;
    fn verify_prehash(verifyingkey: VerifyingKey, bytes: [u8;32], sig: Signature) -> bool;

  // other
    fn bits2field(bits: Vec<u8>) -> [u8;32];
    fn hmac(data: Vec<u8>, key: [u8;32]) -> [u8;32];
    fn generate_k(data: Vec<u8>, x: [u8;32]) -> Scalar;
  
}

impl MyContract for Contract {
    // // field
    // fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement {
    //     a * b
    // }

    fn fe_to_montgomery(w: FieldElement) -> FieldElement {
      w.fe_to_montgomery()
    }

    fn fe_from_montgomery(w: FieldElement) -> FieldElement {
      w.fe_from_montgomery()
    }

    // fn sqrt(w: FieldElement) -> CtOption<FieldElement> {
    //   w.sqrt()
    // }

    // fn invert(w: FieldElement) -> CtOption<FieldElement> {
    //   w.invert()
    // }

    // fn pow_vartime(w: FieldElement, exp: [u64;4]) -> FieldElement {
    //   w.pow_vartime(exp)
    // }

    // fn fe_to_bytes(a: FieldElement) -> [u8;32] {
    //   a.to_bytes()
    // }

  // scalar
    fn scalar_add(a: Scalar, b: Scalar) -> Scalar {
        a + b
    }

    fn scalar_sub(a: Scalar, b: Scalar) -> Scalar {
        a - b
    }

    fn scalar_mul(a: Scalar, b: Scalar) -> Scalar {
        a * b
    }

    fn scalar_invert(a: Scalar) -> CtOption<Scalar> {
        a.scalar_invert()
    }

    fn scalar_from_bytes(in: [u8; 32]) -> Scalar {
      Scalar::from_bytes(in)
    }

  // // point arithmetic
  //   fn affine_to_proj(p: AffinePoint) -> ProjectivePoint {
  //     ProjectivePoint::from(p)
  //   }

    fn proj_to_affine(p: ProjectivePoint) -> AffinePoint {
      p.into()
    }

  //   fn proj_double(p: ProjectivePoint) -> ProjectivePoint {
  //     p.double()
  //   }

  //   fn proj_add(p1: ProjectivePoint, p2: ProjectivePoint) -> ProjectivePoint {
  //     p1.add(p2)
  //   }

  //   fn proj_aff_add(p1_proj: ProjectivePoint, p2_aff: AffinePoint) -> ProjectivePoint {
  //     p1_proj.add_mixed(p2_aff)
  //   }

  //   fn proj_mul(p: ProjectivePoint, k: Scalar) -> ProjectivePoint {
  //     p.mul(k)
  //   }

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
    
    fn from_secret_scalar(scalar: Scalar) -> VerifyingKey {
      VerifyingKey::from_secret_scalar(scalar)
    }

    fn verify_prehash(verifyingkey: VerifyingKey, bytes: [u8;32], sig: Signature) -> bool {
      verifyingkey.verify_prehash(bytes, sig)
    }

    // other
    fn bits2field (bits: Vec<u8>) -> [u8;32] {
      bits2field(bits)
    }

    fn hmac(data: Vec<u8>, key: [u8;32]) -> [u8;32] {
      hmac(data, key)
    }

    fn generate_k(data: Vec<u8>, x: [u8;32]) -> Scalar {
      generate_k(data, x)
    }

    // fn hash_to_field(data: Vec<u8>) -> [FieldElement; 2] {
    //   hash_to_field(data)
    // }

    // fn hash_to_curve(msg: Vec<u8>) -> ProjectivePoint {
    //   hash_to_curve(msg)
    // }

    // fn from_okm (data: [u8;48]) -> FieldElement {
    //   from_okm(data)
    // }

    // fn expand_message(data: Vec<u8>) -> (b256, b256, b256) {
    //   expand_message(data)
    // }

}
