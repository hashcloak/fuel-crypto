use crate::utils::{helpers::get_contract_instance, Fp};
use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

mod success {
  use super::*;

  #[tokio::test] //works
  async fn test_add_fp() {
      let small = Fp{ 
          ls: [1, 2, 3, 4, 5, 6].to_vec()
      };
      let random = Fp{ 
          ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d].to_vec()
      };
      let expected_res = Fp{ 
          ls: [4478030004447473543, 2814704111667093004, 15884408734010272161, 17001047363111187582, 932823543034528552, 1051481384684610851].to_vec()
      };

      let (contract_instance, _id) = get_contract_instance().await;

      let res = contract_instance.add_fp(small, random)
      .tx_params(TxParameters::new(None, Some(100_000_000), None))
      .call_params(CallParameters::new(None, None, Some(100_000_000)))
      .call().await.unwrap().value;
      
      assert!(res == expected_res);
  }

  #[tokio::test] //works
  async fn test_sub_fp() {
      let a = Fp {
          ls: [10587454305359941416, 4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194].to_vec()
      };

      let b = Fp {
          ls: [13403040667047958534, 405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174].to_vec()
      };
      let expected_res = Fp { 
          ls: [15631157712021534498, 4210040059583301456, 2072967503069563536, 7744598167717445820, 16967452369712105079, 469452209245280019].to_vec()
      };
      let (_instance, _id) = get_contract_instance().await;

      let res = _instance.sub_fp(a, b)
          .tx_params(TxParameters::new(None, Some(100_000_000), None))
          .call_params(CallParameters::new(None, None, Some(100_000_000)))
          .call().await.unwrap().value;
      assert!(res == expected_res);
    }

  // WORKS, but takes very long
  #[tokio::test]
  async fn test_mul_fp() {
      let a = Fp{ ls:[
          0x0397_a383_2017_0cd4,
          0x734c_1b2c_9e76_1d30,
          0x5ed2_55ad_9a48_beb5,
          0x095a_3c6b_22a7_fcfc,
          0x2294_ce75_d4e2_6a27,
          0x1333_8bd8_7001_1ebb,
      ].to_vec()};
      let b = Fp{ ls:[
          0xb9c3_c7c5_b119_6af7,
          0x2580_e208_6ce3_35c1,
          0xf49a_ed3d_8a57_ef42,
          0x41f2_81e4_9846_e878,
          0xe076_2346_c384_52ce,
          0x0652_e893_26e5_7dc0,
      ].to_vec()};
      let c = Fp{ ls:[
          0xf96e_f3d7_11ab_5355,
          0xe8d4_59ea_00f1_48dd,
          0x53f7_354a_5f00_fa78,
          0x9e34_a4f3_125c_5f83,
          0x3fbe_0c47_ca74_c19e,
          0x01b0_6a8b_bd4a_dfe4,
      ].to_vec()};
      let (_instance, _id) = get_contract_instance().await;

      let res = _instance.mul_fp(a, b)
          .tx_params(TxParameters::new(None, Some(100_000_000), None))
          .call_params(CallParameters::new(None, None, Some(100_000_000)))
          .call().await.unwrap().value;
      assert!(res == c);
  }

  // WORKS, but takes very long
  /*
  #[tokio::test]
  async fn test_square_fp() {
      let a: Fp = Fp {
          ls: [0xd215_d276_8e83_191b,//15138237129114720539
          0x5085_d80f_8fb2_8261,//5802281256283701857
          0xce9a_032d_df39_3a56,//14887215013780077142
          0x3e9c_4fff_2ca0_c4bb,//4511568884102382779
          0x6436_b6f7_f4d9_5dfb,//7221160228616232443
          0x1060_6628_ad4a_4d90].to_vec()//1180055427263122832
      };

      let expected_res: Fp = Fp {
          ls: [0x33d9_c42a_3cb3_e235,
          0xdad1_1a09_4c4c_d455,
          0xa2f1_44bd_729a_aeba,
          0xd415_0932_be9f_feac,
          0xe27b_c7c4_7d44_ee50,
          0x14b6_a78d_3ec7_a560].to_vec()
      };

      let (_instance, _id) = get_contract_instance().await;

      let res = _instance.square_fp(a)
          .tx_params(TxParameters::new(None, Some(100_000_000), None))
          .call_params(CallParameters::new(None, None, Some(100_000_000)))
          .call().await.unwrap().value;

      assert!(res == expected_res);
  }
 */
  /*
  ERROR: Running this one will give Immediate18TooLarge
  #[tokio::test]
  async fn lexicographically_largest_fp() {
      let zero = Fp{ ls: [0,0,0,0,0,0].to_vec()};
      let one = Fp{ ls: [ //=R
          0x7609_0000_0002_fffd,
          0xebf4_000b_c40c_0002,
          0x5f48_9857_53c7_58ba,
          0x77ce_5853_7052_5745,
          0x5c07_1a97_a256_ec6d,
          0x15f6_5ec3_fa80_e493,
      ].to_vec()};
      let first = Fp{ ls: [
          0xa1fa_ffff_fffe_5557,
          0x995b_fff9_76a3_fffe,
          0x03f4_1d24_d174_ceb4,
          0xf654_7998_c199_5dbd,
          0x778a_468f_507a_6034,
          0x0205_5993_1f7f_8103
      ].to_vec()};
      let second = Fp{ ls: [
          0x1804_0000_0001_5554,
          0x8550_0005_3ab0_0001,
          0x633c_b57c_253c_276f,
          0x6e22_d1ec_31eb_b502,
          0xd391_6126_f2d1_4ca2,
          0x17fb_b857_1a00_6596,
      ].to_vec()};
      let third = Fp{ ls: [
          0x43f5_ffff_fffc_aaae,
          0x32b7_fff2_ed47_fffd,
          0x07e8_3a49_a2e9_9d69,
          0xeca8_f331_8332_bb7a,
          0xef14_8d1e_a0f4_c069,
          0x040a_b326_3eff_0206,
      ].to_vec()};

      let (contract_instance, _id) = get_contract_instance().await;

      let res_zero = contract_instance.lexicographically_largest_fp(zero)
          .tx_params(TxParameters::new(None, Some(10_000_000_000_000), None))
          .call_params(CallParameters::new(None, None, Some(10_000_000_000_000)))
          .call().await.unwrap().value;

      let res_one = contract_instance.lexicographically_largest_fp(one)
          .tx_params(TxParameters::new(None, Some(10_000_000_000_000), None))
          .call_params(CallParameters::new(None, None, Some(10_000_000_000_000)))
          .call().await.unwrap().value;

      let res_first = contract_instance.lexicographically_largest_fp(first)
          .tx_params(TxParameters::new(None, Some(10_000_000_000_000), None))
          .call_params(CallParameters::new(None, None, Some(10_000_000_000_000)))
          .call().await.unwrap().value;

      let res_second = contract_instance.lexicographically_largest_fp(second)
          .tx_params(TxParameters::new(None, Some(10_000_000_000_000), None))
          .call_params(CallParameters::new(None, None, Some(10_000_000_000_000)))
          .call().await.unwrap().value;

      let res_third = contract_instance.lexicographically_largest_fp(third)
          .tx_params(TxParameters::new(None, Some(10_000_000_000_000), None))
          .call_params(CallParameters::new(None, None, Some(10_000_000_000_000)))
          .call().await.unwrap().value;
      
      assert!(res_zero.c == 0);
      assert!(res_one.c == 0);
      assert!(res_first.c == 0);
      assert!(res_second.c == 1);
      assert!(res_third.c == 1);
  }
  */

}