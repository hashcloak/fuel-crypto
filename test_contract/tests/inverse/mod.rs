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
async fn test_inverse_random() {
    /*
    TO_LIMB_T(0xf4df1f341c341746), TO_LIMB_T(0x0a76e6a609d104f1),
    TO_LIMB_T(0x8de5476c4c95b6d5), TO_LIMB_T(0x67eb88a9939d83c0),
    TO_LIMB_T(0x9a793e85b519952d), TO_LIMB_T(0x11988fe592cae3aa)
    */
    let a = Element{ 
        l_0: 715325916561861, 
        l_1: 1128975921026318, 
        l_2: 1696955067652624,
        l_3: 2081297221826529,
        l_4: 175872643896950
    };
    let expected_res = Element{ 
        l_0: 2187613694507759, 
        l_1: 1614434677729781,
        l_2: 1594711943325299,
        l_3: 378203143193209,
        l_4: 843416921835783
    };   

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.inverse(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

        assert!(res_equals(res, expected_res));
}