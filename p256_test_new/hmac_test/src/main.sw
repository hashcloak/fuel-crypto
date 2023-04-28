contract;

use p256::{
  hmac::{hmac, generate_k},
  scalar::Scalar
};

abi MyContract {
    fn hmac(data: Vec<u8>, key: [u8;32]) -> [u8;32];
    fn generate_k(data: Vec<u8>, x: [u8;32]) -> Scalar;
}

impl MyContract for Contract {
    fn hmac(data: Vec<u8>, key: [u8;32]) -> [u8;32] {
      hmac(data, key)
    }

    fn generate_k(data: Vec<u8>, x: [u8;32]) -> Scalar {
      generate_k(data, x)
    }
}
