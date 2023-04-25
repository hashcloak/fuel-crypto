library;

use ::scalar::Scalar;
use ::affine::AffinePoint;
use ::projective::ProjectivePoint;
use ::publickey::PublicKey;
use ::ecdsa::{Signature, verify_prehashed};

pub struct VerifyingKey {
    inner: PublicKey,
}

impl VerifyingKey {
  // TODO add nonzeroscalar struct
  pub fn from_secret_scalar(scalar: Scalar) -> Self {
    let affinePoint: AffinePoint = (ProjectivePoint::generator().mul(scalar)).into();
    VerifyingKey { inner: PublicKey { point: affinePoint }}
  }

  pub fn verify_prehash(self, bytes: [u8;32], sig: Signature) -> bool {
      verify_prehashed(self.inner.point, bytes, sig)
  }
}
