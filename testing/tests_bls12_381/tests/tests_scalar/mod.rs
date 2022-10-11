use crate::utils::{helpers::get_contract_instance, Scalar};
use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

mod success {
  use super::*;

  #[tokio::test]
  async fn test_addition() {
      let a: Scalar = Scalar{ ls: [
          0xffff_ffff_0000_0000,
          0x53bd_a402_fffe_5bfe,
          0x3339_d808_09a1_d805,
          0x73ed_a753_299d_7d48,
      ].to_vec()};

      let a_2 = Scalar{ ls: [
          0xffff_ffff_0000_0000,
          0x53bd_a402_fffe_5bfe,
          0x3339_d808_09a1_d805,
          0x73ed_a753_299d_7d48,
      ].to_vec()};

      let expected_res = Scalar{ ls:[
              0xffff_fffe_ffff_ffff,
              0x53bd_a402_fffe_5bfe,
              0x3339_d808_09a1_d805,
              0x73ed_a753_299d_7d48,
          ].to_vec()};

      let (contract_instance, _id) = get_contract_instance().await;

      let res = contract_instance.add_scalar(a, a_2)
      .tx_params(TxParameters::new(None, Some(100_000_000), None))
      .call_params(CallParameters::new(None, None, Some(100_000_000)))
      .call().await.unwrap().value;
      
      assert!(res == expected_res);

      let a_3 = Scalar{ ls: [
          0xffff_ffff_0000_0000,
          0x53bd_a402_fffe_5bfe,
          0x3339_d808_09a1_d805,
          0x73ed_a753_299d_7d48,
      ].to_vec()};

      let one = Scalar{ ls: [1,0,0,0].to_vec() };
      let res_2 = contract_instance.add_scalar(a_3, one)
      .tx_params(TxParameters::new(None, Some(100_000_000), None))
      .call_params(CallParameters::new(None, None, Some(100_000_000)))
      .call().await.unwrap().value;
      
      assert!(res_2 == Scalar{ ls: [0,0,0,0].to_vec() });
  }

  /*BLOCKED
  error: Internal compiler error: Verification failed: Function anon_11103 return type must match its RET instructions.
  Please file an issue on the repository and include the code that triggered this error.
  */
  // #[tokio::test]
  // async fn test_sqrt() {
  //     let zero = Scalar{ ls: [0,0,0,0].to_vec() };
  //     let (contract_instance, _id) = get_contract_instance().await;
  //     let square_root = contract_instance.scalar_sqrt(zero)
  //         .tx_params(TxParameters::new(None, Some(100_000_000), None))
  //         .call_params(CallParameters::new(None, None, Some(100_000_000)))
  //         .call().await.unwrap().value;
  //     assert_eq!(square_root, Scalar{ ls: [0,0,0,0].to_vec() });
  // }


  /*BLOCKED
  error: Internal compiler error: Verification failed: Function anon_11103 return type must match its RET instructions.
  Please file an issue on the repository and include the code that triggered this error.
  */
  // #[tokio::test]
  // async fn test_sqrt() {
  //     let mut square = Scalar{ ls:[
  //         0x46cd_85a5_f273_077e,
  //         0x1d30_c47d_d68f_c735,
  //         0x77f6_56f6_0bec_a0eb,
  //         0x494a_a01b_df32_468d,
  //     ].to_vec()};

  //     let mut none_count = 0;
  //     let (contract_instance, _id) = get_contract_instance().await;


  //     let j = 0;
  //     while j < 101 {
  //         let square_root = contract_instance.scalar_sqrt(square)
  //             .tx_params(TxParameters::new(None, Some(100_000_000), None))
  //             .call_params(CallParameters::new(None, None, Some(100_000_000)))
  //             .call().await.unwrap().value;
  //         // let square_root = square.sqrt();
  //         if square_root.is_none() {
  //             none_count += 1;
  //         } else {
  //             assert_eq!(square_root.unwrap() * square_root.unwrap(), square);
  //         }
  //         square -= Scalar::one();
  //         j += 1;
  //     }

  //     assert_eq!(49, none_count);
  // }
}