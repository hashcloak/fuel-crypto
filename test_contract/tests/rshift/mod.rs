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
async fn test_shift_right_by51_random() {
    let a: U128 = U128{upper: 16, lower: 0};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.shift_right_by51(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == 131072);
}

#[tokio::test]
async fn test_shift_right_by51_random_2() {
    let a: U128 = U128{upper: 349323232, lower: 456464};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.shift_right_by51(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == 2861655916544);
}

#[tokio::test]
async fn test_shift_right_by51_random_3() {
    let a: U128 = U128{upper: 349323232, lower: 18446744073709551615};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.shift_right_by51(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == 2861655924735);
}