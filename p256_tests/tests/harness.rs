use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}
};
use fuel_core_chain_config::ChainConfig;

// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/p256_tests-abi.json"
));

const G: AffinePoint = AffinePoint {
  x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
  y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
  infinity: 0,
};

//41624337018869194729192205381537838788846303834619688597471765238035829032504
const X_SCALAR: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

//112889434785065900135211481371037383646282385554418514861667765615237067913479
const Y_SCALAR: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};


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
      "./out/debug/p256_tests.bin",
      &wallet,
      DeployConfiguration::default(),
  )
  .await
  .unwrap();

  let instance = MyContract::new(id.clone(), wallet);

  (instance.methods(), id.into())
}

fn assert_xy(x: FieldElement, y: FieldElement, x_res: [u64; 4], y_res: [u64;4]) {
  assert_eq!(x.ls[0], x_res[0]);
  assert_eq!(x.ls[1], x_res[1]);
  assert_eq!(x.ls[2], x_res[2]);
  assert_eq!(x.ls[3], x_res[3]);
  assert_eq!(y.ls[0], y_res[0]);
  assert_eq!(y.ls[1], y_res[1]);
  assert_eq!(y.ls[2], y_res[2]);
  assert_eq!(y.ls[3], y_res[3]);
}

async fn affine_to_proj(_methods: &MyContractMethods<WalletUnlocked>, p: &AffinePoint) -> ProjectivePoint {
  let p_proj = _methods
    .affine_to_proj(p.clone())
    .call().await.unwrap();

  // convert x, y and z to montgomery form
  let x_converted_p = _methods
    .fe_to_montgomery(p_proj.value.clone().x)
    .call().await.unwrap();

  let y_converted_p = _methods
    .fe_to_montgomery(p_proj.value.clone().y)
    .call().await.unwrap();

  let z_converted_p = _methods
    .fe_to_montgomery(p_proj.value.clone().z)
    .call().await.unwrap();

  let p_converted_projective = ProjectivePoint {
    x: x_converted_p.value,
    y: y_converted_p.value,
    z: z_converted_p.value
  };

  p_converted_projective
}

async fn proj_to_resulting_coordinates(_methods: &MyContractMethods<WalletUnlocked>, p: &ProjectivePoint) -> (FieldElement, FieldElement) {
  let affine_result = _methods
    .proj_to_affine(p.clone())
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let (x_converted, y_converted) = convert_from_montgomery(&_methods, &affine_result.value).await;
  (x_converted, y_converted)
}

async fn convert_from_montgomery(_methods: &MyContractMethods<WalletUnlocked>, p: &AffinePoint) -> (FieldElement, FieldElement) {
  let x_converted = _methods
    .fe_from_montgomery(p.clone().x)
    .call().await.unwrap();

  let y_converted = _methods
    .fe_from_montgomery(p.clone().y)
    .call().await.unwrap();

  (x_converted.value, y_converted.value)
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
    assert_eq!(scalar_add.value.ls[0], 8134337258092653344);
    assert_eq!(scalar_add.value.ls[1], 1157902268381881982);
    assert_eq!(scalar_add.value.ls[2], 12007363352295742248);
    assert_eq!(scalar_add.value.ls[3], 5484740071188655816);

    // TEST 2
    //41624337018869194729192205381537838788846303834619688597471765238035829032504
    let x2: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

    //112889434785065900135211481371037383646282385554418514861667765615237067913479
    let y2: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};

    let scalar_add2 = _methods
      .scalar_add(x2, y2)
      .call().await.unwrap();

    // Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
    assert_eq!(scalar_add2.value.ls[0], 6440044811543714286);
    assert_eq!(scalar_add2.value.ls[1], 7791126261927965313);
    assert_eq!(scalar_add2.value.ls[2], 9686708628070057556);
    assert_eq!(scalar_add2.value.ls[3], 6168719932526873529);
}

#[tokio::test]
async fn test_scalar_sub() {
  let (_methods, _id) = get_contract_methods().await;

  let scalar_sub = _methods
    .scalar_sub(X_SCALAR, Y_SCALAR)
    .call().await.unwrap();

  // Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
  assert_eq!(scalar_sub.value.ls[0], 1678027027253883522);
  assert_eq!(scalar_sub.value.ls[1], 7323518455198527368);
  assert_eq!(scalar_sub.value.ls[2], 1848712546639099622);
  assert_eq!(scalar_sub.value.ls[3], 7093558989675447812);
}

