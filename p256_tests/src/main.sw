contract;

use p256::{
  field::FieldElement,
  scalar::*,
  affine::AffinePoint,
  projective::{ProjectivePoint},
  hash_to_field::{hash_to_field, from_okm, expand_message, hash_to_scalar},
  hash2curve::hash_to_curve,
  signingkey::SigningKey,
  ecdsa::{try_sign_prehash, verify_prehashed},
  // secretkey::SecretKey,
};

use utils::choice::CtOption;

abi MyContract {
  // field
    fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement;
    fn fe_to_montgomery(w: FieldElement) -> FieldElement;
    fn fe_from_montgomery(w: FieldElement) -> FieldElement;
    fn sqrt(w: FieldElement) -> CtOption<FieldElement>;
    fn invert(w: FieldElement) -> CtOption<FieldElement>;
    fn pow_vartime(w: FieldElement, exp: [u64;4]) -> FieldElement;
    fn fe_to_bytes(a: FieldElement) -> [u8;32];

  // scalar
    fn scalar_add(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_sub(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_mul(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_invert(a: Scalar) -> CtOption<Scalar>;

  // point arithmetic
    fn affine_to_proj(p: AffinePoint) -> ProjectivePoint;
    fn proj_to_affine(p: ProjectivePoint) -> AffinePoint;
    fn proj_double(p: ProjectivePoint) -> ProjectivePoint;
    fn proj_add(p1: ProjectivePoint, p2: ProjectivePoint) -> ProjectivePoint;
    fn proj_aff_add(p1_proj: ProjectivePoint, p2_aff: AffinePoint) -> ProjectivePoint;
    fn proj_mul(p: ProjectivePoint, k: Scalar) -> ProjectivePoint;

  // hash2curve
    fn hash_to_field(data: Vec<u8>) -> [FieldElement; 2];
    fn hash_to_curve(msg: Vec<u8>) -> ProjectivePoint;
    fn from_okm (data: [u8;48]) -> FieldElement;
    fn expand_message(data: Vec<u8>) -> (b256, b256, b256);

  // ecdsa related
    fn scalar_from_bytes(in: [u8; 32]) -> Scalar;
    fn signingkey_from_bytes(b: [u8;32]) -> SigningKey;
    fn hash_to_scalar(h: b256) -> Scalar;
    fn try_sign_prehash(d: Scalar, k: Scalar, z: Scalar) -> (Scalar, Scalar);
    fn verify_prehashed(a: AffinePoint, bytes: [u8;32], r: Scalar, s: Scalar) -> bool;

}

impl MyContract for Contract {
    fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement {
        a * b
    }

    fn fe_to_montgomery(w: FieldElement) -> FieldElement {
      w.fe_to_montgomery()
    }

    fn fe_from_montgomery(w: FieldElement) -> FieldElement {
      w.fe_from_montgomery()
    }

    fn sqrt(w: FieldElement) -> CtOption<FieldElement> {
      w.sqrt()
    }

    fn invert(w: FieldElement) -> CtOption<FieldElement> {
      w.invert()
    }

    fn pow_vartime(w: FieldElement, exp: [u64;4]) -> FieldElement {
      w.pow_vartime(exp)
    }

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

    fn affine_to_proj(p: AffinePoint) -> ProjectivePoint {
      ProjectivePoint::from(p)
    }

    fn proj_to_affine(p: ProjectivePoint) -> AffinePoint {
      p.into()
    }

    fn proj_double(p: ProjectivePoint) -> ProjectivePoint {
      p.double()
    }

    fn proj_add(p1: ProjectivePoint, p2: ProjectivePoint) -> ProjectivePoint {
      p1.add(p2)
    }

    fn proj_aff_add(p1_proj: ProjectivePoint, p2_aff: AffinePoint) -> ProjectivePoint {
      p1_proj.add_mixed(p2_aff)
    }

    fn proj_mul(p: ProjectivePoint, k: Scalar) -> ProjectivePoint {
      p.mul(k)
    }
    
    fn hash_to_field(data: Vec<u8>) -> [FieldElement; 2] {
      hash_to_field(data)
    }

    fn hash_to_curve(msg: Vec<u8>) -> ProjectivePoint {
      hash_to_curve(msg)
    }

    fn from_okm (data: [u8;48]) -> FieldElement {
      from_okm(data)
    }

    fn expand_message(data: Vec<u8>) -> (b256, b256, b256) {
      expand_message(data)
    }

    fn scalar_from_bytes(in: [u8; 32]) -> Scalar {
      Scalar::from_bytes(in)
    }

    fn signingkey_from_bytes(b: [u8;32]) -> SigningKey {
      SigningKey::from_bytes(b)
    }

    fn hash_to_scalar(h: b256) -> Scalar {
      hash_to_scalar(h)
    }

    fn try_sign_prehash(d: Scalar, k: Scalar, z: Scalar) -> (Scalar, Scalar) {
      try_sign_prehash(d,k,z)
    }

    fn verify_prehashed(a: AffinePoint, bytes: [u8;32], r: Scalar, s: Scalar) -> bool {
      verify_prehashed(a, bytes, r, s)
    }

    fn fe_to_bytes(a: FieldElement) -> [u8;32] {
      a.to_bytes()
    }

}
