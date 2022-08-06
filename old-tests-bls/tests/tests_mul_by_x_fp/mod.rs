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
async fn test_mul_by_3_fp_zero() {
    let zero: vec384 = vec384 {
        ls:[0,0,0,0,0,0].to_vec()
    };

    let expected_res = vec384{ 
        ls:[0,0,0,0,0,0].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.mul_by_3_fp(zero)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_mul_by_3_fp() {
    let a = vec384 {
        ls: [5598198260030196614, 9227139175563025534, 12721729458998794199, 15322498199590564519, 14360971206699872851, 1550139647308650475].to_vec()
    };

    let expected_res = vec384{ 
        ls: [8436476821644414268, 4814390429945107835, 4847095156158667582, 13042074604232716920, 13811961989448662348, 902821706630871694].to_vec()
        };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.mul_by_3_fp(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_mul_by_8_fp_zero() {
    let zero: vec384 = vec384 {
        ls:[0,0,0,0,0,0].to_vec()
    };

    let expected_res = vec384{ 
        ls:[0,0,0,0,0,0].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.mul_by_8_fp(zero)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}


#[tokio::test]
async fn tests_mul_by_8_fp() {
    let a = vec384 {
        ls: [4748578380656466952, 10419428663092908236, 18363049814497995794, 10615108747081361673, 10405771956295193853, 1009856344616347211].to_vec()
    };
    let expected_res = vec384{ 
        ls: [2825647054649832852, 727886963836225123, 6481235779470329860, 623285913863388498, 6257528315350086799, 583656286340618227].to_vec()
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.mul_by_8_fp(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}