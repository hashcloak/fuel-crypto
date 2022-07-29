use fuels::{prelude::*, tx::ContractId};

// Load abi from json
abigen!(BlsTestContract, "out/debug/tests_bls12_381-abi.json");

async fn get_contract_instance() -> (BlsTestContract, ContractId) {
    // Launch a local network and deploy the contract
    let wallet = launch_provider_and_get_wallet().await;

    let id = Contract::deploy(
        "./out/debug/tests_bls12_381.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(None)
    )
    .await
    .unwrap();

    let instance = BlsTestContract::new(id.to_string(), wallet);

    (instance, id)
}


pub fn res_equals(res: Fp, should_be: Fp) -> bool {
    assert!(res.ls[0] == should_be.ls[0]);
    assert!(res.ls[1] == should_be.ls[1]);
    assert!(res.ls[2] == should_be.ls[2]);
    assert!(res.ls[3] == should_be.ls[3]);
    assert!(res.ls[4] == should_be.ls[4]);
    assert!(res.ls[5] == should_be.ls[5]);
    true
}

#[tokio::test]
async fn test_add_fp() {
    let small = Fp{ 
        ls: [1, 2, 3, 4, 5, 6].to_vec()
    };
    let random = Fp{ 
        ls: [0x3e2528903ca1ef86, 0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d].to_vec()
    };
    let expected_res = Fp{ 
        ls: [4478030004447473543, 2814704111667093004, 15884408734010272161, 17001047363111187582, 932823543034528552, 1051481384684610851].to_vec()
    };

    let (contract_instance, _id) = get_contract_instance().await;

    let res = contract_instance.add_fp(small, random)
    .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
    .call_params(CallParameters::new(None, None, Some(100_000_000)))
    .call().await.unwrap().value;
    
    assert!(res_equals(res, expected_res));
}

#[tokio::test]
async fn test_sub_fp() {
    let a = Fp {
        ls: [10587454305359941416, 4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194].to_vec()
    };

    let b = Fp {
        ls: [13403040667047958534, 405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174].to_vec()
    };
    let expected_res = Fp { 
        ls: [15631157712021534498, 4210040059583301456, 2072967503069563536, 7744598167717445820, 16967452369712105079, 469452209245280019].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.sub_fp(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

//WORKS, but smart to comment out when wanting to test other things
#[tokio::test]
async fn test_mul_fp() {
    let r1_vec: Fp = Fp {
        ls: [6071868568151433008, 
        12105094901188801210,
        2389211775905699303,
        7838417195104481535,
        5826366508043997497,
        13436617433956842131].to_vec()
    };
    let r2_vec: Fp = Fp {
        ls: [16964885827015180015, 
        12035734743809705289,
        10517060043363161601,
        1119606639881808286,
        2211903887497377980,
        395875676649998273].to_vec()
    };
    // this is the expected result according to the zkcrypto impl. This is multiplication on montgomery forms
    let expected_res: Fp = Fp {
        ls: [16484308011771146774, 12795119582497094196, 7495239071060242083, 
        6228288009955243706, 334445847756758381, 1343304342180463133].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.mul_fp(r1_vec, r2_vec)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res, expected_res));
}

//WORKS, but smart to comment out when wanting to test other things
#[tokio::test]
async fn test_square_fp() {
    let r1_1: Fp = Fp {
        ls: [6071868568151433008, 
        12105094901188801210,
        2389211775905699303,
        7838417195104481535,
        5826366508043997497,
        13436617433956842131].to_vec()
    };
    let r1_2: Fp = Fp {
        ls: [6071868568151433008, 
        12105094901188801210,
        2389211775905699303,
        7838417195104481535,
        5826366508043997497,
        13436617433956842131].to_vec()
    };
    let r1_3: Fp = Fp {
        ls: [6071868568151433008, 
        12105094901188801210,
        2389211775905699303,
        7838417195104481535,
        5826366508043997497,
        13436617433956842131].to_vec()
    };

    let (_instance, _id) = get_contract_instance().await;

    let expected_res = _instance.mul_fp(r1_1, r1_2)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    let res = _instance.square_fp(r1_3)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    assert!(res_equals(res, expected_res));
}