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
async fn test_equals() {
    let a = Element{ 
        l_0: 2251799813685247, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };
    let b = Element{ 
        l_0: 2251799813685247, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };   

    let (_instance, _id) = get_contract_instance().await;

    let a_b_equal = _instance.equals(a, b).call().await.unwrap().value;
    assert!(a_b_equal);
}

#[tokio::test]
async fn test_multiply_by_0() {
    let (_instance, _id) = get_contract_instance().await;

    //a = 2^255 - 21
    let a = Element{ 
        l_0: 2251799813685227, 
        l_1: 2251799813685247, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247 
    };
    let res = _instance.multiply(a, ZERO)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    assert!(res_equals(res, ZERO));
}

#[tokio::test]
async fn test_multiply_1_by_1() {
    let (_instance, _id) = get_contract_instance().await;

    //a = 2^255 - 21
    let a = Element{ 
        l_0: 2251799813685227, 
        l_1: 2251799813685247, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247 
    };
    let res = _instance.multiply(ONE, ONE)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    assert!(res_equals(res, ONE));
}

#[tokio::test]
async fn test_multiply_by_1_small() {
    let (_instance, _id) = get_contract_instance().await;

    let a = Element{ 
        l_0: 10, 
        l_1: 11, 
        l_2: 12,
        l_3: 13,
        l_4: 14
    };
    let res = _instance.multiply(a, ONE)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    let expected_res = Element { 
        l_0: 10, 
        l_1: 11, 
        l_2: 12,
        l_3: 13,
        l_4: 14
    };
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_multiply_by_1_large() {
    let (_instance, _id) = get_contract_instance().await;
    let a = Element{ 
        l_0: 2251799813685227, 
        l_1: 2251799813685247, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let res = _instance.multiply(a, ONE)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    let expected_res = Element { 
        l_0: 2251799813685227, 
        l_1: 2251799813685247, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_multiply_small_elms() {
    let (_instance, _id) = get_contract_instance().await;
    let a = Element{ 
        l_0: 10,
        l_1: 11,
        l_2: 12,
        l_3: 13,
        l_4: 14
    };
    let b = Element{ 
        l_0: 2,
        l_1: 3,
        l_2: 4,
        l_3: 5,
        l_4: 6
    };
    let res = _instance.multiply(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    let expected_res = Element{ 
        l_0: 4200,
        l_1: 3719,
        l_2: 2909,
        l_3: 1752,
        l_4: 230
    };
    assert!(res_equals(res, expected_res));
}


#[tokio::test]
async fn test_multiply_small_elms_2() {
    let (_instance, _id) = get_contract_instance().await;
    let a = Element{ 
        l_0: 10,
        l_1: 11,
        l_2: 12,
        l_3: 1292655137982008,
        l_4: 14
    };
    let b = Element{ 
        l_0: 2,
        l_1: 3,
        l_2: 4,
        l_3: 5,
        l_4: 6
    };
    let res = _instance.multiply(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    let expected_res = Element{ 
        l_0: 1414398498170175,
        l_1: 1205048169289895,
        l_2: 995697840409273,
        l_3: 333510462280559,
        l_4: 1626165600260968
    };
    assert!(res_equals(res, expected_res));
}


#[tokio::test]
async fn test_multiply_small_elms_3() {
    let (_instance, _id) = get_contract_instance().await;
    let a = Element{ 
        l_0: 1292655137982008,
        l_1: 1303372017735434,
        l_2: 595911506101250,
        l_3: 601879629470779,
        l_4: 50591579140481
    };
    let b = Element{ 
        l_0: 2,
        l_1: 3,
        l_2: 4,
        l_3: 5,
        l_4: 6
    };
    let res = _instance.multiply(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    
    let expected_res = Element{ 
        l_0: 1954506281775991,
        l_1: 334157138245186,
        l_2: 376444288997219,
        l_3: 169499236944723,
        l_4: 548860478185542
    };
    assert!(res_equals(res, expected_res));
}


#[tokio::test]
async fn test_multiply_elms_4() {
    let (_instance, _id) = get_contract_instance().await;
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
    let res = _instance.multiply(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    let expected_res = Element{ 
        l_0: 896638975913114,
        l_1: 1000789340506524,
        l_2: 355992668009873,
        l_3: 806477788321681,
        l_4: 1027544741541094
    };
    assert!(res_equals(res, expected_res));
}
