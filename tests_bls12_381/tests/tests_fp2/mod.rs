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


//Errors: thread 'main' panicked at 'called `Result::unwrap()` on an `Err` value: Immediate18TooLarge { val: 262256, span: Span { src (ptr): 0x600012cb7b50, path: None, start: 0, end: 0, as_str(): "" } }'
// #[tokio::test]
// fn test_multiplication() {
//     let a = Fp2 {
//         c0: fp_from_raw_unchecked([
//             0xc9a2_1831_63ee_70d4,
//             0xbc37_70a7_196b_5c91,
//             0xa247_f8c1_304c_5f44,
//             0xb01f_c2a3_726c_80b5,
//             0xe1d2_93e5_bbd9_19c9,
//             0x04b7_8e80_020e_f2ca,
//         ]),
//         c1: fp_from_raw_unchecked([
//             0x952e_a446_0462_618f,
//             0x238d_5edd_f025_c62f,
//             0xf6c9_4b01_2ea9_2e72,
//             0x03ce_24ea_c1c9_3808,
//             0x0559_50f9_45da_483c,
//             0x010a_768d_0df4_eabc,
//         ]),
//     };
//     let b = Fp2 {
//         c0: fp_from_raw_unchecked([
//             0xa1e0_9175_a4d2_c1fe,
//             0x8b33_acfc_204e_ff12,
//             0xe244_15a1_1b45_6e42,
//             0x61d9_96b1_b6ee_1936,
//             0x1164_dbe8_667c_853c,
//             0x0788_557a_cc7d_9c79,
//         ]),
//         c1: fp_from_raw_unchecked([
//             0xda6a_87cc_6f48_fa36,
//             0x0fc7_b488_277c_1903,
//             0x9445_ac4a_dc44_8187,
//             0x0261_6d5b_c909_9209,
//             0xdbed_4677_2db5_8d48,
//             0x11b9_4d50_76c7_b7b1,
//         ]),
//     };
//     let c = Fp2 {
//         c0: fp_from_raw_unchecked([
//             0xf597_483e_27b4_e0f7,
//             0x610f_badf_811d_ae5f,
//             0x8432_af91_7714_327a,
//             0x6a9a_9603_cf88_f09e,
//             0xf05a_7bf8_bad0_eb01,
//             0x0954_9131_c003_ffae,
//         ]),
//         c1: fp_from_raw_unchecked([
//             0x963b_02d0_f93d_37cd,
//             0xc95c_e1cd_b30a_73d4,
//             0x3087_25fa_3126_f9b8,
//             0x56da_3c16_7fab_0d50,
//             0x6b50_86b5_f4b6_d6af,
//             0x09c3_9f06_2f18_e9f2,
//         ]),
//     };

//     assert_eq!(mul_fp2(a, b), c);
// }