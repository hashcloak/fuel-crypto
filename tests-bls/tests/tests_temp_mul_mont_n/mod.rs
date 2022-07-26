use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;

abigen!(BlsContract, "out/debug/tests-bls-abi.json");

async fn get_contract_instance() -> (BlsContract, ContractId) {
    let mut wallets = launch_provider_and_get_wallets(WalletsConfig::new_single(Some(1), Some(100_000_000))).await;
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

#[tokio::test]
async fn test_temp_mul_random_by_random() {
    //let p_vec: [u64;6] = [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a];
    let r1_vec = vec384 {
        ls: [6071868568151433008, 12105094901188801210, 2389211775905699303, 7838417195104481535, 5826366508043997497, 13436617433956842131].to_vec()
    };
    let r2_vec = vec384{
        ls: [16964885827015180015, 12035734743809705289, 10517060043363161601, 1119606639881808286, 2211903887497377980, 395875676649998273].to_vec()
    };

    let expected_res = vec384 {
        ls: [16494539950903960225, 6909894500484332639, 10854278113294925999, 10279541547892741855, 12499445441687670930, 440910865060157199].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.temp_mul_mont_n(r1_vec, r2_vec)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}