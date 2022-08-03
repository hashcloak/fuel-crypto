use fuels::{prelude::*, tx::ContractId};

// Load abi from json
abigen!(BlsTestContract, "out/debug/tests_bls12_381-abi.json");

async fn get_contract_instance() -> (BlsTestContract, ContractId) {
    // Launch a local network and deploy the contract
    let wallet = launch_provider_and_get_wallet().await;

    let id = Contract::deploy(
        "./out/debug/tests_bls12_381.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(None)
    )
    .await
    .unwrap();

    let instance = BlsTestContract::new(id.to_string(), wallet);

    (instance, id)
}


pub fn res_equals(res: Fp2, should_be: Fp2) -> bool {

    let c0_res = res.c_0;
    let c1_res = res.c_1;
    let c0_should_be = should_be.c_0;
    let c1_should_be = should_be.c_1;

    assert!(c0_res.ls[0] == c0_should_be.ls[0]);
    assert!(c0_res.ls[1] == c0_should_be.ls[1]);
    assert!(c0_res.ls[2] == c0_should_be.ls[2]);
    assert!(c0_res.ls[3] == c0_should_be.ls[3]);
    assert!(c0_res.ls[4] == c0_should_be.ls[4]);
    assert!(c0_res.ls[5] == c0_should_be.ls[5]);

    assert!(c1_res.ls[0] == c1_should_be.ls[0]);
    assert!(c1_res.ls[1] == c1_should_be.ls[1]);
    assert!(c1_res.ls[2] == c1_should_be.ls[2]);
    assert!(c1_res.ls[3] == c1_should_be.ls[3]);
    assert!(c1_res.ls[4] == c1_should_be.ls[4]);
    assert!(c1_res.ls[5] == c1_should_be.ls[5]);
    true
}

fn get_a() -> Fp6  {
    let a = Fp6 {
        c_0: Fp2 {
            c_0: Fp{ls: [
                0x47f9_cb98_b1b8_2d58,
                0x5fe9_11eb_a3aa_1d9d,
                0x96bf_1b5f_4dd8_1db3,
                0x8100_d27c_c925_9f5b,
                0xafa2_0b96_7464_0eab,
                0x09bb_cea7_d8d9_497d,
            ].to_vec()},
            c_1: Fp{ls: [
                0x0303_cb98_b166_2daa,
                0xd931_10aa_0a62_1d5a,
                0xbfa9_820c_5be4_a468,
                0x0ba3_643e_cb05_a348,
                0xdc35_34bb_1f1c_25a6,
                0x06c3_05bb_19c0_e1c1,
            ].to_vec()},
        },
        c_1: Fp2 {
            c_0: Fp{ls: [
                0x46f9_cb98_b162_d858,
                0x0be9_109c_f7aa_1d57,
                0xc791_bc55_fece_41d2,
                0xf84c_5770_4e38_5ec2,
                0xcb49_c1d9_c010_e60f,
                0x0acd_b8e1_58bf_e3c8,
            ].to_vec()},
            c_1: Fp{ls: [
                0x8aef_cb98_b15f_8306,
                0x3ea1_108f_e4f2_1d54,
                0xcf79_f69f_a1b7_df3b,
                0xe4f5_4aa1_d16b_1a3c,
                0xba5e_4ef8_6105_a679,
                0x0ed8_6c07_97be_e5cf,
            ].to_vec()},
        },
        c_2: Fp2 {
            c_0: Fp{ls: [
                0xcee5_cb98_b15c_2db4,
                0x7159_1082_d23a_1d51,
                0xd762_30e9_44a1_7ca4,
                0xd19e_3dd3_549d_d5b6,
                0xa972_dc17_01fa_66e3,
                0x12e3_1f2d_d6bd_e7d6,
            ].to_vec()},
            c_1: Fp{ls: [
                0xad2a_cb98_b173_2d9d,
                0x2cfd_10dd_0696_1d64,
                0x0739_6b86_c6ef_24e8,
                0xbd76_e2fd_b1bf_c820,
                0x6afe_a7f6_de94_d0d5,
                0x1099_4b0c_5744_c040,
            ].to_vec()},
        },
    };

    a
}

fn get_b() -> Fp6 {
    let b = Fp6 {
        c_0: Fp2 {
            c_0: Fp{ ls: [
                0xf120_cb98_b16f_d84b,
                0x5fb5_10cf_f3de_1d61,
                0x0f21_a5d0_69d8_c251,
                0xaa1f_d62f_34f2_839a,
                0x5a13_3515_7f89_913f,
                0x14a3_fe32_9643_c247,
            ].to_vec()},
            c_1: Fp{ ls: [
                0x3516_cb98_b16c_82f9,
                0x926d_10c2_e126_1d5f,
                0x1709_e01a_0cc2_5fba,
                0x96c8_c960_b825_3f14,
                0x4927_c234_207e_51a9,
                0x18ae_b158_d542_c44e,
            ].to_vec()},
        },
        c_1: Fp2 {
            c_0: Fp{ ls: [
                0xbf0d_cb98_b169_82fc,
                0xa679_10b7_1d1a_1d5c,
                0xb7c1_47c2_b8fb_06ff,
                0x1efa_710d_47d2_e7ce,
                0xed20_a79c_7e27_653c,
                0x02b8_5294_dac1_dfba,
            ].to_vec()},
            c_1: Fp{ ls: [
                0x9d52_cb98_b180_82e5,
                0x621d_1111_5176_1d6f,
                0xe798_8260_3b48_af43,
                0x0ad3_1637_a4f4_da37,
                0xaeac_737c_5ac1_cf2e,
                0x006e_7e73_5b48_b824,
            ].to_vec()},
        },
        c_2: Fp2 {
            c_0: Fp{ ls: [
                0xe148_cb98_b17d_2d93,
                0x94d5_1104_3ebe_1d6c,
                0xef80_bca9_de32_4cac,
                0xf77c_0969_2827_95b1,
                0x9dc1_009a_fbb6_8f97,
                0x0479_3199_9a47_ba2b,
            ].to_vec()},
            c_1: Fp{ ls: [
                0x253e_cb98_b179_d841,
                0xc78d_10f7_2c06_1d6a,
                0xf768_f6f3_811b_ea15,
                0xe424_fc9a_ab5a_512b,
                0x8cd5_8db9_9cab_5001,
                0x0883_e4bf_d946_bc32,
            ].to_vec()},
        },
    };

    b
}
