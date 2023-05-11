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

// For checking the validity of the signature
fn assert_eq(res: [u64;4], expected: [u64;4]) {
  assert(res[0] == expected[0] && res[1] == expected[1] && res[2] == expected[2] && res[3] == expected[3]);
}

fn assert_neq(res: [u64;4], expected: [u64;4]) {
  assert(res[0] != expected[0] || res[1] != expected[1] || res[2] != expected[2] || res[3] != expected[3]);
}

// returns whether the given signature is valid, given the hash that was signed and publickey
// - a: public key
// NOTE: coordinates of a are in Montgomery form
// - bytes: hash that was signed
// - sig: signature to be checked
pub fn verify_prehashed(a: AffinePoint, bytes: [u8;32], sig: Signature) -> bool {
  // Ref: https://github.com/RustCrypto/signatures/blob/91a62e8abaca19bcdf126b34f60424144ee46dfe/ecdsa/src/hazmat.rs#L160
  // checks are introduced from https://www.secg.org/sec1-v2.pdf 
  // and from bitcoin ecdsa https://github.com/bitcoin-core/secp256k1/blob/master/src/secp256k1.c#L444

  //If r and s are not both integers in the interval [1, n − 1], output “invalid” and stop.
  
  //Forcing mod operation
  let mod_r = sig.r + Scalar::zero();
  let mod_s = sig.s + Scalar::zero();
  
  // checking if r != 0 and mod_r == r implies r is in the interval [1, n − 1]
  // same check for s.
  assert_neq(sig.r.ls, Scalar::zero().ls);
  assert_neq(sig.s.ls, Scalar::zero().ls);
  assert_eq(mod_r.ls, sig.r.ls);
  assert_eq(mod_s.ls, sig.s.ls);

  //cheks if hash is non-zero
  let mut i = 0;
  while i < 32 {
    if bytes[i] != 0 {
      break;
    }
    i = i + 1;
  }
  assert(i != 32);

  // checks if public key is non-zero
  assert_neq(a.x.ls, [0,0,0,0]);
  assert_neq(a.y.ls, [0,0,0,0]);

  let z = Scalar::from_bytes(bytes);
  let s_inv: Scalar = sig.s.scalar_invert().unwrap();
  let u1: Scalar = z * s_inv;
  let u2: Scalar = sig.r * s_inv;

  let g_proj = ProjectivePoint::from(AffinePoint::generator());
  let u1_g = g_proj.mul(u1);

  let a_proj_point = ProjectivePoint::from(a);
  let u2_a = a_proj_point.mul(u2);

  let x: ProjectivePoint = u1_g.add(u2_a);

  //checking if x is point at infinity 
  assert_neq(x.z.ls, [0,0,0,0]);
  
  let res: FieldElement = x.into().x.fe_from_montgomery();
  let res_scalar: Scalar = Scalar::from_bytes(res.to_bytes());

  if res_scalar.ct_eq(sig.r).unwrap_as_bool() {
    true
  } else {
    false
  }
}
