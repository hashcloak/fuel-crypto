use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;

abigen!(EdContract, "out/debug/test_edwards25519-abi.json");

async fn get_contract_instance() -> (EdContract, ContractId) {
    let mut wallets = launch_provider_and_get_wallets(WalletsConfig::new_single(Some(1), Some(1000000))).await;
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
async fn test_subtraction_by_0() {
    let a = Element{ 
        l_0: 2251799813685247, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };
    let expected_res = Element{ 
        l_0: 2251799813685247, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };   

    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(a, ZERO)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(subtract_res, expected_res));
}

#[tokio::test]
async fn test_subtraction_by_1() {
    let a = Element{ 
        l_0: 2251799813685247, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };
    let expected_res = Element{ 
        l_0: 2251799813685246, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };   

    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(a, ONE)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(subtract_res, expected_res));
}

#[tokio::test]
async fn test_subtraction_by_max() {
    let a = Element{ 
        l_0: 2251799813685227,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let b = Element{ 
        l_0: 2251799813685228, 
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };   
    let expected_res = Element{ 
        l_0: 2251799813685228, 
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };  
    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    assert!(res_equals(subtract_res, expected_res));
}

#[tokio::test]
async fn test_subtraction_random() {
    let a = Element{ 
        l_0: 1292655137982008,
        l_1: 1303372017735434,
        l_2: 595911506101250,
        l_3: 601879629470779,
        l_4: 50591579140481
    };
    let b = Element{ 
        l_0: 1360902863141127, 
        l_1: 807899991388824,
        l_2: 335483569739384,
        l_3: 293961277766182,
        l_4: 137209507300112
    };   
    let expected_res = Element{ 
        l_0: 2183552088526110, 
        l_1: 495472026346609,
        l_2: 260427936361866,
        l_3: 307918351704597,
        l_4: 2165181885525617
    };  
    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
        
    assert!(res_equals(subtract_res, expected_res));
}

#[tokio::test]
async fn test_subtraction_random2() {
    let a = Element{ 
        l_0: 1292655137982008,
        l_1: 1303372017735434,
        l_2: 595911506101250,
        l_3: 601879629470779,
        l_4: 50591579140481
    };
    let b = Element{ 
        l_0: 1360902863141127, 
        l_1: 807899991388824,
        l_2: 335483569739384,
        l_3: 293961277766182,
        l_4: 137209507300112
    };   
    let expected_res = Element{ 
        l_0: 68247725159119, 
        l_1: 1756327787338638,
        l_2: 1991371877323381,
        l_3: 1943881461980650,
        l_4: 86617928159630
    };  
    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(b, a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
        
    assert!(res_equals(subtract_res, expected_res));
}