#[tokio::test]
async fn test_scalar_mul() {
  let (_methods, _id) = get_contract_methods().await;

  let scalar_mul = _methods
    .scalar_mul(X_SCALAR, Y_SCALAR)
    .call().await.unwrap();

  // Result = 103996961415186572744923623518133659781096567566995581831564221704662704998922
  assert_eq!(scalar_mul.value.ls[0], 12652583779974793738);
  assert_eq!(scalar_mul.value.ls[1], 11510399856113002259);
  assert_eq!(scalar_mul.value.ls[2], 17112986354705659152);
  assert_eq!(scalar_mul.value.ls[3], 16567671801288747593);
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
  assert_eq!(invert_x.value.value.ls[0], 9530314696573515379);
  assert_eq!(invert_x.value.value.ls[1], 1325056620123427311);
  assert_eq!(invert_x.value.value.ls[2], 7698614219480972011);
  assert_eq!(invert_x.value.value.ls[3], 13509591698470992260);
}


#[tokio::test]
async fn test_proj_double_1() {
  let (_methods, _id) = get_contract_methods().await;

  // TEST 1
  /*
  EXPECTED from http://point-at-infinity.org/ecc/nisttv
  k = 1
  x = 6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
  y = 4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5

  k = 2
  x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978 = [9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]
  y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1 = [537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]
  */
  let g_converted_projective = affine_to_proj(&_methods, &G).await;

  let double_g = _methods
    .proj_double(g_converted_projective)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let (x_converted_test1, y_converted_test1) = proj_to_resulting_coordinates(&_methods, &double_g.value).await;

  // k = 2
  // x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978 = (reverse)[9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]
  // y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1 = (reverse)[537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]
  assert_xy(x_converted_test1, y_converted_test1, 
    [11964737083406719352, 13873736548487404341, 9967090510939364035, 9003393950442278782],
    [11386427643415524305, 13438088067519447593, 2971701507003789531, 537992211385471040]
  );

  // TEST 2
  let generator_3 = AffinePoint {
    x: FieldElement{ls: [18104864246493347180, 16629180030495074693, 14481306550553801061, 6830804848925149764]},
    y: FieldElement{ls: [11131122737810853938, 15576456008133752893, 3984285777615168236, 9742521897846374270]},
    infinity: 0,
  };
  let g3_converted_projective = affine_to_proj(&_methods, &generator_3).await;

  let double_g3 = _methods
    .proj_double(g3_converted_projective)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let (x_converted_test2, y_converted_test2) = proj_to_resulting_coordinates(&_methods, &double_g3.value).await;
  assert_xy(x_converted_test2, y_converted_test2, 
    [14317131134123807145, 165634889443579316, 10579839724117548515, 12689480371216343084],
    [18265553712439590882, 2017884693948405437, 8064836623372059513, 16743275605901433557]
  );
}


