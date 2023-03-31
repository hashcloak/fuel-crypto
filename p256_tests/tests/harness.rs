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

#[tokio::test] #[ignore]
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

#[tokio::test] #[ignore]
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


// thread 'test_pow_vartime' panicked at 'called `Result::unwrap()` on an `Err` value: ProviderError("gas_limit(1000000) is lower than the estimated gas_used(1381987)")', tests/harness.rs:212:21
// note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
// #[tokio::test]
// async fn test_pow_vartime() {
//     let (_instance, _id) = get_contract_instance().await;
//     let mut exp: Vec<u64> = Vec::new();
//     exp.push(4);
//     // 59139082389495374972926751946201499749231456944901481987554600995611674860084
//     let a: FieldElement = FieldElement{ls:[8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936]};
//     let pow_vartime = _instance
//       .methods()
//       .pow_vartime(a, exp)
//       .call().await.unwrap();

//     //  113097665246986401796390346304073247450823990228174533995721746947810710753685
    
//     let expected: FieldElement = FieldElement{ls: [18077862325614776725, 13343880950817753919, 13722074626277446175, 18017497567293989711]};

//     assert_eq!(expected.ls[0], pow_vartime.value.ls[0]);
// }


#[tokio::test] #[ignore]
async fn test_scalar_add_1() {
    let (_instance, _id) = get_contract_instance().await;

  //31416255128259651114300763853743354944401428675127717048158727858123196938092
  let x: Scalar = Scalar{ls: [15982738825684268908, 12861376030615125811, 9837491998535547791, 5004898192290387222]};

  //3012016290743527304884562416673584005842165475579906631995563069167839294388
  let y: Scalar = Scalar{ls:[ 10598342506117936052, 6743270311476307786, 2169871353760194456, 479841878898268594]};

    let scalar_add = _instance
      .methods()
      .scalar_add(x, y)
      .call().await.unwrap();

// Result is also 34428271419003178419185326270416938950243594150707623680154290927291036232480
    assert_eq!(scalar_add.value.ls[0], 8134337258092653344);
    assert_eq!(scalar_add.value.ls[1], 1157902268381881982);
    assert_eq!(scalar_add.value.ls[2], 12007363352295742248);
    assert_eq!(scalar_add.value.ls[3], 5484740071188655816);
}

#[tokio::test] #[ignore]
async fn test_scalar_add_2() {
  let (_instance, _id) = get_contract_instance().await;

//41624337018869194729192205381537838788846303834619688597471765238035829032504
let x2: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

//112889434785065900135211481371037383646282385554418514861667765615237067913479
let y2: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};

  let scalar_add = _instance
    .methods()
    .scalar_add(x2, y2)
    .call().await.unwrap();

// Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
  assert_eq!(scalar_add.value.ls[0], 6440044811543714286);
  assert_eq!(scalar_add.value.ls[1], 7791126261927965313);
  assert_eq!(scalar_add.value.ls[2], 9686708628070057556);
  assert_eq!(scalar_add.value.ls[3], 6168719932526873529);
}

#[tokio::test] #[ignore]
async fn test_scalar_sub() {
  let (_instance, _id) = get_contract_instance().await;

//41624337018869194729192205381537838788846303834619688597471765238035829032504
let x: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

//112889434785065900135211481371037383646282385554418514861667765615237067913479
let y: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};

  let scalar_sub = _instance
    .methods()
    .scalar_sub(x, y)
    .call().await.unwrap();

// Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
  assert_eq!(scalar_sub.value.ls[0], 1678027027253883522);
  assert_eq!(scalar_sub.value.ls[1], 7323518455198527368);
  assert_eq!(scalar_sub.value.ls[2], 1848712546639099622);
  assert_eq!(scalar_sub.value.ls[3], 7093558989675447812);
}


#[tokio::test]
async fn test_scalar_mul() {
  let (_instance, _id) = get_contract_instance().await;

//41624337018869194729192205381537838788846303834619688597471765238035829032504
let x: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

//112889434785065900135211481371037383646282385554418514861667765615237067913479
let y: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};

  let scalar_mul = _instance
    .methods()
    .scalar_mul(x, y)
    .call().await.unwrap();

// Result = 103996961415186572744923623518133659781096567566995581831564221704662704998922
  assert_eq!(scalar_mul.value.ls[0], 12652583779974793738);
  assert_eq!(scalar_mul.value.ls[1], 11510399856113002259);
  assert_eq!(scalar_mul.value.ls[2], 17112986354705659152);
  assert_eq!(scalar_mul.value.ls[3], 16567671801288747593);
}