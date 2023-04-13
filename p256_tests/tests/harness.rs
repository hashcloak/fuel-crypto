use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}, accounts::fuel_crypto::coins_bip32::enc::Test
};
use fuel_core_chain_config::ChainConfig;

// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/p256_tests-abi.json"
));

async fn get_contract_instance() -> (MyContract<WalletUnlocked>, ContractId) {

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

    (instance, id.into())
}


#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
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
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
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

#[tokio::test]#[ignore]
async fn test_invert_1() {
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
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
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

#[tokio::test]#[ignore]
async fn test_pow_vartime() {
    let (_instance, _id) = get_contract_instance().await;

    // 59139082389495374972926751946201499749231456944901481987554600995611674860084
    let a: FieldElement = FieldElement{ls:[8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936]};

    let montgomery_form = _instance
      .methods()
      .fe_to_montgomery(a.clone())
      .call().await.unwrap();

    let pow_vartime = _instance
      .methods()
      .pow_vartime(montgomery_form.value.clone(), [4,0,0,0])
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();

    let res_montgomery_form = _instance
      .methods()
      .fe_from_montgomery(pow_vartime.value)
      .call().await.unwrap();

    //  113097665246986401796390346304073247450823990228174533995721746947810710753685
    
    let expected: FieldElement = FieldElement{ls: [18077862325614776725, 13343880950817753919, 13722074626277446175, 18017497567293989711]};

    assert_eq!(expected.ls[0], res_montgomery_form.value.ls[0]);
    assert_eq!(expected.ls[1], res_montgomery_form.value.ls[1]);
    assert_eq!(expected.ls[2], res_montgomery_form.value.ls[2]);
    assert_eq!(expected.ls[3], res_montgomery_form.value.ls[3]);
}


#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
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

#[tokio::test]#[ignore]
async fn test_scalar_invert() {

  let (_instance, _id) = get_contract_instance().await;

  // 6024032581487054615307857608562388818842860057096001857409703737786438595508
  let x: Scalar = Scalar{ls: [10598342506117936052, 6743270311476307786, 2169871353760194456, 959683757796537189]};
  
  let invert_x = _instance
    .methods()
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
  /*
  EXPECTED from http://point-at-infinity.org/ecc/nisttv
  k = 1
  x = 6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
  y = 4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5

  k = 2
  x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978 = [9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]
  y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1 = [537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]
  */

  let (_instance, _id) = get_contract_instance().await;

  let generator = AffinePoint {
    x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
    y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
    infinity: 0,
  };

  let g_proj = _instance
    .methods()
    .affine_to_proj(generator)
    .call().await.unwrap();

// convert x, y and z to montgomery form
  let x_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().y)
    .call().await.unwrap();

  let z_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().z)
    .call().await.unwrap();

  let generator_converted = ProjectivePoint {
    x: x_converted.value,
    y: y_converted.value,
    z: z_converted.value
  };

  let double_g = _instance
    .methods()
    .proj_double(generator_converted)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

// This prints all logs in fn double (point_arithmetic.sw)
  // let log_double = double_g.get_logs().unwrap();
  // println!("{:#?}", log_double);

  let affine_result = _instance
    .methods()
    .proj_to_affine(double_g.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let x_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().y)
    .call().await.unwrap();

  // println!("proj double x{:#?}", x_converted);
  // println!("proj double y{:#?}", y_converted);

  // k = 2
  // x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978 = (reverse)[9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]
  // y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1 = (reverse)[537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]
  assert_eq!(x_converted.value.ls[0], 11964737083406719352);
  assert_eq!(x_converted.value.ls[1], 13873736548487404341);
  assert_eq!(x_converted.value.ls[2], 9967090510939364035);
  assert_eq!(x_converted.value.ls[3], 9003393950442278782);
  assert_eq!(y_converted.value.ls[0], 11386427643415524305);
  assert_eq!(y_converted.value.ls[1], 13438088067519447593);
  assert_eq!(y_converted.value.ls[2], 2971701507003789531);
  assert_eq!(y_converted.value.ls[3], 537992211385471040);
}


