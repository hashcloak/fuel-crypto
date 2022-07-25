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
async fn test_add_zero_to_zero() {
    let ZERO_1: vec384 = vec384 {
        ls: [0, 0, 0, 0, 0, 0].to_vec()
    };
    let ZERO_2: vec384 = vec384 {
        ls: [0, 0, 0, 0, 0, 0].to_vec()
    };
    let ZERO_3: vec384 = vec384 {
        ls: [0, 0, 0, 0, 0, 0].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_fp(ZERO_1, ZERO_2)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, ZERO_3));
}

#[tokio::test]
async fn test_add_zero_to_random() {
    let random = vec384{ 
        ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d].to_vec()
    };
    let zero = vec384 {
        ls: [0, 0, 0, 0, 0, 0].to_vec()
    };
    let expected_res = vec384{ 
        ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d].to_vec()
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_fp(random, zero)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_add_random_to_small() {
    let small = vec384{ 
        ls: [1, 2, 3, 4, 5, 6].to_vec()
    };
    let random = vec384{ 
        ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d].to_vec()
    };
    let expected_res = vec384{ 
        ls: [4478030004447473543, 2814704111667093004, 15884408734010272161, 17001047363111187582, 932823543034528552, 1051481384684610851].to_vec()
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_fp(small, random)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_add_larger_than_p() {
    let a = vec384{ 
        ls: [13402431016077863508,2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866].to_vec()
    };
    let b = vec384{ 
        ls: [100,0,0,0,0,0].to_vec()
    };
    let expected_res = vec384{ 
        ls: [13, 0,0,0,0,0].to_vec()
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_fp(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_add_2_randoms() {
    let random_1 = vec384{ 
        ls: [4510245898505151773,8849327944066866226, 11451510199254766964, 782624411996506985, 9666712539018543006, 17492304704872943].to_vec()
    };
    let random_2 = vec384{ 
        ls: [8877477209635348035,16708328088811667500, 14014037299927741552, 1795070958963053268, 10606788931721547929, 841903545056265961].to_vec()
    };
    let expected_res = vec384{ 
        ls: [13387723108140499808, 7110911959168982110, 7018803425472956901, 2577695370959560254, 1826757397030539319, 859395849761138905].to_vec()
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_fp(random_1, random_2)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}
