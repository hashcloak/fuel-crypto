use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;
abigen!(EdContract, "out/debug/test_edwards25519-abi.json");

async fn get_contract_instance() -> (EdContract, ContractId) {
    let mut wallets = launch_provider_and_get_wallets(WalletsConfig::new_single(Some(1), Some(1_000_000))).await;
    let wallet = wallets.pop().unwrap();
    let id = Contract::deploy("./out/debug/test_edwards25519.bin", &wallet, TxParameters::default()).await.unwrap();
    let instance = EdContract::new(id.to_string(), wallet);
    (instance, id)
}

const ZERO: Element = Element{ l_0: 0, l_1: 0, l_2: 0, l_3: 0, l_4: 0 };
const ONE: Element = Element{ l_0: 1, l_1: 0, l_2: 0, l_3: 0, l_4: 0 };

pub fn res_equals(res: Element, should_be: Element) -> bool {
    assert!(res.l_0 == should_be.l_0);
    assert!(res.l_1 == should_be.l_1);
    assert!(res.l_2 == should_be.l_2);
    assert!(res.l_3 == should_be.l_3);
    assert!(res.l_4 == should_be.l_4);
    true
}

#[tokio::test]
async fn test_mult_by_0() {
    let a = Element{ 
        l_0: 2251799813685247,
        l_1: 5,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.scalar_mult(a, 0)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, ZERO));
}

#[tokio::test]
async fn test_mult_by_1() {
    let a = Element{ 
        l_0: 79611,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 555555333333222,
        l_4: 2251799813685247
    };
    let expected_res = Element{ 
        l_0: 79611,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 555555333333222,
        l_4: 2251799813685247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.scalar_mult(a, 1)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_mult_by_2() {
    let a = Element{ 
        l_0: 79611,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 555555333333222,
        l_4: 2251799813685247
    };
    let expected_res = Element{ 
        l_0: 159241,
        l_1: 2251799813685246,
        l_2: 2251799813685247,
        l_3: 1111110666666445,
        l_4: 2251799813685246
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.scalar_mult(a, 2)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_mult_by_large_scalar() {
    let a = Element{ 
        l_0: 79611,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 555555333333222,
        l_4: 2251799813685247
    };
    let expected_res = Element{ 
        l_0: 342008245700831,
        l_1: 2251795518717953,
        l_2: 2251799813685247,
        l_3: 536152338865944,
        l_4: 2251796578355658
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.scalar_mult(a, 4294967295)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}