#[tokio::test]#[ignore]
async fn test_proj_double_2() {
  /*
  EXPECTED from http://point-at-infinity.org/ecc/nisttv
  k = 3
  x = 5ECBE4D1A6330A44C8F7EF951D4BF165E6C6B721EFADA985FB41661BC6E7FD6C = (reverse) [6830804848925149764, 14481306550553801061, 16629180030495074693, 18104864246493347180]
  y = 8734640C4998FF7E374B06CE1A64A2ECD82AB036384FB83D9A79B127A27D5032 = (reverse) [9742521897846374270, 3984285777615168236, 15576456008133752893, 11131122737810853938]

  k = 6
  x = B01A172A76A4602C92D3242CB897DDE3024C740DEBB215B4C6B0AAE93C2291A9 = (reverse) [12689480371216343084, 10579839724117548515, 165634889443579316, 14317131134123807145]
  y = E85C10743237DAD56FEC0E2DFBA703791C00F7701C7E16BDFD7C48538FC77FE2 = (reverse) [16743275605901433557, 8064836623372059513, 2017884693948405437, 18265553712439590882]
  */

  let (_instance, _id) = get_contract_instance().await;

  let generator_3 = AffinePoint {
    x: FieldElement{ls: [18104864246493347180, 16629180030495074693, 14481306550553801061, 6830804848925149764]},
    y: FieldElement{ls: [11131122737810853938, 15576456008133752893, 3984285777615168236, 9742521897846374270]},
    infinity: 0,
  };

  let g_proj = _instance
    .methods()
    .affine_to_proj(generator_3)
    .call().await.unwrap();

// convert x, y and z to montgomery form
  let x_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().y)
    .call().await.unwrap();

  let z_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().z)
    .call().await.unwrap();

  let generator_converted = ProjectivePoint {
    x: x_converted.value,
    y: y_converted.value,
    z: z_converted.value
  };

  let double_g = _instance
    .methods()
    .proj_double(generator_converted)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let affine_result = _instance
    .methods()
    .proj_to_affine(double_g.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let x_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().y)
    .call().await.unwrap();

  assert_eq!(x_converted.value.ls[0], 14317131134123807145);
  assert_eq!(x_converted.value.ls[1], 165634889443579316);
  assert_eq!(x_converted.value.ls[2], 10579839724117548515);
  assert_eq!(x_converted.value.ls[3], 12689480371216343084);
  assert_eq!(y_converted.value.ls[0], 18265553712439590882);
  assert_eq!(y_converted.value.ls[1], 2017884693948405437);
  assert_eq!(y_converted.value.ls[2], 8064836623372059513);
  assert_eq!(y_converted.value.ls[3], 16743275605901433557);
}


