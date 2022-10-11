use crate::utils::{helpers::get_contract_instance, Fp, Fp2};
use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

mod success {
  use super::*;

  #[tokio::test]
  async fn test_add_fp2() {

      let a = Fp2 {
          c_0: Fp{ls: [
              0xc9a2_1831_63ee_70d4,
              0xbc37_70a7_196b_5c91,
              0xa247_f8c1_304c_5f44,
              0xb01f_c2a3_726c_80b5,
              0xe1d2_93e5_bbd9_19c9,
              0x04b7_8e80_020e_f2ca,
          ].to_vec()},
          c_1: Fp{ls: [
              0x952e_a446_0462_618f,
              0x238d_5edd_f025_c62f,
              0xf6c9_4b01_2ea9_2e72,
              0x03ce_24ea_c1c9_3808,
              0x0559_50f9_45da_483c,
              0x010a_768d_0df4_eabc,
          ].to_vec()},
      };
      let b = Fp2 {
          c_0: Fp{ls: [
              0xa1e0_9175_a4d2_c1fe,
              0x8b33_acfc_204e_ff12,
              0xe244_15a1_1b45_6e42,
              0x61d9_96b1_b6ee_1936,
              0x1164_dbe8_667c_853c,
              0x0788_557a_cc7d_9c79,
          ].to_vec()},
          c_1: Fp{ls: [
              0xda6a_87cc_6f48_fa36,
              0x0fc7_b488_277c_1903,
              0x9445_ac4a_dc44_8187,
              0x0261_6d5b_c909_9209,
              0xdbed_4677_2db5_8d48,
              0x11b9_4d50_76c7_b7b1,
          ].to_vec()},
      };
      let c = Fp2 {
          c_0: Fp{ls: [
              0x6b82_a9a7_08c1_32d2,
              0x476b_1da3_39ba_5ba4,
              0x848c_0e62_4b91_cd87,
              0x11f9_5955_295a_99ec,
              0xf337_6fce_2255_9f06,
              0x0c3f_e3fa_ce8c_8f43,
          ].to_vec()},
          c_1: Fp{ls: [
              0x6f99_2c12_73ab_5bc5,
              0x3355_1366_17a1_df33,
              0x8b0e_f74c_0aed_aff9,
              0x062f_9246_8ad2_ca12,
              0xe146_9770_738f_d584,
              0x12c3_c3dd_84bc_a26d,
          ].to_vec()},
      };

      let (contract_instance, _id) = get_contract_instance().await;

      let res = contract_instance.add_fp2(a, b)
      .tx_params(TxParameters::new(None, Some(100_000_000), None))
      .call_params(CallParameters::new(None, None, Some(100_000_000)))
      .call().await.unwrap().value;
      
      assert!(res.c_0 == c.c_0);
      assert!(res.c_1 == c.c_1);
  }

  #[tokio::test]
  async fn test_sub_fp2() {

      let a = Fp2 {
          c_0: Fp{ ls: [
              0xc9a2_1831_63ee_70d4,
              0xbc37_70a7_196b_5c91,
              0xa247_f8c1_304c_5f44,
              0xb01f_c2a3_726c_80b5,
              0xe1d2_93e5_bbd9_19c9,
              0x04b7_8e80_020e_f2ca,
          ].to_vec()},
          c_1: Fp{ ls: [
              0x952e_a446_0462_618f,
              0x238d_5edd_f025_c62f,
              0xf6c9_4b01_2ea9_2e72,
              0x03ce_24ea_c1c9_3808,
              0x0559_50f9_45da_483c,
              0x010a_768d_0df4_eabc,
          ].to_vec()},
      };
      let b = Fp2 {
          c_0: Fp{ ls: [
              0xa1e0_9175_a4d2_c1fe,
              0x8b33_acfc_204e_ff12,
              0xe244_15a1_1b45_6e42,
              0x61d9_96b1_b6ee_1936,
              0x1164_dbe8_667c_853c,
              0x0788_557a_cc7d_9c79,
          ].to_vec()},
          c_1: Fp{ ls: [
              0xda6a_87cc_6f48_fa36,
              0x0fc7_b488_277c_1903,
              0x9445_ac4a_dc44_8187,
              0x0261_6d5b_c909_9209,
              0xdbed_4677_2db5_8d48,
              0x11b9_4d50_76c7_b7b1,
          ].to_vec()},
      };
      let c = Fp2 {
          c_0: Fp{ ls: [
              0xe1c0_86bb_bf1b_5981,
              0x4faf_c3a9_aa70_5d7e,
              0x2734_b5c1_0bb7_e726,
              0xb2bd_7776_af03_7a3e,
              0x1b89_5fb3_98a8_4164,
              0x1730_4aef_6f11_3cec,
          ].to_vec()},
          c_1: Fp{ ls: [
              0x74c3_1c79_9519_1204,
              0x3271_aa54_79fd_ad2b,
              0xc9b4_7157_4915_a30f,
              0x65e4_0313_ec44_b8be,
              0x7487_b238_5b70_67cb,
              0x0952_3b26_d0ad_19a4,
          ].to_vec()},
      };

      let (contract_instance, _id) = get_contract_instance().await;

      let res = contract_instance.sub_fp2(a, b)
      .tx_params(TxParameters::new(None, Some(100_000_000), None))
      .call_params(CallParameters::new(None, None, Some(100_000_000)))
      .call().await.unwrap().value;
      
      assert!(res.c_0 == c.c_0);
      assert!(res.c_1 == c.c_1);
  }

