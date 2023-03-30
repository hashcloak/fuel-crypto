use fuels::{prelude::*, tx::ContractId};

// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/p256_tests-abi.json"
));

async fn get_contract_instance() -> (MyContract, ContractId) {
    // Launch a local network and deploy the contract
    let mut wallets = launch_custom_provider_and_get_wallets(
        WalletsConfig::new(
            Some(1),             /* Single wallet */
            Some(1),             /* Single coin (UTXO) */
            Some(1_000_000_000), /* Amount per coin */
        ),
        None,
        None,
    )
    .await;
    let wallet = wallets.pop().unwrap();

    let id = Contract::deploy(
        "./out/debug/p256_tests.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(Some(
            "./out/debug/p256_tests-storage_slots.json".to_string(),
        )),
    )
    .await
    .unwrap();

    let instance = MyContract::new(id.clone(), wallet);

    (instance, id.into())
}

#[tokio::test] #[ignore]
async fn test_fe_mul_1() {
    let (_instance, _id) = get_contract_instance().await;
    let a: FieldElement = FieldElement{ls: [1,1,1,1]};
    let b: FieldElement = FieldElement{ls: [1,0,0,0]};
    
    let a_montgomery_form = _instance
      .methods()
      .fe_to_montgomery(a)
      .call().await.unwrap();

    let b_montgomery_form = _instance
      .methods()
      .fe_to_montgomery(b)
      .call().await.unwrap();

    let result = _instance
      .methods()
      .fe_mul(a_montgomery_form.value, b_montgomery_form.value)
      .call().await.unwrap();
      
    let result_converted = _instance
      .methods()
      .fe_from_montgomery(result.value)
      .call().await.unwrap();
    
    let expected: FieldElement = FieldElement{ls: [1,1,1,1]};

    assert_eq!(expected, result_converted.value);
}

#[tokio::test] #[ignore]
async fn test_fe_mul_2() {
    let (_instance, _id) = get_contract_instance().await;
    let a: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
    let b: FieldElement = FieldElement{ls: [10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};
    
    let a_montgomery_form = _instance
      .methods()
      .fe_to_montgomery(a)
      .call().await.unwrap();

    let b_montgomery_form = _instance
      .methods()
      .fe_to_montgomery(b)
      .call().await.unwrap();

    let result = _instance
      .methods()
      .fe_mul(a_montgomery_form.value, b_montgomery_form.value)
      .call().await.unwrap();
      
    let result_converted = _instance
      .methods()
      .fe_from_montgomery(result.value)
      .call().await.unwrap();
    
    let expected: FieldElement = FieldElement{ls: [3855380404042364083, 4501942987140393524, 18012298605561464384, 6330810359896140563]};

    assert_eq!(expected, result_converted.value);
}

#[tokio::test] #[ignore]
async fn test_fe_mul_3() {
    let (_instance, _id) = get_contract_instance().await;
    let a1: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
    let a2: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

    
    let a1_montgomery_form = _instance
      .methods()
      .fe_to_montgomery(a1)
      .call().await.unwrap();

    let a2_montgomery_form = _instance
      .methods()
      .fe_to_montgomery(a2)
      .call().await.unwrap();

    let result = _instance
      .methods()
      .fe_mul(a1_montgomery_form.value, a2_montgomery_form.value)
      .call().await.unwrap();
      
    let result_converted = _instance
      .methods()
      .fe_from_montgomery(result.value)
      .call().await.unwrap();
    
    let expected: FieldElement = FieldElement{ls: [2309392440375388613, 1135074464031845990, 12738695718013625742, 14519977860574561767]};

    assert_eq!(expected, result_converted.value);
}

#[tokio::test]
async fn test_sqrt() {
    // Random nr 59139082389495374972926751946201499749231456944901481987554600995611674860084
    // 8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936
    let (_instance, _id) = get_contract_instance().await;
    let r: FieldElement = FieldElement{ls: [8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936]};

    let r_form = _instance
      .methods()
      .fe_to_montgomery(r)
      .call().await.unwrap();

    let sqrt_r = _instance
      .methods()
      .sqrt(r_form.value)
      .tx_params(TxParameters::new(None, Some(100_000_000), None))
      .call().await.unwrap();

    let result_converted = _instance
      .methods()
      .fe_from_montgomery(sqrt_r.value.value)
      .call().await.unwrap();

    // println!("{:#?}", result_converted.value);
    assert_eq!(result_converted.value.ls[0], 10414696227621044143);
    assert_eq!(result_converted.value.ls[1], 5518441681270087222);
    assert_eq!(result_converted.value.ls[2], 392556470792855661);
    assert_eq!(result_converted.value.ls[3], 10489680726816654902);
    /*
    [10489680726816654902,392556470792855661,5518441681270087222,10414696227621044143]
    equals 65844793093953043268213057897943240429286616083437016212003006386916887363503
    square of this is
    59139082389495374972926751946201499749231456944901481987554600995611674860084
    so, correct
    */
}

#[tokio::test]
async fn test_invert() {
    let (_instance, _id) = get_contract_instance().await;
    // root of unity 115792089210356248762697446949407573530086143415290314195533631308867097853950
    // [18446744073709551614, 4294967295, 0, 18446744069414584321]
    let root_of_unity = FieldElement { ls: [18446744073709551614, 4294967295, 0, 18446744069414584321]};

    let montgomery_form = _instance
      .methods()
      .fe_to_montgomery(root_of_unity)
      .call().await.unwrap();

    let inv_montgomery_form = _instance
      .methods()
      .invert(montgomery_form.value)
      .tx_params(TxParameters::new(None, Some(100_000_000), None))
      .call().await.unwrap();

    let inv = _instance
      .methods()
      .fe_from_montgomery(inv_montgomery_form.value.value)
      .call().await.unwrap();

// Result is also 115792089210356248762697446949407573530086143415290314195533631308867097853950
    assert_eq!(inv.value.ls[0], 18446744073709551614);
    assert_eq!(inv.value.ls[1], 4294967295);
    assert_eq!(inv.value.ls[2], 0);
    assert_eq!(inv.value.ls[3], 18446744069414584321);
}