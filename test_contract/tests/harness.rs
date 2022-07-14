use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;

// Load abi from json
abigen!(EdContract, "out/debug/test_edwards25519-abi.json");

async fn get_contract_instance() -> (EdContract, ContractId) {
    // Launch a local network and deploy the contract
    let wallet = launch_provider_and_get_single_wallet().await;

    let id = Contract::deploy("./out/debug/test_edwards25519.bin", &wallet, TxParameters::default())
        .await
        .unwrap();

    let instance = EdContract::new(id.to_string(), wallet);

    (instance, id)
}

const zero: Element = Element{ l_0: 0, l_1: 0, l_2: 0, l_3: 0, l_4: 0 };

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
    let res = _instance.multiply(a, zero)
        .tx_params(TxParameters::new(None, Some(100), None, None))
        .call().await.unwrap().value;

    assert!(res_equals(res, zero));
}