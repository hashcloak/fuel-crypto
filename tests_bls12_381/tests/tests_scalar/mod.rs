use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

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

fn scalar_equals(res: Scalar, should_be: Scalar) -> bool {
    assert!(res.ls[0] == should_be.ls[0]);
    assert!(res.ls[1] == should_be.ls[1]);
    assert!(res.ls[2] == should_be.ls[2]);
    assert!(res.ls[3] == should_be.ls[3]);
    true
}

#[tokio::test]
async fn test_addition() {
    let a: Scalar = Scalar{ ls: [
        0xffff_ffff_0000_0000,
        0x53bd_a402_fffe_5bfe,
        0x3339_d808_09a1_d805,
        0x73ed_a753_299d_7d48,
    ].to_vec()};

    let mut a_again = Scalar{ ls: [
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

    let res = contract_instance.add_scalar(a, a_again)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    
    assert!(scalar_equals(res, expected_res));
}
// fn test_addition() {
//     let mut tmp = LARGEST;
//     tmp += &LARGEST;

//     assert_eq!(
//         tmp,
//         Scalar([
//             0xffff_fffe_ffff_ffff,
//             0x53bd_a402_fffe_5bfe,
//             0x3339_d808_09a1_d805,
//             0x73ed_a753_299d_7d48,
//         ])
//     );

//     let mut tmp = LARGEST;
//     tmp += &Scalar([1, 0, 0, 0]);

//     assert_eq!(tmp, Scalar::zero());
// }