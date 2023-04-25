library;

use ::verifyingkey::VerifyingKey;
use ::scalar::Scalar;
use ::secretkey::SecretKey;
use ::utils::choice::Choice;
use ::ecdsa::{Signature, try_sign_prehashed};
use ::hmac::{generate_k, vec_to_array, into_bytes, compose};
use std::bytes::Bytes;


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

  // https://github.com/RustCrypto/signatures/blob/master/ecdsa/src/signing.rs#L171

  // Sign message using a deterministic ephemeral scalar (`k`)
  // computed using the algorithm described in [RFC6979 § 3.2].
  //
  // [RFC6979 § 3.2]: https://tools.ietf.org/html/rfc6979#section-3

  pub fn try_sign(self, msg: Vec<u8>) -> Signature {
    let mut d = self.secret_scalar;
    let mut d_256 = compose((d.ls[3], d.ls[2], d.ls[1], d.ls[0]));
    let mut d_bytes = vec_to_array(into_bytes(d_256).into_vec_u8());

    let k = generate_k(msg, d_bytes);

    // This step is needed because sha256 is giving correct result only using with Bytes
    // TODO: if msg length is large, this will take time. 
    // Either we need to change the input format for msg into Bytes instead of Vec<u8> or sha256 should give desired result on Vec<u8>

    let mut msg_bytes = Bytes::new();
    let mut i = 0;
    while i < msg.len() {
      msg_bytes.push(msg.get(i).unwrap());
      i = i + 1;
    }

    let digest = msg_bytes.sha256();
    let digest_bytes = vec_to_array(into_bytes(digest).into_vec_u8());

    try_sign_prehashed(self.secret_scalar, k, digest_bytes)
  }

}