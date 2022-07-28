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
async fn test_not() {
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.not(18417751708719972248)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == 28992364989579367);
}

#[tokio::test]
async fn tests_subtract_wrap() {
    let (_instance, _id) = get_contract_instance().await;

    let res1 = _instance.subtract_wrap(U128{upper: 0, lower: 100}, U128{upper: 0, lower: 80})
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res1.lower == 20);
    assert!(res1.upper == 0);

    let res2 = _instance.subtract_wrap(U128{upper: 0, lower: 100}, U128{upper: 0, lower: 230})
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    assert!(res2.lower == 18446744073709551486);
    assert!(res2.upper == 18446744073709551615);
}

#[tokio::test]
async fn tests_sbb() {
    let (_instance, _id) = get_contract_instance().await;

    let res1 = _instance.sbb(0,0,0)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    let res2 = _instance.sbb(0,1,0)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    let res3 = _instance.sbb(0,1,1)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;

    let a = 435983458;
    let res4 = _instance.sbb(a,0,1)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;

    assert!(res1.0 == 0);
    assert!(res1.1 == 0);

    assert!(res2.0 == u64::MAX);
    assert!(res2.1 == 1);

    assert!(res3.0 == u64::MAX - 1);
    assert!(res3.1 == 1);

    assert!(res4.0 == a-1);
    assert!(res4.1 == 0);
}

#[tokio::test]
async fn test_adc_random() {
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.adc(9837491998535547791, 10009796384580774444, 0)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    assert!(res.0 == 1400544309406770619);
    assert!(res.1 == 1);
}

#[tokio::test]
async fn test_adc_random_with_carry() {
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.adc(9837491998535547791, 10009796384580774444, 1)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    assert!(res.0 == 1400544309406770620);
    assert!(res.1 == 1);
}

#[tokio::test]
async fn test_subtract_p_smaller() {
    let BLS12_381_P: vec384 = vec384 {
        ls: [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;
    let a_smaller_than_p = vec384 {
        ls: [13402431016077863508, 2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866].to_vec()
    };
    let expected_res = vec384 {
        ls: [13402431016077863508, 2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866].to_vec()
    };

    let res = _instance.subtract_p(a_smaller_than_p, BLS12_381_P)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;

    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_subtract_p_larger() {
    let BLS12_381_P: vec384 = vec384 {
        ls: [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;
    let a_larger_than_p = vec384 { // p+ 200
        ls: [13402431016077863795, 2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866].to_vec()
    };
    let expected_res = vec384 {
        ls: [200, 0, 0, 0, 0, 0].to_vec()
    };

    let res = _instance.subtract_p(a_larger_than_p, BLS12_381_P)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_neg_p() {
    let BLS12_381_P: vec384 = vec384 {
        ls: [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;
    let p: vec384 = vec384 {
        ls: [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a].to_vec()
    };
    let zero: vec384 = vec384 {
        ls: [0, 0, 0, 0, 0, 0].to_vec()
    };

    let res = _instance.neg(p, BLS12_381_P)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    
    assert!(res_equals(res, zero));
}

#[tokio::test]
async fn test_neg_1() {
    let BLS12_381_P: vec384 = vec384 {
        ls: [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;
    let one: vec384 = vec384 {
        ls: [1, 0, 0, 0, 0, 0].to_vec()
    };
    let expected_res = vec384 { // p-1
        ls: [13402431016077863594, 2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866].to_vec()
    };

    let res = _instance.neg(one, BLS12_381_P)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_neg_random() {
    let BLS12_381_P: vec384 = vec384 {
        ls: [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;
    let r = vec384 {
        ls: [13059245463466299169, 17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687].to_vec()
    };
    let expected_res = vec384 { // p-r
        ls: [343185552611564426, 2882282484148780005, 6545683898001206309, 12914691390957992833, 41210333997197102, 1273825819919628179].to_vec()
    };

    let res = _instance.neg(r, BLS12_381_P)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    
    assert!(res_equals(res, expected_res));
}