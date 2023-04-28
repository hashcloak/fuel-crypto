library;

use ::scalar::Scalar;
use ::utils::choice::Choice;

pub struct SecretKey {
  // Ref: https://github.com/RustCrypto/traits/blob/a7a62e2de9b0f077958405246f553e3ce5c3c26f/elliptic-curve/src/secret_key.rs#L83
  inner: Scalar,
}

impl SecretKey {
  // return the secretkey based on the input scalar
  // Error: when scalar is zero
  pub fn from_scalar(s: Scalar) -> Self {
    // Ref: https://github.com/RustCrypto/traits/blob/a7a62e2de9b0f077958405246f553e3ce5c3c26f/elliptic-curve/src/secret_key.rs#L104
    assert(!s.ct_eq(Scalar::zero()).unwrap_as_bool());
    SecretKey { inner: s }
  }
}