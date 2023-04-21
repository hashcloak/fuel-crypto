library;

use ::scalar::Scalar;
use ::utils::choice::{Choice, CtOption};
use ::affine::AffinePoint;
use ::projective::ProjectivePoint;
// use ::secretkey::SecretKey;
use std::logging::log;
use ::field::FieldElement;

// https://github.com/RustCrypto/signatures/blob/91a62e8abaca19bcdf126b34f60424144ee46dfe/ecdsa/src/hazmat.rs#L75

// k: random secret used while signing 
// d: secret key
//bytes: message digest to be signed. MUST BE OUTPUT OF A CRYPTOGRAPHICALLY SECURE DIGEST ALGORITHM!!!
pub fn try_sign_prehash(d: Scalar, k: Scalar, bytes: [u8;32]) -> (Scalar, Scalar){

    let z = Scalar::from_bytes(bytes);
    // check if k is non-zero
    assert(!k.ct_eq(Scalar::zero()).unwrap_as_bool());

    let k_inv = Scalar::scalar_invert(k);
    // log(k_inv);
    //checks if k_inv exist or not
    assert(k_inv.is_some.unwrap_as_bool());
    let g_affine = ProjectivePoint::from(AffinePoint::generator());
    let g_x_montgomery = FieldElement::fe_to_montgomery(g_affine.x);
    let g_y_montgomery = FieldElement::fe_to_montgomery(g_affine.y);
    let g_z_montgomery = FieldElement::fe_to_montgomery(g_affine.z);

    let g_projective_montgomery = ProjectivePoint{x: g_x_montgomery, y: g_y_montgomery, z: g_z_montgomery};
    let R_montgomery = ProjectivePoint::into(ProjectivePoint::mul(g_projective_montgomery, k));
    let R = AffinePoint{x: FieldElement::fe_from_montgomery(R_montgomery.x), y: FieldElement::fe_from_montgomery(R_montgomery.y), infinity: 0};
    log(R.x);
    log(R.y);
    //reduces R.x into element of the scalar field 
    let r = Scalar{ls: [R.x.ls[0], R.x.ls[1], R.x.ls[2], R.x.ls[3] ]} + Scalar::zero();

    //computes s as a signature over r and z
    let s = k_inv.value * (z + (r * d));

    //check if s is zero or not
    assert(!s.ct_eq(Scalar::zero()).unwrap_as_bool());

    (r,s)
}

// Reference impl https://github.com/RustCrypto/signatures/blob/91a62e8abaca19bcdf126b34f60424144ee46dfe/ecdsa/src/hazmat.rs#L160
// a is the public key
// bytes is the hash
// (r,s) signature
pub fn verify_prehashed(a: AffinePoint, bytes: [u8;32], r: Scalar, s: Scalar) -> bool {
    let z = Scalar::from_bytes(bytes);
    let s_inv: Scalar = s.scalar_invert().unwrap();
    let u1: Scalar = z * s_inv;
    let u2: Scalar = r * s_inv;

    let g_affine = ProjectivePoint::from(AffinePoint::generator());
    let g_x_montgomery = FieldElement::fe_to_montgomery(g_affine.x);
    let g_y_montgomery = FieldElement::fe_to_montgomery(g_affine.y);
    let g_z_montgomery = FieldElement::fe_to_montgomery(g_affine.z);
    let g_projective_montgomery = ProjectivePoint{x: g_x_montgomery, y: g_y_montgomery, z: g_z_montgomery};
    let u1_g = g_projective_montgomery.mul(u1);

    let a_proj_point = ProjectivePoint::from(a);
    let a_x_montgomery = FieldElement::fe_to_montgomery(a_proj_point.x);
    let a_y_montgomery = FieldElement::fe_to_montgomery(a_proj_point.y);
    let a_z_montgomery = FieldElement::fe_to_montgomery(a_proj_point.z);
    let a_projective_montgomery = ProjectivePoint{x: a_x_montgomery, y: a_y_montgomery, z: a_z_montgomery};
    let u2_a = a_projective_montgomery.mul(u2);

    let x: ProjectivePoint = u1_g.add(u2_a);
    let res: FieldElement = x.into().x.fe_from_montgomery();
    let res_scalar: Scalar = Scalar::from_bytes(res.to_bytes());

    if res_scalar.ct_eq(r).unwrap_as_bool() {
      true
    } else {
      false
    }
}


/// This is used to convert a message digest whose size may be smaller or
/// larger than the size of the curve's scalar field into a serialized
/// (unreduced) field element.
///
/// [RFC6979 § 2.3.2]: https://datatracker.ietf.org/doc/html/rfc6979#section-2.3.2
/// [SEC1]: https://www.secg.org/sec1-v2.pdf
pub fn bits2field (bits: Vec<u8>) -> [u8;32] {
  
  //if length of bits less than half of digest raise error
  if bits.len() < 16 {
    //TODO: raise error
  }
  //if bits length is smaller than 32, pad it with zeros
  // if bits length is more than 32(larger than the field size), truncate 

  let mut fieldBytes = [0u8;32];
  let mut i = 0; 
  while i < bits.len() && i < 32 {
    fieldBytes[i] = bits.get(i).unwrap();
    i = i + 1;
  }

  fieldBytes
  }
