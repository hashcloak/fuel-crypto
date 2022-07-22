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

// #[tokio::test]
// async fn test_add_zero_to_random() {
//     let random = vec384{ 
//         ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d]
//     };
//     let expected_res = vec384{ 
//         ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d]
//     };

//     let (_instance, _id) = get_contract_instance().await;

//     let res = _instance.add_fp(random, ZERO)
//         .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
//         .call_params(CallParameters::new(None, None, Some(100_000_000)))
//         .call().await.unwrap().value;
//     assert!(res_equals(res, expected_res));
// }