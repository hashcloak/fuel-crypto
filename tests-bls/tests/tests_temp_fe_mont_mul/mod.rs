use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;

abigen!(BlsContract, "out/debug/tests-bls-abi.json");

async fn get_contract_instance() -> (BlsContract, ContractId) {
    let mut wallets = launch_provider_and_get_wallets(WalletsConfig::new_single(Some(1), Some(1_000_000))).await;
    let wallet = wallets.pop().unwrap();
    let id = Contract::deploy("./out/debug/tests-bls.bin", &wallet, TxParameters::default()).await.unwrap();
    let instance = BlsContract::new(id.to_string(), wallet);
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

// #[tokio::test]
// async fn temp_fe_mont_mul_random() {
//     let p_vec = [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a].to_vec();
//     let r1_vec = [17993655965713306301, 15604842006860479165, 10837926002905938402, 13429498400065700031, 1823694494885156540, 933350646299434799].to_vec();
//     let r2_vec = [5720430457560562798, 2568557665684583703, 15870134958983808442, 14065062413899436375, 12262047246709729804, 1303068506660090079].to_vec();
//     let expected_res = [8042921339150017446, 4899742317194411181, 11922910400151252689, 7736564210120511729, 10892349319971706476, 542573957820843489].to_vec()
//     let (_instance, _id) = get_contract_instance().await;

//     let res = _instance.temp_fe_mont_mul(r1_vec, r2_vec)
//         .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
//         .call_params(CallParameters::new(None, None, Some(100_000_000)))
//         .call().await.unwrap().value;
//     assert!(res_equals(res, expected_res));
// }