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
async fn test_carry_propagate_1() {
    let a = Element{ 
        l_0: u64::MAX,
        l_1: u64::MAX,
        l_2: u64::MAX,
        l_3: u64::MAX,
        l_4: u64::MAX
    };
    let expected_res = Element{ 
        l_0: 2251799813685247 + (19*8191), 
        l_1: 2251799813685247 + 8191, 
        l_2: 2251799813685247 + 8191,
        l_3: 2251799813685247 + 8191,
        l_4: 2251799813685247 + 8191
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.carry_propagate(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_carry_propagate_2() {
    let a = Element{ 
        l_0: 2251799813685250,
        l_1: 0,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };
    let expected_res = Element{ 
        l_0: 2,
        l_1: 1,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.carry_propagate(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_reduce() {
    let a = Element{ 
        l_0: 2251799813685250,
        l_1: 0,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };
    let expected_res = Element{ 
        l_0: 2,
        l_1: 1,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.reduce(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_reduce_2() {
    let a = Element{ 
        l_0: 2251799813685250,
        l_1: 2251799813685250,
        l_2: 2251799813685250,
        l_3: 2251799813685250,
        l_4: 2251799813685250
    };
    let expected_res = Element{ 
        l_0: 21,
        l_1: 3,
        l_2: 3,
        l_3: 3,
        l_4: 3
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.reduce(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_reduce_3() {
    let a = Element{ 
        l_0: u64::MAX,
        l_1: u64::MAX,
        l_2: u64::MAX,
        l_3: u64::MAX,
        l_4: u64::MAX
    };
    let expected_res = Element{ 
        l_0: 155647,
        l_1: 8191,
        l_2: 8191,
        l_3: 8191,
        l_4: 8191
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.reduce(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_reduce_4() {
    let a = Element{ 
        l_0: 4503599627370494,
        l_1: 4503599627370494,
        l_2: 4503599627370494,
        l_3: 4503599627370494,
        l_4: 4503599627370494
    };
    let expected_res = Element{ 
        l_0: 36,
        l_1: 0,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.reduce(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}