#[tokio::test]
async fn test_proj_add() {
  let (_methods, _id) = get_contract_methods().await;

  /* (this is the same as the double test, just here for easier comparison)
  EXPECTED from http://point-at-infinity.org/ecc/nisttv
  k = 2
  x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978 = (reverse) [9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]
  y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1 = (reverse) [537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]

  k = 3
  x = 5ECBE4D1A6330A44C8F7EF951D4BF165E6C6B721EFADA985FB41661BC6E7FD6C = (reverse) [6830804848925149764, 14481306550553801061, 16629180030495074693, 18104864246493347180]
  y = 8734640C4998FF7E374B06CE1A64A2ECD82AB036384FB83D9A79B127A27D5032 = (reverse) [9742521897846374270, 3984285777615168236, 15576456008133752893, 11131122737810853938]

  k = 5
  x = 51590B7A515140D2D784C85608668FDFEF8C82FD1F5BE52421554A0DC3D033ED = (reverse) [5861729009977606354, 15529757686913994719, 17261315495468721444, 2401907399252259821]
  y = E0C17DA8904A727D8AE1BF36BF8A79260D012F00D4D80888D1D0BB44FDA16DA4 = (reverse) [16195363897929790077, 10007490088856615206, 937081878087207048, 15118789854070140324]

  */
  let generator_2 = AffinePoint {
    x: FieldElement{ls: [11964737083406719352, 13873736548487404341, 9967090510939364035, 9003393950442278782]},
    y: FieldElement{ls: [11386427643415524305, 13438088067519447593, 2971701507003789531, 537992211385471040]},
    infinity: 0,
  };

  let generator_3 = AffinePoint {
    x: FieldElement{ls: [18104864246493347180, 16629180030495074693, 14481306550553801061, 6830804848925149764]},
    y: FieldElement{ls: [11131122737810853938, 15576456008133752893, 3984285777615168236, 9742521897846374270]},
    infinity: 0,
  };

  let generator_converted_2 = affine_to_proj(&_methods, &generator_2).await;
  let generator_converted_3 = affine_to_proj(&_methods, &generator_3).await;

  let g_2_add_g_3 = _methods
    .proj_add(generator_converted_2.clone(), generator_converted_3.clone())
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let (x_converted, y_converted) = proj_to_resulting_coordinates(&_methods, &g_2_add_g_3.value).await;

  assert_xy(x_converted, y_converted, 
    [2401907399252259821, 17261315495468721444, 15529757686913994719, 5861729009977606354],
    [15118789854070140324, 937081878087207048, 10007490088856615206, 16195363897929790077]
  );

}


#[tokio::test]
async fn test_proj_double_add_equality() {
  /*
  EXPECTED from http://point-at-infinity.org/ecc/nisttv

  k = 1
  x = 6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
  y = 4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5

  k = 2
  x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978 = [9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]
  y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1 = [537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]
  */

  let (_methods, _id) = get_contract_methods().await;
  let g_converted_projective = affine_to_proj(&_methods, &G).await;

  let double_g = _methods
    .proj_double(g_converted_projective.clone())
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let (x_converted_double, y_converted_double) = proj_to_resulting_coordinates(&_methods, &double_g.value).await;

  let add_g = _methods
    .proj_add(g_converted_projective.clone(), g_converted_projective.clone())
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let (x_converted_add, y_converted_add) = proj_to_resulting_coordinates(&_methods, &add_g.value).await;

  assert_eq!(x_converted_double.ls[0], x_converted_add.ls[0]);
  assert_eq!(x_converted_double.ls[1], x_converted_add.ls[1]);
  assert_eq!(x_converted_double.ls[2], x_converted_add.ls[2]);
  assert_eq!(x_converted_double.ls[3], x_converted_add.ls[3]);
  assert_eq!(y_converted_double.ls[0], y_converted_add.ls[0]);
  assert_eq!(y_converted_double.ls[1], y_converted_add.ls[1]);
  assert_eq!(y_converted_double.ls[2], y_converted_add.ls[2]);
  assert_eq!(y_converted_double.ls[3], y_converted_add.ls[3]);

}


