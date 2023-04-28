library;

use ::verifyingkey::VerifyingKey;
use ::scalar::Scalar;
use ::secretkey::SecretKey;
use ::utils::choice::Choice;
use ::ecdsa::{Signature, try_sign_prehashed};
use ::hmac::{generate_k, into_byte_array, compose};
use std::bytes::Bytes;

// Secret key for signing, public key in verifying_key for verification of signature
pub struct SigningKey {
  // Ref: https://github.com/RustCrypto/signatures/blob/master/ecdsa/src/signing.rs#L66
  secret_scalar: Scalar,
  verifying_key: VerifyingKey
}

impl SigningKey {

  // returns signingkey (secret key) using the given bytes
  // Error: when bytes result in scalar equal to zero
  pub fn from_bytes(bytes: [u8;32]) -> SigningKey {
    // Ref: https://github.com/RustCrypto/signatures/blob/master/ecdsa/src/signing.rs#L92
    let secret_scalar = Scalar::from_bytes(bytes);
    assert(!secret_scalar.ct_eq(Scalar::zero()).unwrap_as_bool());
    let secret_key = SecretKey::from_scalar(secret_scalar);
    let verifying_key = VerifyingKey::from_secret_scalar(secret_scalar);
    SigningKey {
      secret_scalar: secret_scalar,
      verifying_key: verifying_key
    }
  }

  // returns signature using the signing key on the given message.
  pub fn try_sign(self, msg: Vec<u8>) -> Signature {
    // Ref: https://github.com/RustCrypto/signatures/blob/master/ecdsa/src/signing.rs#L171

    // Sign message using a deterministic ephemeral scalar (`k`)
    // computed using the algorithm described in [RFC6979 § 3.2].
    //
    // [RFC6979 § 3.2]: https://tools.ietf.org/html/rfc6979#section-3

    let mut d = self.secret_scalar;
    let mut d_256 = compose((d.ls[3], d.ls[2], d.ls[1], d.ls[0]));
    let mut d_bytes: [u8;32] = into_byte_array(d_256);

    let k = generate_k(msg, d_bytes);

    /*
    sha256 does not give correct result for certain inputs in Sway.
    It seems to be working correctly for Bytes, therefore we do a conversion to Bytes to be safe.
    This should be removed whenever possible!
    */
    let mut msg_bytes = Bytes::new();
    let mut i = 0;
    while i < msg.len() {
      msg_bytes.push(msg.get(i).unwrap());
      i = i + 1;
    }

    let digest = msg_bytes.sha256();
    let digest_bytes: [u8;32] = into_byte_array(digest);

    try_sign_prehashed(self.secret_scalar, k, digest_bytes)
  }

}