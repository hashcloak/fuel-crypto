library;

use ::field::FieldElement;
use ::scalar::Scalar;
use ::affine::AffinePoint;
use ::projective::ProjectivePoint;
use ::ecdsa::{Signature, verify_prehashed};
use ::utils::choice::Choice;

pub struct PublicKey {
  point: AffinePoint,
}

pub struct VerifyingKey {
  inner: PublicKey,
}

impl VerifyingKey {

  // returns verifyingkey in montgomery form
  pub fn from_secret_scalar(scalar: Scalar) -> Self {
    assert(!scalar.ct_eq(Scalar::zero()).unwrap_as_bool());
    // Ref: https://github.com/RustCrypto/signatures/blob/master/ecdsa/src/verifying.rs#L92
    let affinePoint: AffinePoint = (ProjectivePoint::generator().mul(scalar)).into();
    VerifyingKey { inner: PublicKey { point: affinePoint }}
  }
}

impl VerifyingKey {

  // There are 2 separate verification functions, to allow input with a pubkey and with a secret scalar.

// TODO uncomment when possible. Having both verification algorithms gives the following error: "Unable to offset into the data section more than 2^12 bits. Unsupported data section length."
  // returns whether signature is verified, using the scalar as input for verification key
  // Note: converting scalar results in verifyingkey in montgomery form
  // pub fn verify_prehash_with_secret_scalar(scalar: Scalar, bytes: [u8;32], sig: Signature) -> bool {
  //   // Ref: https://github.com/RustCrypto/signatures/blob/master/ecdsa/src/verifying.rs#L163
  //   let pubkey = Self::from_secret_scalar(scalar);
  //   verify_prehashed(pubkey.inner.point, bytes, sig)
  // }

  // returns whether signature is verified, using the given verifyingkey
  // Note: pubkey is expected to be in normal form and will be converted to Montgomery form
  pub fn verify_prehash_with_pubkey(self, bytes: [u8;32], sig: Signature) -> bool {
    // Ref: https://github.com/RustCrypto/signatures/blob/master/ecdsa/src/verifying.rs#L163

    // self.inner.point is affine point in normal form, so conversion is needed
    let a_x_montgomery = FieldElement::fe_to_montgomery(self.inner.point.x);
    let a_y_montgomery = FieldElement::fe_to_montgomery(self.inner.point.y);
    let a_proj = AffinePoint {x: a_x_montgomery, y: a_y_montgomery, infinity: self.inner.point.infinity };

    verify_prehashed(a_proj, bytes, sig)
  }
}
