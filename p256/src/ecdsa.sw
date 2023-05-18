library;

use ::scalar::Scalar;
use ::modular_helper::ct_eq; 
use ::utils::choice::{Choice, CtOption};
use ::affine::AffinePoint;
use ::projective::ProjectivePoint;
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
  // checks are introduced from https://www.secg.org/sec1-v2.pdf 
  // and from bitcoin ecdsa https://github.com/bitcoin-core/secp256k1/blob/master/src/secp256k1.c#L444

  //If r and s are not both integers in the interval [1, n − 1], output “invalid” and stop.
  
  //Forcing mod operation
  let mod_r = sig.r + Scalar::zero();
  let mod_s = sig.s + Scalar::zero();
  
  // checking if r != 0 and mod_r == r implies r is in the interval [1, n − 1]
  // same check for s.
  assert(ct_eq(sig.r.ls, [0,0,0,0]).unwrap_as_bool() == false);
  assert(ct_eq(sig.s.ls, [0,0,0,0]).unwrap_as_bool() == false);
  assert(ct_eq(mod_r.ls, sig.r.ls).unwrap_as_bool() == true);
  assert(ct_eq(mod_s.ls, sig.s.ls).unwrap_as_bool() == true);

    //converting bytes hash into [u64;4]
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

  //cheks if bytes hash is non-zero
  assert(ct_eq(u64s, [0,0,0,0]).unwrap_as_bool() == false);

  // checks if public key is non-zero
  assert(ct_eq(a.x.ls, [0,0,0,0]).unwrap_as_bool() == false);
  assert(ct_eq(a.y.ls, [0,0,0,0]).unwrap_as_bool() == false);

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
  assert(ct_eq(x.z.ls, [0,0,0,0]).unwrap_as_bool() == false);
  
  let res: FieldElement = x.into().x.fe_from_montgomery();
  let res_scalar: Scalar = Scalar::from_bytes(res.to_bytes());

  if res_scalar.ct_eq(sig.r).unwrap_as_bool() {
    true
  } else {
    false
  }
}
