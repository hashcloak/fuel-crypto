use fuels::prelude::*;
use crate::utils::{
  FieldElement, 
  Scalar,
  AffinePoint,
  Signature,
  helpers::{get_contract_methods, assert_xy, convert_from_montgomery}
};

mod success {
  use super::*;

  #[tokio::test]
  async fn test_verify_prehashed() {
    // test vectors taken from https://datatracker.ietf.org/doc/html/rfc6979#appendix-A.2.5

    let (_methods, _id) = get_contract_methods().await;

    // With SHA-256, message = "sample":
    // sha256 of "sample" af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf
    let hash1 = [175, 43, 219, 225, 170, 155, 110, 193, 226, 173, 225, 214, 148, 244, 31, 199, 26, 131, 29, 2, 104, 233, 137, 21, 98, 17, 61, 138, 98, 173, 209, 191];
    let r1 = Scalar{ls:[14072920526640068374, 11325576126734727569, 1243237162801856982, 17281590685529975037]};
    let s1 = Scalar{ls:[5603792056925998504, 17575579964503225350, 15291629082155065189, 17855396570382826561]};

    // With SHA-256, message = "test":
    // sha256 of "test" 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
    let hash2 = [159, 134, 208, 129, 136, 76, 125, 101, 154, 47, 234, 160, 197, 90, 208, 21, 163, 191, 79, 27, 43, 11, 130, 44, 209, 93, 108, 21, 176, 240, 10, 8];
    let r2 = Scalar{ls: [5704041684016530279, 17095379372343503669, 8203448929688135267, 17414206049896059341]};
    let s2 = Scalar{ls: [921059038994563203, 6856306437048585036, 13629460836803561749, 116883667144026900]};
    
    // pubkey
    let a = AffinePoint {
      x: FieldElement { ls:[16602909452612575158, 13855808666783054444, 14511138361138572648, 6989257567681289521] },
      y: FieldElement { ls:[8620948056189575833, 17505968991938453329, 11825020959996820580, 8720092648338668697] },
      infinity: 0
    };
    let sign1 = Signature{r: r1, s: s1};
    // verification for signature on "sample"
    let verify1 = _methods
      .verify_prehashed(a.clone(), hash1.clone(), sign1)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert!(verify1.value);

    let sign2 = Signature{r: r2.clone(), s: s2.clone()};
    // verification for signature on "test"
    let verify2 = _methods
      .verify_prehashed(a.clone(), hash2, sign2.clone())
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert!(verify2.value);

    // Check for a failing verification
    let verify_failed = _methods
      .verify_prehashed(a.clone(), hash1.clone(), sign2.clone()) // hash1, with signature for hash2 should fail
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert!(!verify_failed.value);
  }


  #[tokio::test]
  async fn test_generate_verifyingkey() {
    // test vectors taken from https://datatracker.ietf.org/doc/html/rfc6979#appendix-A.2.5

    let (_methods, _id) = get_contract_methods().await;

    // private scalar C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721
    let x = Scalar { ls: [8902035550577321761, 5643225679381699346, 7736094919201248915, 14533021268895757590]};

    // verification for signature on "sample"
    let get_verifying_key = _methods
      .from_secret_scalar(x)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    // convert the coordinates to compare them with the value from the doc
    let converted_coordinates = convert_from_montgomery(&_methods, &get_verifying_key.value.inner.point).await;

    // should be equal to the pubkey given in the doc
    assert_xy(converted_coordinates.0, converted_coordinates.1, [16602909452612575158, 13855808666783054444, 14511138361138572648, 6989257567681289521], [8620948056189575833, 17505968991938453329, 11825020959996820580, 8720092648338668697]);
  }

  #[tokio::test]#[ignore]//WORKS, takes 21 min to run
  async fn test_verify_with_generated_verifyingkey() {
    // test vectors taken from https://datatracker.ietf.org/doc/html/rfc6979#appendix-A.2.5

    let (_methods, _id) = get_contract_methods().await;

    // private scalar C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721
    let x = Scalar { ls: [8902035550577321761, 5643225679381699346, 7736094919201248915, 14533021268895757590]};

    // verification for signature on "sample"
    let verifying_key = _methods
      .from_secret_scalar(x)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    // With SHA-256, message = "sample":
    // sha256 of "sample" af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf
    let hash1 = [175, 43, 219, 225, 170, 155, 110, 193, 226, 173, 225, 214, 148, 244, 31, 199, 26, 131, 29, 2, 104, 233, 137, 21, 98, 17, 61, 138, 98, 173, 209, 191];
    let r1 = Scalar{ls:[14072920526640068374, 11325576126734727569, 1243237162801856982, 17281590685529975037]};
    let s1 = Scalar{ls:[5603792056925998504, 17575579964503225350, 15291629082155065189, 17855396570382826561]};
    let signature1 = Signature { r: r1, s: s1}; 

    // With SHA-256, message = "test":
    // signature of that hashed message
    let r2 = Scalar{ls: [5704041684016530279, 17095379372343503669, 8203448929688135267, 17414206049896059341]};
    let s2 = Scalar{ls: [921059038994563203, 6856306437048585036, 13629460836803561749, 116883667144026900]};
    let signature2 = Signature { r: r2, s: s2}; 

    // verification for signature on "sample"
    let verify1 = _methods
      .verify_prehash(verifying_key.value.clone(), hash1.clone(), signature1)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert!(verify1.value);

    // Check for a failing verification
    let verify_failed = _methods
      .verify_prehash(verifying_key.value.clone(), hash1.clone(), signature2)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert!(!verify_failed.value);
  }
}