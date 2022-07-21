use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;

// Load abi from json
abigen!(EdContract, "out/debug/test_edwards25519-abi.json");

async fn get_contract_instance() -> (EdContract, ContractId) {
    let mut wallets =
    launch_provider_and_get_wallets(WalletsConfig::new_single(Some(1), Some(1000000))).await;
    let wallet = wallets.pop().unwrap();

    let id = Contract::deploy("./out/debug/test_edwards25519.bin", &wallet, TxParameters::default())
        .await
        .unwrap();

    let instance = EdContract::new(id.to_string(), wallet);

    (instance, id)
}

pub fn res_equals(res: Element, should_be: Element) -> bool {
    assert!(res.l_0 == should_be.l_0);
    assert!(res.l_1 == should_be.l_1);
    assert!(res.l_2 == should_be.l_2);
    assert!(res.l_3 == should_be.l_3);
    assert!(res.l_4 == should_be.l_4);
    true
}

#[tokio::test]
async fn test_square1() {
    let a = Element{ 
        l_0: 1292655137982008, 
        l_1: 1303372017735434, 
        l_2: 595911506101250,
        l_3: 312158315551803,
        l_4: 404732633123850 
    };
    let a_square = Element{ 
        l_0: 2144628324130663, 
        l_1: 596790797966485,
        l_2: 912635275234964,
        l_3: 713663780369466,
        l_4: 1207365348681671
    };   

    let (_instance, _id) = get_contract_instance().await;

    let squared_res = _instance.square(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(squared_res, a_square));
}