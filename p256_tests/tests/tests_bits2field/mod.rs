use fuels::prelude::*;
use crate::utils::{
  helpers::get_contract_methods
};

mod success {
  use super::*;

  #[tokio::test]
  async fn test_bits2field() {
    let (_methods, _id) = get_contract_methods().await;

    let bits: Vec<u8> = vec! [170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170];
    let bytes = _methods
      .bits2field(bits)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert_eq!(bytes.value, [170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);


    let bits2: Vec<u8> = vec![170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170];
    let bytes2 = _methods
      .bits2field(bits2)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert_eq!(bytes2.value, [170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170]);

    let bits3: Vec<u8> = vec![170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 187, 187, 187, 187, 187, 187, 187, 187, 187, 187, 187, 187, 187, 187, 187, 187];
    let bytes3 = _methods
      .bits2field(bits3)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert_eq!(bytes3.value, [170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170]);
  }

}