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
async fn test_sub_zero_from_zero() {
    let zero_1: vec384 = vec384 {
        ls: [0, 0, 0, 0, 0, 0].to_vec()
    };
    let zero_2: vec384 = vec384 {
        ls: [0, 0, 0, 0, 0, 0].to_vec()
    };
    let zero_3: vec384 = vec384 {
        ls: [0, 0, 0, 0, 0, 0].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.sub_fp(zero_1, zero_2)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, zero_3));
}

#[tokio::test]
async fn test_sub_zero_from_random() {
    let random = vec384{ 
        ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d].to_vec()
    };
    let expected_res = vec384{ 
        ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d].to_vec()
    };
    let zero_4: vec384 = vec384 {
        ls:[0,0,0,0,0,0].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.sub_fp(random, zero_4)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_sub_random_from_zero() {
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687].to_vec()
    };
    let zero_4: vec384 = vec384 {
        ls:[0,0,0,0,0,0].to_vec()
    };
    let expected_res = vec384{ 
        ls: [343185552611564426, 2882282484148780005, 6545683898001206309, 12914691390957992833, 41210333997197102, 1273825819919628179].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.sub_fp(zero_4,r)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_sub_random_from_small() {
    let small = vec384 {
        ls: [1, 2, 3, 4, 5, 6].to_vec()
    };
    let r = vec384 {
        ls: [13059245463466299169, 17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687].to_vec()
    };
    let expected_res = vec384{ 
        ls: [343185552611564427, 2882282484148780007, 6545683898001206312, 12914691390957992837, 41210333997197107, 1273825819919628185].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.sub_fp(small, r)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_sub_2_random() {
    let a = vec384 {
        ls: [10587454305359941416, 4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194].to_vec()
    };

    let b = vec384 {
        ls: [13403040667047958534, 405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174].to_vec()
    };
    let expected_res = vec384{ 
        ls: [15631157712021534498, 4210040059583301456, 2072967503069563536, 7744598167717445820, 16967452369712105079, 469452209245280019].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.sub_fp(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}