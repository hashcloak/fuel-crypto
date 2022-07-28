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

fn get_test_vectors() -> (Vec<u64>, Vec<u64>) {
    let mut zero_vec = Vec::new();
    zero_vec.push(0);
    zero_vec.push(0);
    zero_vec.push(0);
    zero_vec.push(0);
    zero_vec.push(0);
    zero_vec.push(0);

    let mut p_vec = Vec::new();
    p_vec.push(0xb9feffffffffaaab);
    p_vec.push(0x1eabfffeb153ffff);
    p_vec.push(0x6730d2a0f6b0f624);
    p_vec.push(0x64774b84f38512bf);
    p_vec.push(0x4b1ba7b6434bacd7);
    p_vec.push(0x1a0111ea397fe69a);

    (zero_vec, p_vec)
}

// TODO This can't run yet, because in the contract we can't use Vec
// #[tokio::test]
// async fn test_add_zero_to_zero_addn() {
//     let (_instance, _id) = get_contract_instance().await;
//     let mut zero_vec = Vec::new();
//     zero_vec.push(0);
//     zero_vec.push(0);
//     zero_vec.push(0);
//     zero_vec.push(0);
//     zero_vec.push(0);
//     zero_vec.push(0);
//     let(zero_vec1, p_vec) = get_test_vectors();

//     let mut expected_res = Vec::new();
//     expected_res.push(0);
//     expected_res.push(0);
//     expected_res.push(0);
//     expected_res.push(0);
//     expected_res.push(0);
//     expected_res.push(0);

//     let res = _instance.add_mod_n(zero_vec, zero_vec1, p_vec, 6)
//         .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
//         .call_params(CallParameters::new(None, None, Some(100_000_000)))
//         .call().await.unwrap().value;
//     assert!(res_equals(res, expected_res));
// }