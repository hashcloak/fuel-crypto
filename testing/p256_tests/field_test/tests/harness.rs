use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}, 
};
use fuel_core_chain_config::ChainConfig;

// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/field_test-abi.json"
));

async fn get_contract_methods() -> (MyContractMethods<WalletUnlocked>, ContractId) {
  let mut wallet = WalletUnlocked::new_random(None);
  let num_assets = 1;
  let coins_per_asset = 100;
  let amount_per_coin = 100000;
  let (coins, _asset_ids) = setup_multiple_assets_coins(
      wallet.address(),
      num_assets,
      coins_per_asset,
      amount_per_coin,
  );
  // Custom gas limit
  let consensus_parameters_config = ConsensusParameters::DEFAULT
    .with_max_gas_per_tx(100_000_000_000).with_gas_per_byte(0);
  let mut chain_config = ChainConfig::local_testnet();
  // This is needed to allow for expensive operations
  chain_config.block_gas_limit = 100_000_000_000;
  let (client, _addr) = setup_test_client(coins, vec![], None, Some(chain_config), Some(consensus_parameters_config)).await;
  let provider = Provider::new(client);
  wallet.set_provider(provider.clone());
  let id = Contract::deploy(
      "./out/debug/field_test.bin",
      &wallet,
      DeployConfiguration::default(),
  )
  .await
  .unwrap();
  let instance = MyContract::new(id.clone(), wallet);
  (instance.methods(), id.into())
}

fn assert_scalar(res: Scalar, expected: Scalar) {
  assert_eq!(res.ls[0], expected.ls[0]);
  assert_eq!(res.ls[1], expected.ls[1]);
  assert_eq!(res.ls[2], expected.ls[2]);
  assert_eq!(res.ls[3], expected.ls[3]);
}

async fn to_montgomery_ab(_methods: &MyContractMethods<WalletUnlocked>, a: FieldElement, b: FieldElement) -> (FieldElement, FieldElement) {
  let a_montgomery_form = _methods
    .fe_to_montgomery(a)
    .call().await.unwrap();
  let b_montgomery_form = _methods
    .fe_to_montgomery(b)
    .call().await.unwrap();
  (a_montgomery_form.value, b_montgomery_form.value)
}

async fn from_montgomery(_methods: &MyContractMethods<WalletUnlocked>, a: FieldElement) -> FieldElement {
  _methods
    .fe_from_montgomery(a)
    .call().await.unwrap().value
}

async fn to_montgomery(_methods: &MyContractMethods<WalletUnlocked>, a: FieldElement) -> FieldElement {
  _methods
    .fe_to_montgomery(a)
    .call().await.unwrap().value
}
//41624337018869194729192205381537838788846303834619688597471765238035829032504
const X_SCALAR: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

//112889434785065900135211481371037383646282385554418514861667765615237067913479
const Y_SCALAR: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};