#[tokio::test]#[ignore]
async fn test_proj_add() {
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
  let (_instance, _id) = get_contract_instance().await;

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

  let g_proj_2 = _instance
    .methods()
    .affine_to_proj(generator_2)
    .call().await.unwrap();

// convert x, y and z to montgomery form
  let x_converted_2 = _instance
    .methods()
    .fe_to_montgomery(g_proj_2.value.clone().x)
    .call().await.unwrap();

  let y_converted_2 = _instance
    .methods()
    .fe_to_montgomery(g_proj_2.value.clone().y)
    .call().await.unwrap();

  let z_converted_2 = _instance
    .methods()
    .fe_to_montgomery(g_proj_2.value.clone().z)
    .call().await.unwrap();

  let generator_converted_2 = ProjectivePoint {
    x: x_converted_2.value,
    y: y_converted_2.value,
    z: z_converted_2.value
  };


  let g_proj_3 = _instance
    .methods()
    .affine_to_proj(generator_3)
    .call().await.unwrap();

// convert x, y and z to montgomery form
  let x_converted_3 = _instance
    .methods()
    .fe_to_montgomery(g_proj_3.value.clone().x)
    .call().await.unwrap();

  let y_converted_3 = _instance
    .methods()
    .fe_to_montgomery(g_proj_3.value.clone().y)
    .call().await.unwrap();

  let z_converted_3 = _instance
    .methods()
    .fe_to_montgomery(g_proj_3.value.clone().z)
    .call().await.unwrap();

  let generator_converted_3 = ProjectivePoint {
    x: x_converted_3.value,
    y: y_converted_3.value,
    z: z_converted_3.value
  };

  let g_2_add_g_3 = _instance
    .methods()
    .proj_add(generator_converted_2.clone(), generator_converted_3.clone())
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

// This prints all logs in fn add (point_arithmetic.sw)
  // let log_g_add_g = g_add_g.get_logs().unwrap();
  // println!("{:#?}", log_g_add_g);

  let affine_result = _instance
    .methods()
    .proj_to_affine(g_2_add_g_3.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let x_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().y)
    .call().await.unwrap();

  assert_eq!(x_converted.value.ls[0], 2401907399252259821);
  assert_eq!(x_converted.value.ls[1], 17261315495468721444);
  assert_eq!(x_converted.value.ls[2], 15529757686913994719);
  assert_eq!(x_converted.value.ls[3], 5861729009977606354);
  assert_eq!(y_converted.value.ls[0], 15118789854070140324);
  assert_eq!(y_converted.value.ls[1], 937081878087207048);
  assert_eq!(y_converted.value.ls[2], 10007490088856615206);
  assert_eq!(y_converted.value.ls[3], 16195363897929790077);

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

  let (_instance, _id) = get_contract_instance().await;

  let generator = AffinePoint {
    x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
    y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
    infinity: 0,
  };

  let g_proj = _instance
    .methods()
    .affine_to_proj(generator)
    .call().await.unwrap();

// convert x, y and z to montgomery form
  let x_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().y)
    .call().await.unwrap();

  let z_converted = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().z)
    .call().await.unwrap();

  let generator_converted = ProjectivePoint {
    x: x_converted.value,
    y: y_converted.value,
    z: z_converted.value
  };

  let double_g = _instance
    .methods()
    .proj_double(generator_converted.clone())
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  // This prints all logs in fn double (point_arithmetic.sw)
  // let log_double = double_g.get_logs().unwrap();

  let affine_result_double = _instance
    .methods()
    .proj_to_affine(double_g.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let x_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result_double.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result_double.value.clone().y)
    .call().await.unwrap();

  
  let add_g = _instance
    .methods()
    .proj_add(generator_converted.clone(), generator_converted.clone())
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();


  let affine_result_add = _instance
    .methods()
    .proj_to_affine(add_g.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();
  
  let x_converted_add = _instance
    .methods()
    .fe_from_montgomery(affine_result_add.value.clone().x)
    .call().await.unwrap();

  let y_converted_add = _instance
    .methods()
    .fe_from_montgomery(affine_result_add.value.clone().y)
    .call().await.unwrap();

  assert_eq!(x_converted.value.ls[0], x_converted_add.value.ls[0]);
  assert_eq!(x_converted.value.ls[1], x_converted_add.value.ls[1]);
  assert_eq!(x_converted.value.ls[2], x_converted_add.value.ls[2]);
  assert_eq!(x_converted.value.ls[3], x_converted_add.value.ls[3]);
  assert_eq!(y_converted.value.ls[0], y_converted_add.value.ls[0]);
  assert_eq!(y_converted.value.ls[1], y_converted_add.value.ls[1]);
  assert_eq!(y_converted.value.ls[2], y_converted_add.value.ls[2]);
  assert_eq!(y_converted.value.ls[3], y_converted_add.value.ls[3]);

}


