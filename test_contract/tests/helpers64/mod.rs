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
async fn tests_multiply64() {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    // let ab = 98471291840283423519614919326553453204;

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.multiply64(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res.lower == 5960040633016627860);
    assert!(res.upper == 5338139427034470684);
}

#[tokio::test]
async fn test_add64_random() {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let aplusb_carry: (u64, u64) = (1400544309406770619, 1);

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add64(a, b, 0)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == aplusb_carry);
}

#[tokio::test]
async fn test_add64_random_with_carry() {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let aplusb_carry: (u64, u64) = (1400544309406770620, 1);

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add64(a, b, 1)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == aplusb_carry);
}

#[tokio::test]
async fn test_add_multiply64() {
    let a = 496009164746885;
    let b = 24764068336973246;
    let r: U128 = U128{upper: 2516888776885, lower: 8614063320694916486};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_multiply64(r, a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res.lower == 10881738262824685884);
    assert!(res.upper == 3182762646142);
}

#[tokio::test]
async fn test_add_multiply64_2() {
    let a = 24764068336973246;
    let b = 137209507300112;
    let r: U128 = U128{upper: 95365234715, lower: 16956620749643293576};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_multiply64(r, a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res.lower == 18148778710141221224);
    assert!(res.upper == 279563898809);
}