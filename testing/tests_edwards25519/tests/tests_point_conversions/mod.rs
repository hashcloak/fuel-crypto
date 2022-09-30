use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

abigen!(EdwardsTestContract, "out/debug/tests_edwards25519-abi.json");

async fn get_contract_instance() -> (EdwardsTestContractMethods, Bech32ContractId) {
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
    let consensus_parameters_config = ConsensusParameters::DEFAULT.with_max_gas_per_tx(1000000000);

    let (client, addr) = setup_test_client(coins, vec![], None, Some(consensus_parameters_config)).await;
    
    let provider = Provider::new(client);
    wallet.set_provider(provider.clone());

    let id = Contract::deploy(
        "./out/debug/tests_edwards25519.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::default(),
    ).await.unwrap();

    let instance = EdwardsTestContract::new(id.to_string(), wallet);
    (instance.methods(), id)
}

/*
source: https://crypto.stackexchange.com/questions/99798/test-vectors-points-for-ed25519
G: hex:     5866666666666666666666666666666666666666666666666666666666666666
G: x-coord: 15112221349535400772501151409588531511454012693041857206046113283949847762202
[1738742601995546, 1146398526822698, 2070867633025821, 562264141797630, 587772402128613]
G: y-coord: 46316835694926478169428394003475163141307993866256225615783033603165251855960
[1801439850948184, 1351079888211148, 450359962737049, 900719925474099, 1801439850948198]

2G: hex:     c9a3f86aae465f0e56513864510f3997561fa2c9e85ea21dc2292309f3cd6022
2G: x-coord: 24727413235106541002554574571675588834622768167397638456726423682521233608206
2G: y-coord: 15549675580280190176352668710449542251549572066445060580507079593062643049417

5G: hex:     edc876d6831fd2105d0b4389ca2e283166469289146e2ce06faefe98b22548df
5G: x-coord: 33467004535436536005251147249499675200073690106659565782908757308821616914995
5G: y-coord: 43097193783671926753355113395909008640284023746042808659097434958891230611693

aG: hex:     14e35209936de59710e4a3a55b1887a6f3a390c0b1b2d132a0158ff3b60581e0
aG: x-coord: 46953515626174660128743374276590207025464948126956050456964432034683890442435
aG: y-coord: 43649996176441760651255662656482711906128939437336752974722489909985414406932

bG: hex:     cca4cc575d5eb9057834ad8b759272d37feb95c9f7197bf251814f37a4413f1d
bG: x-coord: 48108495825706412711799803692360228025391948835486250305831184019146948949994
bG: y-coord: 13228837014764440841117560545823854143168584625415590819123131242008409842892

*/
/*
#[tokio::test]
async fn test_p1p1_to_p2() {
    let x = Element{ l_0: 1738742601995546, 
        l_1: 1146398526822698, 
        l_2: 2070867633025821, 
        l_3: 562264141797630, 
        l_4: 587772402128613 };
    let y = Element{ l_0: 1801439850948184, 
        l_1: 1351079888211148, 
        l_2: 450359962737049, 
        l_3: 900719925474099, 
        l_4: 1801439850948198 };
    let z = Element{ l_0: 1, l_1: 0, l_2: 0, l_3: 0, l_4: 0 };
    let test_point = ge25519_p2 { x:x, y:y, z:z };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.dbl_p1p1(test_point)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    print!("{}", res.x);
    print!("{}", res.y);
    print!("{}", res.z);
    print!("{}", res.t);
    // assert!(res.x == 24727413235106541002554574571675588834622768167397638456726423682521233608206);
    // assert!(res.y == 15549675580280190176352668710449542251549572066445060580507079593062643049417);

}
 */