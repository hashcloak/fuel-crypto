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
async fn test_temp_mul_random_by_random() {
    let p_vec: vec384 = vec384 {
        ls: [0xb9feffffffffaaab, 
        0x1eabfffeb153ffff,
        0x6730d2a0f6b0f624,
        0x64774b84f38512bf,
        0x4b1ba7b6434bacd7,
        0x1a0111ea397fe69a].to_vec()
    };
    let r1_vec: vec384 = vec384 {
        ls: [6071868568151433008, 
        12105094901188801210,
        2389211775905699303,
        7838417195104481535,
        5826366508043997497,
        13436617433956842131].to_vec()
    };
    let r2_vec: vec384 = vec384 {
        ls: [16964885827015180015, 
        12035734743809705289,
        10517060043363161601,
        1119606639881808286,
        2211903887497377980,
        395875676649998273].to_vec()
    };
    // this is the expected result according to the zkcrypto impl. This is multiplication on montgomery forms
    let expected_res: vec384 = vec384 {
        ls: [16484308011771146774, 12795119582497094196, 7495239071060242083, 
        6228288009955243706, 334445847756758381, 1343304342180463133].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.mul_temp_wrapper(r1_vec, r2_vec, p_vec, 6)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));

    //zkcrypto impl gives this res as well. So it's not a "standard" mul
    //[16484308011771146774, 12795119582497094196, 7495239071060242083, 
    // 6228288009955243706, 334445847756758381, 1343304342180463133]
}

#[tokio::test]
async fn test_mul_temp_by_2() {
    let p_vec: vec384 = vec384 {
        ls: [0xb9feffffffffaaab, 
        0x1eabfffeb153ffff,
        0x6730d2a0f6b0f624,
        0x64774b84f38512bf,
        0x4b1ba7b6434bacd7,
        0x1a0111ea397fe69a].to_vec()
    };

    //2367106380816923637832389518823092703674202766714323478820851269126356623723913304989534316437425836090100832620729
    let r1_vec: vec384 = vec384 {
        ls: [9172416622910853305, 14987574562624449790, 
        13213778230238218784, 15872153713916140599, 
        9712154313263354644, 1108202597211161767].to_vec()
    };
    let vec_2: vec384 = vec384 {
        ls: [2,0,0,0,0,0].to_vec()
    };

    // this is the expected result according to the zkcrypto impl. This is multiplication on montgomery forms
    let expected_res: vec384 = vec384 {
        ls: [11360606136736300744, 10320420748134520786, 17912563010296520217, 
        16145629554006184624, 12933232110729028586, 1518885514198738558].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.mul_temp_wrapper(r1_vec, vec_2, p_vec, 6)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}