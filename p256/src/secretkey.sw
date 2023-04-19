library;

use ::scalar::Scalar;
use ::utils::choice::Choice;

pub struct SecretKey {
    inner: Scalar,
}

impl SecretKey {
  pub fn from_scalar(s: Scalar) -> Self {
    assert(!s.ct_eq(Scalar::zero()).unwrap_as_bool());
    SecretKey { inner: s }
  }
}