#[tokio::test]#[ignore]
async fn test_invert_2() {
    let (_instance, _id) = get_contract_instance().await;
    // z = 91124962024886858784529270100042892326259481668464472788705119272298270350337

    let z = FieldElement { ls: [1993877568177495041, 10345888787846536528, 7746511691117935375, 14517043990409914413]};

    let montgomery_form = _instance
      .methods()
      .fe_to_montgomery(z)
      .call().await.unwrap();

    let inv_montgomery_form = _instance
      .methods()
      .invert(montgomery_form.value)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();

    let inv = _instance
      .methods()
      .fe_from_montgomery(inv_montgomery_form.value.value)
      .call().await.unwrap();

// z^(-1) = 55173594307801430653488059849270067497062709750303379613668917872479280424320
    assert_eq!(inv.value.ls[0], 4299806231468303744);
    assert_eq!(inv.value.ls[1], 8024480717984164326);
    assert_eq!(inv.value.ls[2], 11501998322799236989);
    assert_eq!(inv.value.ls[3], 8789660679986197156);
}


#[tokio::test]#[ignore]
async fn test_invert_3() {
    let (_instance, _id) = get_contract_instance().await;
    // x = 22655705336418459534985897682282060659277249245397833902983697318739469358813

    let x = FieldElement { ls: [10634854829044225757, 351552716085025155, 10645315080955407736, 3609262091244858135]};

    let montgomery_form = _instance
      .methods()
      .fe_to_montgomery(x)
      .call().await.unwrap();

    let inv_montgomery_form = _instance
      .methods()
      .invert(montgomery_form.value)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();

    let inv = _instance
      .methods()
      .fe_from_montgomery(inv_montgomery_form.value.value)
      .call().await.unwrap();

// z^(-1) = 88647100750625721153149943186404157918844683715528760041837114016635683486024
    assert_eq!(inv.value.ls[0], 12758252840858302792);
    assert_eq!(inv.value.ls[1], 2862372623786672612);
    assert_eq!(inv.value.ls[2], 7477786404377448950);
    assert_eq!(inv.value.ls[3], 14122297915116537490);
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

    let (_instance, _id) = get_contract_instance().await;
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
  
    let g_proj_2 = _instance
      .methods()
      .affine_to_proj(g_2)
      .call().await.unwrap();
  
  // convert x, y and z to montgomery form
    let x_converted_g_2 = _instance
      .methods()
      .fe_to_montgomery(g_proj_2.value.clone().x)
      .call().await.unwrap();
  
    let y_converted_g_2 = _instance
      .methods()
      .fe_to_montgomery(g_proj_2.value.clone().y)
      .call().await.unwrap();
  
    let z_converted_g_2 = _instance
      .methods()
      .fe_to_montgomery(g_proj_2.value.clone().z)
      .call().await.unwrap();
  
    let g_2_converted_projective = ProjectivePoint {
      x: x_converted_g_2.value,
      y: y_converted_g_2.value,
      z: z_converted_g_2.value
    };
  
  let x_converted_g_5 = _instance
    .methods()
    .fe_to_montgomery(g_5.x)
    .call().await.unwrap();

  let y_converted_g_5 = _instance
    .methods()
    .fe_to_montgomery(g_5.y)
    .call().await.unwrap();

  let g_5_converted_affine = AffinePoint{x: x_converted_g_5.value, y: y_converted_g_5.value, infinity: 0};
  
  
  let g_2_mix_add_g_5 = _instance
    .methods()
    .proj_aff_add(g_2_converted_projective, g_5_converted_affine)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let affine_result = _instance
    .methods()
    .proj_to_affine(g_2_mix_add_g_5.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let x_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().y)
    .call().await.unwrap();
    /* 
    k = 7
    x = 8E533B6FA0BF7B4625BB30667C01FB607EF9F8B8A80FEF5B300628703187B2A3 = (reverse)[10255606127077063494, 2718820016773528416, 9149617589957160795, 3460497826013229731]
    y = 73EB1DBDE03318366D069F83A6F5900053C73633CB041B21C55E1A86C1F400B4 = (reverse)[8352802635236186166, 7856141987785052160, 6036853421590715169, 14221833839364538548]
    */   
    assert_eq!(x_converted.value.ls[0], 3460497826013229731);
    assert_eq!(x_converted.value.ls[1], 9149617589957160795);
    assert_eq!(x_converted.value.ls[2], 2718820016773528416);
    assert_eq!(x_converted.value.ls[3], 10255606127077063494);

    assert_eq!(y_converted.value.ls[0], 14221833839364538548);
    assert_eq!(y_converted.value.ls[1], 6036853421590715169);
    assert_eq!(y_converted.value.ls[2], 7856141987785052160);
    assert_eq!(y_converted.value.ls[3], 8352802635236186166);
}

