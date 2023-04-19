library;

use ::verifyingkey::VerifyingKey;
use ::scalar::Scalar;
use ::secretkey::SecretKey;
use ::utils::choice::Choice;

pub struct SigningKey {
  secret_scalar: Scalar,
  verifying_key: VerifyingKey
}

impl SigningKey {
  pub fn from_bytes(bytes: [u8;32]) -> SigningKey {
    let secret_scalar = Scalar::from_bytes(bytes);
    assert(!secret_scalar.ct_eq(Scalar::zero()).unwrap_as_bool());
    let secret_key = SecretKey::from_scalar(secret_scalar);
    let verifying_key = VerifyingKey::from_secret_scalar(secret_scalar);
    SigningKey {
      secret_scalar: secret_scalar,
      verifying_key: verifying_key
    }
  }
}