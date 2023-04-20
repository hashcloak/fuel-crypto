library;

use ::scalar::Scalar;
use ::utils::choice::Choice;
use ::affine::AffinePoint;
use ::projective::ProjectivePoint;
// use ::secretkey::SecretKey;
use std::logging::log;
use ::field::FieldElement;

// https://github.com/RustCrypto/signatures/blob/91a62e8abaca19bcdf126b34f60424144ee46dfe/ecdsa/src/hazmat.rs#L75
// TODO: FieldBytes implementation
// From z of type fieldBytes, it is converted(reduced) into a scalar mod n (order of the p256 curve)
// as of now, we consider z to  be the prehash scalar value
// k: random secret used while signing 
// d: secret key
pub fn try_sign_prehash(d: Scalar, k: Scalar, z: Scalar) -> (Scalar, Scalar){

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