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

#[tokio::test]
async fn test_1_lshift_p() {
    let r = vec384 {
        ls: [13059245463466299169, 17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687].to_vec()
    };
    let expected_res = vec384{ 
        ls: [7671746853223046722, 17102462128446408757, 1779981351125750781, 7096037212622990972, 10741786888947010385, 1199945595455823374].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.lshift_fp(r,1)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_250_lshift_p() {
    let a = vec384 {
        ls: [13749239540608708580, 16959468157877110068, 1567469580365175571, 14160078721051372203, 9626163454156242266, 1779547015017246937].to_vec()
    };
    let expected_res = vec384{ 
        ls: [13113011510218319406, 16706544215516829647, 7984223107370075095, 1162337285386263785, 307447685117845313, 411984953494678179].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.lshift_fp(a, 250)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}