  #[tokio::test]
  async fn test_neg_fp2() {

      let a = Fp2 {
          c_0: Fp{ls: [
              0xc9a2_1831_63ee_70d4,
              0xbc37_70a7_196b_5c91,
              0xa247_f8c1_304c_5f44,
              0xb01f_c2a3_726c_80b5,
              0xe1d2_93e5_bbd9_19c9,
              0x04b7_8e80_020e_f2ca,
          ].to_vec()},
          c_1: Fp{ls: [
              0x952e_a446_0462_618f,
              0x238d_5edd_f025_c62f,
              0xf6c9_4b01_2ea9_2e72,
              0x03ce_24ea_c1c9_3808,
              0x0559_50f9_45da_483c,
              0x010a_768d_0df4_eabc,
          ].to_vec()},
      };
      let b = Fp2 {
          c_0: Fp{ls: [
              0xf05c_e7ce_9c11_39d7,
              0x6274_8f57_97e8_a36d,
              0xc4e8_d9df_c664_96df,
              0xb457_88e1_8118_9209,
              0x6949_13d0_8772_930d,
              0x1549_836a_3770_f3cf,
          ].to_vec()},
          c_1: Fp{ls: [
              0x24d0_5bb9_fb9d_491c,
              0xfb1e_a120_c12e_39d0,
              0x7067_879f_c807_c7b1,
              0x60a9_269a_31bb_dab6,
              0x45c2_56bc_fd71_649b,
              0x18f6_9b5d_2b8a_fbde,
          ].to_vec()},
      };


      let (contract_instance, _id) = get_contract_instance().await;

      let res = contract_instance.neg_fp2(a)
      .tx_params(TxParameters::new(None, Some(100_000_000), None))
      .call_params(CallParameters::new(None, None, Some(100_000_000)))
      .call().await.unwrap().value;
      
      assert!(res.c_0 == b.c_0);
      assert!(res.c_1 == b.c_1);
  }
  
  #[tokio::test] 
  async fn test_multiplication() {
      let a = Fp2 {
          c_0: Fp{ ls:[
              0xc9a2_1831_63ee_70d4,
              0xbc37_70a7_196b_5c91,
              0xa247_f8c1_304c_5f44,
              0xb01f_c2a3_726c_80b5,
              0xe1d2_93e5_bbd9_19c9,
              0x04b7_8e80_020e_f2ca,
          ].to_vec()},
          c_1: Fp{ ls:[
              0x952e_a446_0462_618f,
              0x238d_5edd_f025_c62f,
              0xf6c9_4b01_2ea9_2e72,
              0x03ce_24ea_c1c9_3808,
              0x0559_50f9_45da_483c,
              0x010a_768d_0df4_eabc,
          ].to_vec()},
      };
      let b = Fp2 {
          c_0: Fp{ ls:[
              0xa1e0_9175_a4d2_c1fe,
              0x8b33_acfc_204e_ff12,
              0xe244_15a1_1b45_6e42,
              0x61d9_96b1_b6ee_1936,
              0x1164_dbe8_667c_853c,
              0x0788_557a_cc7d_9c79,
          ].to_vec()},
          c_1: Fp{ ls:[
              0xda6a_87cc_6f48_fa36,
              0x0fc7_b488_277c_1903,
              0x9445_ac4a_dc44_8187,
              0x0261_6d5b_c909_9209,
              0xdbed_4677_2db5_8d48,
              0x11b9_4d50_76c7_b7b1,
          ].to_vec()},
      };
      let c = Fp2 {
          c_0: Fp{ ls:[
              0xf597_483e_27b4_e0f7,
              0x610f_badf_811d_ae5f,
              0x8432_af91_7714_327a,
              0x6a9a_9603_cf88_f09e,
              0xf05a_7bf8_bad0_eb01,
              0x0954_9131_c003_ffae,
          ].to_vec()},
          c_1: Fp{ ls:[
              0x963b_02d0_f93d_37cd,
              0xc95c_e1cd_b30a_73d4,
              0x3087_25fa_3126_f9b8,
              0x56da_3c16_7fab_0d50,
              0x6b50_86b5_f4b6_d6af,
              0x09c3_9f06_2f18_e9f2,
          ].to_vec()},
      };

      let (contract_instance, _id) = get_contract_instance().await;

      let res = contract_instance.mul_fp2(a, b)
          .tx_params(TxParameters::new(None, Some(100_000_000), None))
          .call_params(CallParameters::new(None, None, Some(100_000_000)))
          .call().await.unwrap().value;

      assert!(res == c);
  }

