library;

use ::scalar::Scalar;
use ::affine::AffinePoint;
use ::projective::ProjectivePoint;
use ::publickey::PublicKey;

pub struct VerifyingKey {
    inner: PublicKey,
}

impl VerifyingKey {
  // TODO add nonzeroscalar struct
  /*
  /Users/elena/Documents/hashcloak/clients/Fuel Labs/fuel-workspace/elliptic-curves/p384/src/ecdh.rs
  12,30: //! use p384::{EncodedPoint, PublicKey, ecdh::EphemeralSecret};
  24,22: //! let bob_public = PublicKey::from_sec1_bytes(bob_pk_bytes.as_ref())
  30,24: //! let alice_public = PublicKey::from_sec1_bytes(alice_pk_bytes.as_ref())
  */
  pub fn from_secret_scalar(scalar: Scalar) -> Self {
    let affinePoint: AffinePoint = (ProjectivePoint::generator().mul(scalar)).into();
    VerifyingKey { inner: PublicKey { point: affinePoint }}
  }
}