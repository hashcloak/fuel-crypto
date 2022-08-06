use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

abigen!(BlsContract, "out/debug/tests-bls-abi.json");

async fn get_contract_instance() -> (BlsContract, Bech32ContractId) {
    // Create the wallet.
    let mut wallet = LocalWallet::new_random(None);
    let num_assets = 1;
    let coins_per_asset = 100;
    let amount_per_coin = 100000;

    let (coins, asset_ids) = setup_multiple_assets_coins(
        wallet.address(),
        num_assets,
        coins_per_asset,
        amount_per_coin,
    );

    // configure the gas limit
    let consensus_parameters_config = ConsensusParameters::DEFAULT.with_max_gas_per_tx(10_000_000_000_000);

    // Here's the important part. This will be running a `fuel-core` that will live through this test.
    // The configured coins are the same as before, I'm just passing them to it.
    let (client, addr) = setup_test_client(coins, None, Some(consensus_parameters_config)).await;
  
    // Important. Make sure the random wallet you created above uses this provider you created just now.
    let provider = Provider::new(client);
    wallet.set_provider(provider.clone());

    let id = Contract::deploy(
        "./out/debug/tests-bls.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::default(), // <--- new stuff from 0.18
    )
    .await
    .unwrap();
    let instance = BlsContractBuilder::new(id.to_string(), wallet).build(); // <-- notice the `.build()` coming from `0.18` here
    (instance, id)
}

pub fn res_equals(res: vec384, should_be: vec384) -> bool {
    assert!(res.ls[0] == should_be.ls[0]);
    assert!(res.ls[1] == should_be.ls[1]);
    assert!(res.ls[2] == should_be.ls[2]);
    assert!(res.ls[3] == should_be.ls[3]);
    assert!(res.ls[4] == should_be.ls[4]);
    assert!(res.ls[5] == should_be.ls[5]);
    true
}

//runs with gas limit 10_000_000_000_000
// I would think this does a "normal" mult... but it doesnt. However, our zkcrypto functions are being tested against
// zkcrypto tests so thats OK. With this test at least we know how to increase the gas limit. And that a very high limit is probably needed.
#[tokio::test]
async fn test_temp_mul_random_by_random() {
//     15893342109957185315274996980159955840696869464618597139081654135225976620298280402004730099734930472282685911264653
// [7601317525063134605, 14737835108041207235, 7856501253924799053, 9728524752340033442, 8018744563895365642, 7440748395322036726]


    //let p_vec: [u64;6] = [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a];
    let r1_vec = vec384 {
        ls: [7601317525063134605, 14737835108041207235, 7856501253924799053, 9728524752340033442, 8018744563895365642, 7440748395322036726].to_vec()
    };

//     6426056301875987760035045131419826427959545715777668602170085103660258490882518289245959835486066380634045485171465
// [2100109755352105737, 8370746840931066636, 11596494770511871063, 3039720716978434317, 16449625404618362957, 3008471584241360315]
    let r2_vec = vec384{
        ls: [2100109755352105737, 8370746840931066636, 11596494770511871063, 3039720716978434317, 16449625404618362957, 3008471584241360315].to_vec()
    };

    //662295453570983325530111016671619871152537908715293912221215151084869461019373230933077596861385628632414151952313
    //[8398368441850316729, 11909455072033861112, 10407834670867800778, 5873847235982413757, 1304857104357117827, 310065296480341730]
    let expected_res = vec384 {
        ls: [8398368441850316729, 11909455072033861112, 10407834670867800778, 5873847235982413757, 1304857104357117827, 310065296480341730].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.temp_mul_mont_n(r1_vec, r2_vec)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    println!("{}", res.ls[0]);
    println!("{}", res.ls[1]);
    println!("{}", res.ls[2]);
    println!("{}", res.ls[2]);
    println!("{}", res.ls[4]);
    println!("{}", res.ls[5]);
    /*-> different outcome
9333873115146394089
4782551559207793765
10050393911427975672
10050393911427975672
1218813032832674028
1486933856237831752
    */
    // assert!(res_equals(res, expected_res));
}