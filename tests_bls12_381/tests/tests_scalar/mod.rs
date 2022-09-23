use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

abigen!(BlsTestContract, "out/debug/tests_bls12_381-abi.json");

async fn get_contract_instance() -> (BlsTestContract, Bech32ContractId) {
    let mut wallet = WalletUnlocked::new_random(None);
    let num_assets = 1;
    let coins_per_asset = 100;
    let amount_per_coin = 100000;

    let (coins, asset_ids) = setup_multiple_assets_coins(
        wallet.address(),
        num_assets,
        coins_per_asset,
        amount_per_coin,
    );

    // Custom gas limit
    let consensus_parameters_config = ConsensusParameters::DEFAULT.with_max_gas_per_tx(10_000_000_000_000);

    let (client, addr) = setup_test_client(coins, None, Some(consensus_parameters_config)).await;
    
    let provider = Provider::new(client);
    wallet.set_provider(provider.clone());

    let id = Contract::deploy(
        "./out/debug/tests_bls12_381.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::default(),
    ).await.unwrap();

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
    
    assert!(scalar_equals(res, expected_res));

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
    
    assert!(scalar_equals(res_2, Scalar{ ls: [0,0,0,0].to_vec() }));

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
//         .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
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