  /*
  //ERROR still gives Immediate18TooLarge :( (12 sept)
  #[tokio::test]
  async fn test_squaring() {
      let a = Fp2 {
          c_0: Fp{ ls:[
              0xc9a2_1831_63ee_70d4,
              0xbc37_70a7_196b_5c91,
              0xa247_f8c1_304c_5f44,
              0xb01f_c2a3_726c_80b5,
              0xe1d2_93e5_bbd9_19c9,
              0x04b7_8e80_020e_f2ca,
          ].to_vec()},
          c_1: Fp{ ls:[
              0x952e_a446_0462_618f,
              0x238d_5edd_f025_c62f,
              0xf6c9_4b01_2ea9_2e72,
              0x03ce_24ea_c1c9_3808,
              0x0559_50f9_45da_483c,
              0x010a_768d_0df4_eabc,
          ].to_vec()},
      };
      let b = Fp2 {
          c_0: Fp{ ls:[
              0xa1e0_9175_a4d2_c1fe,
              0x8b33_acfc_204e_ff12,
              0xe244_15a1_1b45_6e42,
              0x61d9_96b1_b6ee_1936,
              0x1164_dbe8_667c_853c,
              0x0788_557a_cc7d_9c79,
          ].to_vec()},
          c_1: Fp{ ls:[
              0xda6a_87cc_6f48_fa36,
              0x0fc7_b488_277c_1903,
              0x9445_ac4a_dc44_8187,
              0x0261_6d5b_c909_9209,
              0xdbed_4677_2db5_8d48,
              0x11b9_4d50_76c7_b7b1,
          ].to_vec()},
      };
      let (contract_instance, _id) = get_contract_instance().await;

      let res = contract_instance.square_fp2(a)
          .tx_params(TxParameters::new(None, Some(100_000_000), None))
          .call_params(CallParameters::new(None, None, Some(100_000_000)))
          .call().await.unwrap().value;

      println!("{}", res.c_0.ls[0]);
      println!("{}", res.c_0.ls[1]);
      println!("{}", res.c_0.ls[2]);
      println!("{}", res.c_0.ls[2]);
      println!("{}", res.c_0.ls[4]);
      println!("{}", res.c_0.ls[5]);

      println!("{}", res.c_1.ls[0]);
      println!("{}", res.c_1.ls[1]);
      println!("{}", res.c_1.ls[2]);
      println!("{}", res.c_1.ls[2]);
      println!("{}", res.c_1.ls[4]);
      println!("{}", res.c_1.ls[5]);

      assert!(res.c_0 == b.c_0);
      assert!(res.c_1 == b.c_1);
  }
  */
  /*
  //ERROR Immediate18TooLarge
  #[tokio::test]//stripped down version from zkcrypto impl
  async fn lexicographically_largest_fp2() {
      let zero = Fp2 { 
          c_0 : Fp{ ls: [0,0,0,0,0,0].to_vec()},
          c_1 : Fp{ ls: [0,0,0,0,0,0].to_vec()},
      };
      let one = Fp2 {
          c_0: Fp{ ls: [ //=R
              0x7609_0000_0002_fffd,
              0xebf4_000b_c40c_0002,
              0x5f48_9857_53c7_58ba,
              0x77ce_5853_7052_5745,
              0x5c07_1a97_a256_ec6d,
              0x15f6_5ec3_fa80_e493,
          ].to_vec()},
          c_1 : Fp{ ls: [0,0,0,0,0,0].to_vec()}
      };

      let first = Fp2 {
          c_0: Fp{ ls: [
              0x1128_ecad_6754_9455,
              0x9e7a_1cff_3a4e_a1a8,
              0xeb20_8d51_e08b_cf27,
              0xe98a_d408_11f5_fc2b,
              0x736c_3a59_232d_511d,
              0x10ac_d42d_29cf_cbb6,
          ].to_vec()},
          c_1 : Fp{ ls: [
              0xd328_e37c_c2f5_8d41,
              0x948d_f085_8a60_5869,
              0x6032_f9d5_6f93_a573,
              0x2be4_83ef_3fff_dc87,
              0x30ef_61f8_8f48_3c2a,
              0x1333_f55a_3572_5be0].to_vec()}
      };
      let (contract_instance, _id) = get_contract_instance().await;

      let res_zero = contract_instance.lexicographically_largest_fp2(zero)
          .tx_params(TxParameters::new(None, Some(10_000_000_000_000), None))
          .call_params(CallParameters::new(None, None, Some(10_000_000_000_000)))
          .call().await.unwrap().value;

      let res_one = contract_instance.lexicographically_largest_fp2(one)
          .tx_params(TxParameters::new(None, Some(10_000_000_000_000), None))
          .call_params(CallParameters::new(None, None, Some(10_000_000_000_000)))
          .call().await.unwrap().value;

      let res_first = contract_instance.lexicographically_largest_fp2(first)
          .tx_params(TxParameters::new(None, Some(10_000_000_000_000), None))
          .call_params(CallParameters::new(None, None, Some(10_000_000_000_000)))
          .call().await.unwrap().value;

      assert!(res_zero.c == 0);
      assert!(res_one.c == 0);
      assert!(res_first.c == 1);
  }
  */
}