#[tokio::test]
async fn test_fe_mul_1() {
  let (_methods, _id) = get_contract_methods().await;

  // Test 1
  let a1: FieldElement = FieldElement{ls: [1,1,1,1]};
  let b1: FieldElement = FieldElement{ls: [1,0,0,0]};
  
  let (a1_montgomery_form, b1_montgomery_form) = to_montgomery_ab(&_methods, a1, b1).await;
  let result1 = _methods
    .fe_mul(a1_montgomery_form, b1_montgomery_form)
    .call().await.unwrap();
  let result1_converted = from_montgomery(&_methods, result1.value).await;
  
  assert_eq!(FieldElement{ls: [1,1,1,1]}, result1_converted);

  // Test 2
  let a2: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
  let b2: FieldElement = FieldElement{ls: [10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};
  
  let (a2_montgomery_form, b2_montgomery_form) = to_montgomery_ab(&_methods, a2, b2).await;
  let result2 = _methods
    .fe_mul(a2_montgomery_form, b2_montgomery_form)
    .call().await.unwrap();
  let result_converted2 = from_montgomery(&_methods, result2.value).await;
  
  let expected2: FieldElement = FieldElement{ls: [3855380404042364083, 4501942987140393524, 18012298605561464384, 6330810359896140563]};

  assert_eq!(expected2, result_converted2);

  // Test 3
  let a3: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
  let b3: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
  
  let (a3_montgomery_form, b3_montgomery_form) = to_montgomery_ab(&_methods, a3, b3).await;
  let result3 = _methods
    .fe_mul(a3_montgomery_form, b3_montgomery_form)
    .call().await.unwrap();
  let result_converted3 = from_montgomery(&_methods, result3.value).await;
  
  let expected3: FieldElement = FieldElement{ls: [2309392440375388613, 1135074464031845990, 12738695718013625742, 14519977860574561767]};

  assert_eq!(expected3, result_converted3);

}

#[tokio::test]
async fn test_sqrt() {
  let (_methods, _id) = get_contract_methods().await;

  // Random nr 59139082389495374972926751946201499749231456944901481987554600995611674860084
  // 8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936
  let r: FieldElement = FieldElement{ls: [8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936]};

  let r_form = to_montgomery(&_methods, r).await;
  let sqrt_r = _methods
    .sqrt(r_form)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();
  let result_converted = from_montgomery(&_methods, sqrt_r.value.value).await;
  let expected: FieldElement = FieldElement{ls: [10414696227621044143, 5518441681270087222, 392556470792855661, 10489680726816654902]};

  assert_eq!(expected, result_converted);
}

#[tokio::test]
async fn test_invert_1() {
  let (_methods, _id) = get_contract_methods().await;

  // TEST 1

  // root of unity 115792089210356248762697446949407573530086143415290314195533631308867097853950
  // [18446744073709551614, 4294967295, 0, 18446744069414584321]
  let root_of_unity = FieldElement { ls: [18446744073709551614, 4294967295, 0, 18446744069414584321]};
  let root_of_unity_montgomery_form = to_montgomery(&_methods, root_of_unity).await;

  let inv_montgomery_form = _methods
    .invert(root_of_unity_montgomery_form)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let result1_converted = from_montgomery(&_methods, inv_montgomery_form.value.value).await;
  let expected1: FieldElement = FieldElement{ls: [18446744073709551614, 4294967295, 0, 18446744069414584321]};

  assert_eq!(expected1, result1_converted);

  // TEST 2

  let z = FieldElement { ls: [1993877568177495041, 10345888787846536528, 7746511691117935375, 14517043990409914413]};
  let z_montgomery_form = to_montgomery(&_methods, z).await;

  let inv_z_montgomery_form = _methods
    .invert(z_montgomery_form)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let result2_converted = from_montgomery(&_methods, inv_z_montgomery_form.value.value).await;
  let expected2: FieldElement = FieldElement{ls: [4299806231468303744, 8024480717984164326, 11501998322799236989, 8789660679986197156]};

  assert_eq!(expected2, result2_converted);

  // TEST 3
  let x = FieldElement { ls: [10634854829044225757, 351552716085025155, 10645315080955407736, 3609262091244858135]};
  let x_montgomery_form = to_montgomery(&_methods, x).await;

  let inv_x_montgomery_form = _methods
    .invert(x_montgomery_form)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let result3_converted = from_montgomery(&_methods, inv_x_montgomery_form.value.value).await;
  // z^(-1) = 88647100750625721153149943186404157918844683715528760041837114016635683486024
  let expected3: FieldElement = FieldElement{ls: [12758252840858302792, 2862372623786672612, 7477786404377448950, 14122297915116537490]};

  assert_eq!(expected3, result3_converted);
}

#[tokio::test]
async fn test_pow_vartime() {
  let (_methods, _id) = get_contract_methods().await;

  // 59139082389495374972926751946201499749231456944901481987554600995611674860084
  let a: FieldElement = FieldElement{ls:[8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936]};
  let a_montgomery_form = to_montgomery(&_methods, a).await;

  let pow_vartime = _methods
    .pow_vartime(a_montgomery_form.clone(), [4,0,0,0])
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let result1_converted = from_montgomery(&_methods, pow_vartime.value).await;
  let expected1 = FieldElement{ls: [18077862325614776725, 13343880950817753919, 13722074626277446175, 18017497567293989711]};

  assert_eq!(expected1, result1_converted);
}

#[tokio::test]
async fn test_fe_to_bytes() {
  let (_methods, _id) = get_contract_methods().await;

  // bigint 43872280807156713839160376167191808430140484563252114113014272064716834774966
  let x = FieldElement { ls:[16602909452612575158, 13855808666783054444, 14511138361138572648, 6989257567681289521] };

  let bytes = _methods
    .fe_to_bytes(x)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  assert_eq!(bytes.value, [96, 254, 212, 186, 37, 90, 157, 49, 201, 97, 235, 116, 198, 53, 109, 104, 192, 73, 184, 146, 59, 97, 250, 108, 230, 105, 98, 46, 96, 242, 159, 182]);
}

#[tokio::test]
async fn test_bytes_to_scalar() {
  let (_methods, _id) = get_contract_methods().await;

  // test value: 112889434785065900135211481371037383646282385554418514861667765615237067913479
  let byte_array: [u8;32] = [249, 149, 39, 226, 134, 32, 66, 219, 182, 99, 19, 244, 76, 76, 71, 182, 192, 37, 158, 22, 246, 63, 0, 1, 148, 196, 213, 187, 227, 187, 57, 7];
  let result = _methods
    .scalar_from_bytes(byte_array)
    .call().await.unwrap();

  let expected_res = Scalar{ ls: [10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};
  assert_scalar(result.value, expected_res);
}

#[tokio::test]
async fn test_scalar_add() {
  let (_methods, _id) = get_contract_methods().await;

  // TEST 1
  //31416255128259651114300763853743354944401428675127717048158727858123196938092
  let x1: Scalar = Scalar{ls: [15982738825684268908, 12861376030615125811, 9837491998535547791, 5004898192290387222]};

  //3012016290743527304884562416673584005842165475579906631995563069167839294388
  let y1: Scalar = Scalar{ls:[ 10598342506117936052, 6743270311476307786, 2169871353760194456, 479841878898268594]};

  let scalar_add = _methods
    .scalar_add(x1, y1)
    .call().await.unwrap();

  // Result is also 34428271419003178419185326270416938950243594150707623680154290927291036232480
  let expected_res1 = Scalar{ ls: [8134337258092653344, 1157902268381881982, 12007363352295742248, 5484740071188655816]};
  assert_scalar(scalar_add.value, expected_res1);

  // TEST 2
  //41624337018869194729192205381537838788846303834619688597471765238035829032504
  let x2: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

  //112889434785065900135211481371037383646282385554418514861667765615237067913479
  let y2: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};

  let scalar_add2 = _methods
    .scalar_add(x2, y2)
    .call().await.unwrap();

  // Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
  let expected_res2 = Scalar{ ls: [6440044811543714286, 7791126261927965313, 9686708628070057556, 6168719932526873529]};
  assert_scalar(scalar_add2.value, expected_res2);
}

#[tokio::test]
async fn test_scalar_sub() {
  let (_methods, _id) = get_contract_methods().await;

  let scalar_sub = _methods
    .scalar_sub(X_SCALAR, Y_SCALAR)
    .call().await.unwrap();

  // Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
  let expected_res = Scalar{ ls: [1678027027253883522, 7323518455198527368, 1848712546639099622, 7093558989675447812]};
  assert_scalar(scalar_sub.value, expected_res);
}

#[tokio::test]
async fn test_scalar_mul() {
  let (_methods, _id) = get_contract_methods().await;

  let scalar_mul = _methods
    .scalar_mul(X_SCALAR, Y_SCALAR)
    .call().await.unwrap();

  // Result = 103996961415186572744923623518133659781096567566995581831564221704662704998922
  let expected_res = Scalar{ ls: [12652583779974793738, 11510399856113002259, 17112986354705659152, 16567671801288747593]};
  assert_scalar(scalar_mul.value, expected_res);
}

#[tokio::test]
async fn test_scalar_invert() {
  let (_methods, _id) = get_contract_methods().await;

  // 6024032581487054615307857608562388818842860057096001857409703737786438595508
  let x: Scalar = Scalar{ls: [10598342506117936052, 6743270311476307786, 2169871353760194456, 959683757796537189]};
  
  let invert_x = _methods
    .scalar_invert(x)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  // result should be 84801081494837761602111676842516221872243864255054144073280115004536303842931
  let expected_res = Scalar{ ls: [9530314696573515379, 1325056620123427311, 7698614219480972011, 13509591698470992260]};
  assert_scalar(invert_x.value.value, expected_res);
}