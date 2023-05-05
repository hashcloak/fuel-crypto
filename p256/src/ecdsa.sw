library;

use ::scalar::Scalar;
use ::utils::choice::{Choice, CtOption};
use ::affine::AffinePoint;
use ::projective::ProjectivePoint;
use std::logging::log;
use ::field::FieldElement;

pub struct Signature {
  r: Scalar,
  s: Scalar
}

// returns whether the given signature is valid, given the hash that was signed and publickey
// - a: public key
// NOTE: coordinates of a are in Montgomery form
// - bytes: hash that was signed
// - sig: signature to be checked
pub fn verify_prehashed(a: AffinePoint, bytes: [u8;32], sig: Signature) -> bool {
  // Ref: https://github.com/RustCrypto/signatures/blob/91a62e8abaca19bcdf126b34f60424144ee46dfe/ecdsa/src/hazmat.rs#L160
  let z = Scalar::from_bytes(bytes);
  let s_inv: Scalar = sig.s.scalar_invert().unwrap();
  let u1: Scalar = z * s_inv;
  let u2: Scalar = sig.r * s_inv;

  let g_proj = ProjectivePoint::from(AffinePoint::generator());
  let u1_g = g_proj.mul(u1);

  let a_proj_point = ProjectivePoint::from(a);
  let u2_a = a_proj_point.mul(u2);

  let x: ProjectivePoint = u1_g.add(u2_a);
  let res: FieldElement = x.into().x.fe_from_montgomery();
  let res_scalar: Scalar = Scalar::from_bytes(res.to_bytes());

  if res_scalar.ct_eq(sig.r).unwrap_as_bool() {
    true
  } else {
    false
  }
}
