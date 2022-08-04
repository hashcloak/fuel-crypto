use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

// Load abi from json
abigen!(BlsTestContract, "out/debug/tests_bls12_381-abi.json");

async fn get_contract_instance() -> (BlsTestContract, Bech32ContractId) {
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

    let instance = BlsTestContractBuilder::new(id.to_string(), wallet).build();

    (instance, id)
}


pub fn res_equals(res: Fp, should_be: Fp) -> bool {
    assert!(res.ls[0] == should_be.ls[0]);
    assert!(res.ls[1] == should_be.ls[1]);
    assert!(res.ls[2] == should_be.ls[2]);
    assert!(res.ls[3] == should_be.ls[3]);
    assert!(res.ls[4] == should_be.ls[4]);
    assert!(res.ls[5] == should_be.ls[5]);
    true
}

#[tokio::test]
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
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
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
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

// // WORKS, but smart to comment out when wanting to test other things
// #[tokio::test]
// async fn test_mul_fp() {
//     let a = Fp{ ls:[
//         0x0397_a383_2017_0cd4,
//         0x734c_1b2c_9e76_1d30,
//         0x5ed2_55ad_9a48_beb5,
//         0x095a_3c6b_22a7_fcfc,
//         0x2294_ce75_d4e2_6a27,
//         0x1333_8bd8_7001_1ebb,
//     ].to_vec()};
//     let b = Fp{ ls:[
//         0xb9c3_c7c5_b119_6af7,
//         0x2580_e208_6ce3_35c1,
//         0xf49a_ed3d_8a57_ef42,
//         0x41f2_81e4_9846_e878,
//         0xe076_2346_c384_52ce,
//         0x0652_e893_26e5_7dc0,
//     ].to_vec()};
//     let c = Fp{ ls:[
//         0xf96e_f3d7_11ab_5355,
//         0xe8d4_59ea_00f1_48dd,
//         0x53f7_354a_5f00_fa78,
//         0x9e34_a4f3_125c_5f83,
//         0x3fbe_0c47_ca74_c19e,
//         0x01b0_6a8b_bd4a_dfe4,
//     ].to_vec()};
//     let (_instance, _id) = get_contract_instance().await;

//     let res = _instance.mul_fp(a, b)
//         .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
//         .call_params(CallParameters::new(None, None, Some(100_000_000)))
//         .call().await.unwrap().value;
//     assert!(res_equals(res, c));
// }

// // WORKS, but smart to comment out when wanting to test other things
// #[tokio::test]
// async fn test_square_fp() {
//     let a: Fp = Fp {
//         ls: [0xd215_d276_8e83_191b,//15138237129114720539
//         0x5085_d80f_8fb2_8261,//5802281256283701857
//         0xce9a_032d_df39_3a56,//14887215013780077142
//         0x3e9c_4fff_2ca0_c4bb,//4511568884102382779
//         0x6436_b6f7_f4d9_5dfb,//7221160228616232443
//         0x1060_6628_ad4a_4d90].to_vec()//1180055427263122832
//     };

//     // let a_again: Fp = Fp {
//     //     ls: [0xd215_d276_8e83_191b,
//     //     0x5085_d80f_8fb2_8261,//5802281256283701857
//     //     0xce9a_032d_df39_3a56,//14887215013780077142
//     //     0x3e9c_4fff_2ca0_c4bb,//4511568884102382779
//     //     0x6436_b6f7_f4d9_5dfb,//7221160228616232443
//     //     0x1060_6628_ad4a_4d90].to_vec()//1180055427263122832
//     // };

//     let expected_res: Fp = Fp {
//         ls: [0x33d9_c42a_3cb3_e235,
//         0xdad1_1a09_4c4c_d455,
//         0xa2f1_44bd_729a_aeba,
//         0xd415_0932_be9f_feac,
//         0xe27b_c7c4_7d44_ee50,
//         0x14b6_a78d_3ec7_a560].to_vec()
//     };

//     let (_instance, _id) = get_contract_instance().await;

//     let res = _instance.square_fp(a)
//         .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
//         .call_params(CallParameters::new(None, None, Some(100_000_000)))
//         .call().await.unwrap().value;
//     //fails :( 
//     assert!(res_equals(res, expected_res));
// }