#[tokio::test] #[ignore]
async fn test_proj_mul_2g() {
  // 2G should give the same output as addition formulas above
  let (_instance, _id) = get_contract_instance().await;

  let generator = AffinePoint {
    x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
    y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
    infinity: 0,
  };

  let g_proj = _instance
    .methods()
    .affine_to_proj(generator)
    .call().await.unwrap();

// convert x, y and z to montgomery form
  let x_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().x)
    .call().await.unwrap();

  let y_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().y)
    .call().await.unwrap();

  let z_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().z)
    .call().await.unwrap();

  let g_converted_projective = ProjectivePoint {
    x: x_converted_g.value,
    y: y_converted_g.value,
    z: z_converted_g.value
  };

  //2
  let x: Scalar = Scalar{ls: [2, 0, 0, 0]};

  let g_mul_2 = _instance
    .methods()
    .proj_mul(g_converted_projective, x)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let affine_result = _instance
    .methods()
    .proj_to_affine(g_mul_2.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let x_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().y)
    .call().await.unwrap();
 
  assert_eq!(x_converted.value.ls[0], 11964737083406719352);
  assert_eq!(x_converted.value.ls[1], 13873736548487404341);
  assert_eq!(x_converted.value.ls[2], 9967090510939364035);
  assert_eq!(x_converted.value.ls[3], 9003393950442278782);
  assert_eq!(y_converted.value.ls[0], 11386427643415524305);
  assert_eq!(y_converted.value.ls[1], 13438088067519447593);
  assert_eq!(y_converted.value.ls[2], 2971701507003789531);
  assert_eq!(y_converted.value.ls[3], 537992211385471040);
}

#[tokio::test] #[ignore]
async fn test_proj_mul_xg() {
  let (_instance, _id) = get_contract_instance().await;

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
  let generator = AffinePoint {
    x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
    y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
    infinity: 0,
  };

  let g_proj = _instance
    .methods()
    .affine_to_proj(generator)
    .call().await.unwrap();

// convert x, y and z to montgomery form
  let x_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().x)
    .call().await.unwrap();

  let y_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().y)
    .call().await.unwrap();

  let z_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().z)
    .call().await.unwrap();

  let g_converted_projective = ProjectivePoint {
    x: x_converted_g.value,
    y: y_converted_g.value,
    z: z_converted_g.value
  };

  //31416255128259651114300763853743354944401428675127717048158727858123196938092
  let x: Scalar = Scalar{ls: [15982738825684268908, 12861376030615125811, 9837491998535547791, 5004898192290387222]};

  let x_mul_g = _instance
    .methods()
    .proj_mul(g_converted_projective, x)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let affine_result = _instance
    .methods()
    .proj_to_affine(x_mul_g.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let x_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().y)
    .call().await.unwrap();

  assert_eq!(x_converted.value.ls[0], 13567665731212626147);
  assert_eq!(x_converted.value.ls[1], 5912556393462985994);
  assert_eq!(x_converted.value.ls[2], 8580126093152460211);
  assert_eq!(x_converted.value.ls[3], 7225374860094292523);
  assert_eq!(y_converted.value.ls[0], 12585211474778133614);
  assert_eq!(y_converted.value.ls[1], 8913053197310797155);
  assert_eq!(y_converted.value.ls[2], 3465461371705416650);
  assert_eq!(y_converted.value.ls[3], 8928676520536014294);
}