#[tokio::test]
async fn test_proj_affine_add() {

  /*
  EXPECTED from http://point-at-infinity.org/ecc/nisttv
  k = 2
  x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978 = (reverse) [9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]
  y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1 = (reverse) [537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]
  
  k = 5
  x = 51590B7A515140D2D784C85608668FDFEF8C82FD1F5BE52421554A0DC3D033ED = (reverse)[5861729009977606354, 15529757686913994719, 17261315495468721444, 2401907399252259821]
  y = E0C17DA8904A727D8AE1BF36BF8A79260D012F00D4D80888D1D0BB44FDA16DA4 = (reverse)[16195363897929790077, 10007490088856615206, 937081878087207048, 15118789854070140324]

  k = 7
  x = 8E533B6FA0BF7B4625BB30667C01FB607EF9F8B8A80FEF5B300628703187B2A3 = (reverse)[10255606127077063494, 2718820016773528416, 9149617589957160795, 3460497826013229731]
  y = 73EB1DBDE03318366D069F83A6F5900053C73633CB041B21C55E1A86C1F400B4 = (reverse)[8352802635236186166, 7856141987785052160, 6036853421590715169, 14221833839364538548]
  */

  let (_methods, _id) = get_contract_methods().await;
  // x = 22655705336418459534985897682282060659277249245397833902983697318739469358813

  let g_2 = AffinePoint {
    x: FieldElement{ls: [11964737083406719352, 13873736548487404341, 9967090510939364035, 9003393950442278782]},
    y: FieldElement{ls: [11386427643415524305, 13438088067519447593, 2971701507003789531, 537992211385471040]},
    infinity: 0,
  };

  let g_5 = AffinePoint {
    x: FieldElement{ls: [2401907399252259821, 17261315495468721444, 15529757686913994719, 5861729009977606354]},
    y: FieldElement{ls: [15118789854070140324, 937081878087207048, 10007490088856615206, 16195363897929790077]},
    infinity: 0,
  };

  let g_2_converted_projective = affine_to_proj(&_methods, &g_2).await;

  let x_converted_g_5 = _methods
    .fe_to_montgomery(g_5.x)
    .call().await.unwrap();

  let y_converted_g_5 = _methods
    .fe_to_montgomery(g_5.y)
    .call().await.unwrap();

  let g_5_converted_affine = AffinePoint{x: x_converted_g_5.value, y: y_converted_g_5.value, infinity: 0};
  
  let g_2_mix_add_g_5 = _methods
    .proj_aff_add(g_2_converted_projective, g_5_converted_affine)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let (x_converted, y_converted) = proj_to_resulting_coordinates(&_methods, &g_2_mix_add_g_5.value).await;

  /* 
  k = 7
  x = 8E533B6FA0BF7B4625BB30667C01FB607EF9F8B8A80FEF5B300628703187B2A3 = (reverse)[10255606127077063494, 2718820016773528416, 9149617589957160795, 3460497826013229731]
  y = 73EB1DBDE03318366D069F83A6F5900053C73633CB041B21C55E1A86C1F400B4 = (reverse)[8352802635236186166, 7856141987785052160, 6036853421590715169, 14221833839364538548]
  */   
  assert_xy(x_converted, y_converted, 
    [3460497826013229731, 9149617589957160795, 2718820016773528416, 10255606127077063494],
    [14221833839364538548, 6036853421590715169, 7856141987785052160, 8352802635236186166]
  );
}

#[tokio::test]
async fn test_proj_mul_2g() {
  // TEST 1

  // 2G should give the same output as addition formulas above
  let (_methods, _id) = get_contract_methods().await;

  let g_converted_projective = affine_to_proj(&_methods, &G).await;

  //2
  let x: Scalar = Scalar{ls: [2, 0, 0, 0]};

  let g_mul_2 = _methods
    .proj_mul(g_converted_projective, x)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let (x_converted, y_converted) = proj_to_resulting_coordinates(&_methods, &g_mul_2.value).await;

  assert_xy(x_converted, y_converted, 
    [11964737083406719352, 13873736548487404341, 9967090510939364035, 9003393950442278782],
    [11386427643415524305, 13438088067519447593, 2971701507003789531, 537992211385471040]
  );

  // TEST 2

  /*
  xG with G the generator and x = 31416255128259651114300763853743354944401428675127717048158727858123196938092
  Calculate with PariGP

  p = 2^256 - 2^224 + 2^192 + 2^96 - 1;
  a = -3;
  b = 41058363725152142129326129780047268409114441015993725554835256314039467401291;
  E = ellinit([a, b], p);
  U = [Mod(48439561293906451759052585252797914202762949526041747995844080717082404635286, 115792089210356248762697446949407573530086143415290314195533631308867097853951), Mod(36134250956749795798585127919587881956611106672985015071877198253568414405109, 115792089210356248762697446949407573530086143415290314195533631308867097853951)];
  V = ellmul(E, U, 31416255128259651114300763853743354944401428675127717048158727858123196938092);
  print(V);
  */

  let g_converted_projective = affine_to_proj(&_methods, &G).await;

  //31416255128259651114300763853743354944401428675127717048158727858123196938092
  let x: Scalar = Scalar{ls: [15982738825684268908, 12861376030615125811, 9837491998535547791, 5004898192290387222]};

  let x_mul_g = _methods
    .proj_mul(g_converted_projective, x)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let (x_converted, y_converted) = proj_to_resulting_coordinates(&_methods, &x_mul_g.value).await;

  assert_xy(x_converted, y_converted, 
    [13567665731212626147, 5912556393462985994, 8580126093152460211, 7225374860094292523],
    [12585211474778133614, 8913053197310797155, 3465461371705416650, 8928676520536014294]
  );
}
