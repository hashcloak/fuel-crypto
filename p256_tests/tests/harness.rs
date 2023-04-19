use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}, accounts::fuel_crypto::coins_bip32::enc::Test, types::Bits256
};
use fuel_core_chain_config::ChainConfig;

// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/p256_tests-abi.json"
));

const g: AffinePoint = AffinePoint {
  x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
  y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
  infinity: 0,
};

//41624337018869194729192205381537838788846303834619688597471765238035829032504
const x_scalar: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

//112889434785065900135211481371037383646282385554418514861667765615237067913479
const y_scalar: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};
async fn get_contract_methods() -> (MyContractMethods<WalletUnlocked>, ContractId) {

  let mut wallet = WalletUnlocked::new_random(None);
  let num_assets = 1;
  let coins_per_asset = 100;
  let amount_per_coin = 100000;

  let (coins, asset_ids) = setup_multiple_assets_coins(
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

  let (client, addr) = setup_test_client(coins, vec![], None, Some(chain_config), Some(consensus_parameters_config)).await;

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

fn assert_fieldelement(a: FieldElement, expected_res: [u64; 4]) {
  assert_eq!(a.ls[0], expected_res[0]);
  assert_eq!(a.ls[1], expected_res[1]);
  assert_eq!(a.ls[2], expected_res[2]);
  assert_eq!(a.ls[3], expected_res[3]);
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
async fn test_bytes_to_scalar() {
    let (_methods, _id) = get_contract_methods().await;

// test value: 112889434785065900135211481371037383646282385554418514861667765615237067913479
    let byte_array: [u8;32] = [249, 149, 39, 226, 134, 32, 66, 219, 182, 99, 19, 244, 76, 76, 71, 182, 192, 37, 158, 22, 246, 63, 0, 1, 148, 196, 213, 187, 227, 187, 57, 7];
    let result = _methods
      .scalar_from_bytes(byte_array)
      .call().await.unwrap();

    assert_eq!(result.value.ls[0], 10719928016004921607);
    assert_eq!(result.value.ls[1], 13845646450878251009);
    assert_eq!(result.value.ls[2], 13142370077570254774);
    assert_eq!(result.value.ls[3], 17984324540840297179);
}

fn check_fieldelement(a: FieldElement, expected_res: FieldElement) {
  assert_eq!(a.ls[0], expected_res.ls[0]);
  assert_eq!(a.ls[1], expected_res.ls[1]);
  assert_eq!(a.ls[2], expected_res.ls[2]);
  assert_eq!(a.ls[3], expected_res.ls[3]);

}

fn assert_signingkey(a: SigningKey, expected_res: SigningKey) {
  // assert equality of scalar
  assert_eq!(a.secret_scalar.ls[0], expected_res.secret_scalar.ls[0]);
  assert_eq!(a.secret_scalar.ls[1], expected_res.secret_scalar.ls[1]);
  assert_eq!(a.secret_scalar.ls[2], expected_res.secret_scalar.ls[2]);
  assert_eq!(a.secret_scalar.ls[3], expected_res.secret_scalar.ls[3]);
  // assert equality of point coordinates
  check_fieldelement(a.verifying_key.inner.point.x, expected_res.verifying_key.inner.point.x);
  check_fieldelement(a.verifying_key.inner.point.y, expected_res.verifying_key.inner.point.y);

  assert_eq!(a.verifying_key.inner.point.infinity, expected_res.verifying_key.inner.point.infinity);
}

#[tokio::test]
async fn test_bytes_to_signingkey() {
    let (_methods, _id) = get_contract_methods().await;

// 0xc9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721
// 91225253027397101270059260515990221874496108017261222445699397644687913215777
// be [201, 175, 169, 216, 69, 186, 117, 22, 107, 92, 33, 87, 103, 177, 214, 147, 78, 80, 195, 219, 54, 232, 155, 18, 123, 138, 98, 43, 18, 15, 103, 33]
// value from ref impl elliptic-curves ecdsa.rs
    let byte_array: [u8;32] = [201, 175, 169, 216, 69, 186, 117, 22, 107, 92, 33, 87, 103, 177, 214, 147, 78, 80, 195, 219, 54, 232, 155, 18, 123, 138, 98, 43, 18, 15, 103, 33];
    let result = _methods
      .signingkey_from_bytes(byte_array)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    // Expected value from reference repo elliptic-curves
    let expected = SigningKey {
      secret_scalar: Scalar {
          ls: [
              8902035550577321761,
              5643225679381699346,
              7736094919201248915,
              14533021268895757590,
          ],
      }, 
      verifying_key: VerifyingKey {
          inner: PublicKey {
              point: AffinePoint {
                  x: FieldElement {
                      ls: [
                          854155409699656515,
                          3316163128507520414,
                          4813278211787846225,
                          17918716845990570650,
                      ],
                  },
                  y: FieldElement {
                      ls: [
                          2963932528407990331,
                          8170061389371059402,
                          12842851857548027727,
                          2638587248444126887,
                      ],
                  },
                  infinity: 0,
              },
          },
      }
    };

    assert_signingkey(result.value, expected);
}

#[tokio::test] #[ignore]
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

#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
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


#[tokio::test]#[ignore]
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


#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
async fn test_scalar_sub() {
  let (_methods, _id) = get_contract_methods().await;

  let scalar_sub = _methods
    .scalar_sub(x_scalar, y_scalar)
    .call().await.unwrap();

  // Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
  assert_eq!(scalar_sub.value.ls[0], 1678027027253883522);
  assert_eq!(scalar_sub.value.ls[1], 7323518455198527368);
  assert_eq!(scalar_sub.value.ls[2], 1848712546639099622);
  assert_eq!(scalar_sub.value.ls[3], 7093558989675447812);
}

#[tokio::test]#[ignore]
async fn test_scalar_mul() {
  let (_methods, _id) = get_contract_methods().await;

  let scalar_mul = _methods
    .scalar_mul(x_scalar, y_scalar)
    .call().await.unwrap();

  // Result = 103996961415186572744923623518133659781096567566995581831564221704662704998922
  assert_eq!(scalar_mul.value.ls[0], 12652583779974793738);
  assert_eq!(scalar_mul.value.ls[1], 11510399856113002259);
  assert_eq!(scalar_mul.value.ls[2], 17112986354705659152);
  assert_eq!(scalar_mul.value.ls[3], 16567671801288747593);
}

#[tokio::test]#[ignore]
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


#[tokio::test]#[ignore]
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
  let g_converted_projective = affine_to_proj(&_methods, &g).await;

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


#[tokio::test]#[ignore]
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


#[tokio::test]#[ignore]
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
  let g_converted_projective = affine_to_proj(&_methods, &g).await;

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


#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
async fn test_proj_mul_2g() {
  // TEST 1

  // 2G should give the same output as addition formulas above
  let (_methods, _id) = get_contract_methods().await;

  let g_converted_projective = affine_to_proj(&_methods, &g).await;

  //2
  let x: Scalar = Scalar{ls: [2, 0, 0, 0]};

  let g_mul_2 = _methods
    .proj_mul(g_converted_projective.clone(), x)
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

  //31416255128259651114300763853743354944401428675127717048158727858123196938092
  let x: Scalar = Scalar{ls: [15982738825684268908, 12861376030615125811, 9837491998535547791, 5004898192290387222]};

  let x_mul_g = _methods
    .proj_mul(g_converted_projective.clone(), x)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let (x_converted, y_converted) = proj_to_resulting_coordinates(&_methods, &x_mul_g.value).await;

  assert_xy(x_converted, y_converted, 
    [13567665731212626147, 5912556393462985994, 8580126093152460211, 7225374860094292523],
    [12585211474778133614, 8913053197310797155, 3465461371705416650, 8928676520536014294]
  );

  // TEST 3
  //29852220098221261079183923314599206100666902414330245206392788703677545185283
  let x_2: Scalar = Scalar{ls: [18302637406848811011, 144097595956916351, 18158518095570798528, 4755733036782191103]};

  let x_2_mul_g = _methods
    .proj_mul(g_converted_projective.clone(), x_2)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let (x_converted_x2g, y_converted_x2g) = proj_to_resulting_coordinates(&_methods, &x_2_mul_g.value).await;

  assert_xy(x_converted_x2g, y_converted_x2g, 
    [8797506388050518575, 5381390155001572521, 14210276306527660856, 11433769691616765559],
    [18243921637092895352, 3362778627141179829, 4574725413093469409, 1998945958994053561]
  );
}

#[tokio::test]#[ignore]
async fn test_from_okm () {

  let (_methods, _id) = get_contract_methods().await;

  // random(2^384)
  // 29574121323020303933831581169207951122829468626121072655439219863093377468360436174282205068642494412975233236534840
  // big-endian [13845646450878251009, 10719928016004921607, 6631139461101160670, 14991082624209354397, 7557322358563246340, 13282407956253574712]

  // let data: [u64;6] = [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670, 10719928016004921607, 13845646450878251009];
  let data: [u8; 48] = [56, 6, 81, 186, 169, 151, 84, 184, 4, 145, 71, 11, 165, 0, 225, 104, 157, 126, 135, 118, 56, 6, 11, 208, 222, 136, 2, 227, 52, 138, 6, 92, 7, 57, 187, 227, 187, 213, 196, 148, 1, 0, 63, 246, 22, 158, 37, 192];

  let result = _methods
    .from_okm(data)
    .call().await.unwrap();

  // correct value according to reference repo:
  // 0xBC5BDAC732B6B32C0C76A01A486F2AAF0CE104CE7EE79FB2D9FAD9EE57DEF6E7
  // equals: 85197108567622674053253976229903765397140825897163024844039591489851386427111
  // digits [13572682451095302956, 898081210451831471, 928028283153915826, 15707106268107699943]

  assert_fieldelement(result.value, [15707106268107699943, 928028283153915826, 898081210451831471, 13572682451095302956]);
}

#[tokio::test]#[ignore]
async fn test_expand_msg () {
  let (_methods, _id) = get_contract_methods().await;

  let data = vec![97,98,99];
  let result = _methods
    .expand_message(data)
    .call().await.unwrap();

  let expected = Bits256 ([216, 204, 171, 35, 181, 152, 92, 206, 168, 101, 198, 201, 123, 110, 91, 131, 80, 231, 148, 230, 3, 180, 185, 121, 2, 245, 58, 138, 13, 96, 86, 21]);
  assert_eq!(result.value.0, expected);

  // second message
  // msg: b"abcdef0123456789",
  // uniform_bytes: &hex!("eff31487c770a893cfb36f912fbfcbff40d5661771ca4b2cb4eafe524333f5c1"),
  let data2 = vec![97, 98, 99, 100, 101, 102, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57];
  let result2 = _methods
    .expand_message(data2)
    .call().await.unwrap();

  // This test only works with DST equal to: "QUUX-V01-CS02-with-expander-SHA256-128"
  // let DST_prime: [u8; 39] = [81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116, 104, 45, 101, 120, 112, 97, 110, 100, 101, 114, 45, 83, 72, 65, 50, 53, 54, 45, 49, 50, 56, 38];
  
  // let expected2 = Bits256([239, 243, 20, 135, 199, 112, 168, 147, 207, 179, 111, 145, 47, 191, 203, 255, 64, 213, 102, 23, 113, 202, 75, 44, 180, 234, 254, 82, 67, 51, 245, 193]);
  // assert_eq!(result2.value.0, expected2);

}

// TODO hash_to_field has to be debugged and fixed
#[tokio::test]
async fn test_hash_to_field() {
  let (_methods, _id) = get_contract_methods().await;

  struct TestVector {
    msg: Vec<u8>,
    p_x: FieldElement,
    p_y: FieldElement,
    u_0: FieldElement,
    u_1: FieldElement,
    q0_x: FieldElement,
    q0_y: FieldElement,
    q1_x: FieldElement,
    q1_y: FieldElement,
  }

// TestVector {
//   msg: b"abc",
//   p_x: hex!("0bb8b87485551aa43ed54f009230450b492fead5f1cc91658775dac4a3388a0f"),
//   p_y: hex!("5c41b3d0731a27a7b14bc0bf0ccded2d8751f83493404c84a88e71ffd424212e"),
//   u_0: hex!("afe47f2ea2b10465cc26ac403194dfb68b7f5ee865cda61e9f3e07a537220af1"),
//   u_1: hex!("379a27833b0bfe6f7bdca08e1e83c760bf9a338ab335542704edcd69ce9e46e0"),
//   q0_x: hex!("5219ad0ddef3cc49b714145e91b2f7de6ce0a7a7dc7406c7726c7e373c58cb48"),
//   q0_y: hex!("7950144e52d30acbec7b624c203b1996c99617d0b61c2442354301b191d93ecf"),
//   q1_x: hex!("019b7cb4efcfeaf39f738fe638e31d375ad6837f58a852d032ff60c69ee3875f"),
//   q1_y: hex!("589a62d2b22357fed5449bc38065b760095ebe6aeac84b01156ee4252715446e"),


  let vector1: TestVector = TestVector { 
    msg: vec![97,98,99], 
    p_x: FieldElement{ls: [9760948305482254863, 5273691893279789413, 4527611864262133003, 844627740724632228]},
    p_y: FieldElement{ls: [12145770588654543150, 9750847572926286980, 12775516694752652589, 6647792232841226151]},
    // first fieldelement should be:
    u_0: FieldElement{ls: [11474617306762578673, 10051857245547636254, 14710634624562028470, 12674395089602151525]},
    // second:
    u_1: FieldElement{ls: [355165799953876704, 13806404278462796839, 8925185093799233376, 4006558263084318319]},
    q0_x: FieldElement{ls: [8245103793509288776, 7845454890279372487,13192191604878931934, 5915949860614556745]}, 
    q0_y: FieldElement{ls: [3837913169617567439, 14525823833306047554, 17040321694184184214, 8741509203355699915]}, 
    q1_x: FieldElement{ls: [3674762227143116639, 6545563691401106128, 11489685293311925559, 115823331987417843]}, 
    q1_y: FieldElement{ls: [1544422570455286894, 675186360566958849, 15367579092470052704, 6384524078822414334]} 
  };

  
  let hash2field = _methods
    .hash_to_field(vector1.msg)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let logs = hash2field.get_logs().unwrap();
  println!("{:#?}", logs);
  /*
[
    "Bits256([74, 151, 151, 159, 152, 135, 73, 68, 128, 177, 121, 235, 244, 54, 25, 242, 43, 215, 199, 145, 250, 236, 109, 31, 93, 198, 191, 106, 247, 218, 120, 34])",
    "Bits256([239, 145, 238, 93, 213, 160, 16, 174, 98, 67, 178, 255, 92, 45, 3, 185, 170, 44, 40, 226, 162, 105, 211, 36, 51, 255, 166, 248, 152, 179, 188, 215])",
    "Bits256([65, 241, 157, 161, 18, 14, 79, 142, 179, 18, 235, 177, 114, 43, 158, 145, 41, 51, 77, 35, 177, 218, 196, 67, 28, 184, 16, 176, 90, 8, 177, 144])",
    "[74, 151, 151, 159, 152, 135, 73, 68, 128, 177, 121, 235, 244, 54, 25, 242, 43, 215, 199, 145, 250, 236, 109, 31, 93, 198, 191, 106, 247, 218, 120, 34, 239, 145, 238, 93, 213, 160, 16, 174, 98, 67, 178, 255, 92, 45, 3, 185]",
    "[170, 44, 40, 226, 162, 105, 211, 36, 51, 255, 166, 248, 152, 179, 188, 215, 65, 241, 157, 161, 18, 14, 79, 142, 179, 18, 235, 177, 114, 43, 158, 145, 41, 51, 77, 35, 177, 218, 196, 67, 28, 184, 16, 176, 90, 8, 177, 144]",
]
[
    FieldElement {
        ls: [
            1728813152584433580,
            1780581177103270634,
            8480265857755027571,
            1974814188125222243,
        ],
    },
    FieldElement {
        ls: [
            2011117570769239119,
            139850257455497610,
            3924352572349401321,
            8445929672427632768,
        ],
    },
]
  */

  println!("{:#?}", hash2field.value);
  assert_eq!(hash2field.value[0].ls[0], vector1.u_0.ls[0]);
  assert_eq!(hash2field.value[0].ls[1], vector1.u_0.ls[1]);
  assert_eq!(hash2field.value[0].ls[2], vector1.u_0.ls[2]);
  assert_eq!(hash2field.value[0].ls[3], vector1.u_0.ls[3]);
  assert_eq!(hash2field.value[1].ls[0], vector1.u_1.ls[0]);
  assert_eq!(hash2field.value[1].ls[1], vector1.u_1.ls[1]);
  assert_eq!(hash2field.value[1].ls[2], vector1.u_1.ls[2]);
  assert_eq!(hash2field.value[1].ls[3], vector1.u_1.ls[3]);
}