#[tokio::test] #[ignore]
async fn test_proj_mul_xg_2() {
  let (_instance, _id) = get_contract_instance().await;

  // k = 29852220098221261079183923314599206100666902414330245206392788703677545185283
  // x = 9EACE8F4B071E677C5350B02F2BB2B384AAE89D58AA72CA97A170572E0FB222F
  // y = 1BBDAEC2430B09B93F7CB08678636CE12EAAFD58390699B5FD2F6E1188FC2A78

  let generator = AffinePoint {
    x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
    y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
    infinity: 0,
  };

  let g_proj = _instance
    .methods()
    .affine_to_proj(generator)
    .call().await.unwrap();

// convert x, y and z to montgomery form
  let x_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().x)
    .call().await.unwrap();

  let y_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().y)
    .call().await.unwrap();

  let z_converted_g = _instance
    .methods()
    .fe_to_montgomery(g_proj.value.clone().z)
    .call().await.unwrap();

  let g_converted_projective = ProjectivePoint {
    x: x_converted_g.value,
    y: y_converted_g.value,
    z: z_converted_g.value
  };

  //29852220098221261079183923314599206100666902414330245206392788703677545185283
  let x_2: Scalar = Scalar{ls: [18302637406848811011, 144097595956916351, 18158518095570798528, 4755733036782191103]};

  let x_2_mul_g = _instance
    .methods()
    .proj_mul(g_converted_projective, x_2)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let affine_result = _instance
    .methods()
    .proj_to_affine(x_2_mul_g.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

  let x_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().x)
    .call().await.unwrap();

  let y_converted = _instance
    .methods()
    .fe_from_montgomery(affine_result.value.clone().y)
    .call().await.unwrap();

  assert_eq!(x_converted.value.ls[0], 8797506388050518575);
  assert_eq!(x_converted.value.ls[1], 5381390155001572521);
  assert_eq!(x_converted.value.ls[2], 14210276306527660856);
  assert_eq!(x_converted.value.ls[3], 11433769691616765559);
  assert_eq!(y_converted.value.ls[0], 18243921637092895352);
  assert_eq!(y_converted.value.ls[1], 3362778627141179829);
  assert_eq!(y_converted.value.ls[2], 4574725413093469409);
  assert_eq!(y_converted.value.ls[3], 1998945958994053561);
}



#[tokio::test]
async fn hash_to_field() {
  let (_instance, _id) = get_contract_instance().await;

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
  u_0: FieldElement{ls: [11474617306762578673, 10051857245547636254, 14710634624562028470, 12674395089602151525]},
  u_1: FieldElement{ls: [355165799953876704, 13806404278462796839, 8925185093799233376, 4006558263084318319]},
  q0_x: FieldElement{ls: [8245103793509288776, 7845454890279372487,13192191604878931934, 5915949860614556745]}, 
  q0_y: FieldElement{ls: [3837913169617567439, 14525823833306047554, 17040321694184184214, 8741509203355699915]}, 
  q1_x: FieldElement{ls: [3674762227143116639, 6545563691401106128, 11489685293311925559, 115823331987417843]}, 
  q1_y: FieldElement{ls: [1544422570455286894, 675186360566958849, 15367579092470052704, 6384524078822414334]} 
};

  let hash2field = _instance
    .methods()
    .hash_to_field(vector1.msg)
    .call().await.unwrap();

  println!("{:#?}", hash2field.value);
  // assert_eq!(hash2field.value[0].ls[0], vector1.u_0.ls[0]);
  // assert_eq!(hash2field.value[0].ls[1], vector1.u_0.ls[1]);
  // assert_eq!(hash2field.value[0].ls[2], vector1.u_0.ls[2]);
  // assert_eq!(hash2field.value[0].ls[3], vector1.u_0.ls[3]);
  // assert_eq!(hash2field.value[1].ls[0], vector1.u_1.ls[0]);
  // assert_eq!(hash2field.value[2].ls[1], vector1.u_1.ls[1]);
  // assert_eq!(hash2field.value[1].ls[2], vector1.u_1.ls[2]);
  // assert_eq!(hash2field.value[1].ls[3], vector1.u_1.ls[3]);
}
