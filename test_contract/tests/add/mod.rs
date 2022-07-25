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
async fn test_add_to_0() {
    let a = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };
    let expected_res = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add(ZERO, a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_add_0() {
    let a = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };
    let expected_res = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add(a, ZERO)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_add_a_to_b() {
    let a = Element{ 
        l_0: 2251799813685247,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let b = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };
    let expected_res = Element{ 
        l_0: 8209, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_add_a_to_a() {
    let a = Element{ 
        l_0: 2251799813685228,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let a_again = Element{ 
        l_0: 2251799813685228,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let expected_res = Element{ 
        l_0: 2251799813685227, 
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add(a, a_again)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}