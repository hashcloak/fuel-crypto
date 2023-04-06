use fuels::{prelude::*, tx::ContractId};

// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/p256_tests-abi.json"
));

async fn get_contract_instance() -> (MyContract<WalletUnlocked>, ContractId) {
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

// To run the test, uncomment the fe_to_montgomery and fe_from_montgomery lines in pow_vartime
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

    //  113097665246986401796390346304073247450823990228174533995721746947810710753685
    
    let expected: FieldElement = FieldElement{ls: [18077862325614776725, 13343880950817753919, 13722074626277446175, 18017497567293989711]};

    assert_eq!(expected.ls[0], pow_vartime.value.ls[0]);
    assert_eq!(expected.ls[1], pow_vartime.value.ls[1]);
    assert_eq!(expected.ls[2], pow_vartime.value.ls[2]);
    assert_eq!(expected.ls[3], pow_vartime.value.ls[3]);
}

/*
#[tokio::test] 
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

#[tokio::test]
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

#[tokio::test]
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

#[tokio::test]
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

*/

#[tokio::test]
async fn test_proj_double_P() {
  /*
  EXPECTED from http://point-at-infinity.org/ecc/nisttv
  k = 1
x = 6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
y = 4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5

k = 2
x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978
 [9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]


y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1
[537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]

  Using GP Pari to test. Confirms 2G above.

p = 2^256 - 2^224 + 2^192 + 2^96 - 1;
a = -3;
b = 41058363725152142129326129780047268409114441015993725554835256314039467401291;
E = ellinit([a, b], p);
U = [Mod(48439561293906451759052585252797914202762949526041747995844080717082404635286, 115792089210356248762697446949407573530086143415290314195533631308867097853951), Mod(36134250956749795798585127919587881956611106672985015071877198253568414405109, 115792089210356248762697446949407573530086143415290314195533631308867097853951)];
V = elladd(E, U, U);
print(V);

[Mod(56515219790691171413109057904011688695424810155802929973526481321309856242040, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 
[9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]

Mod(3377031843712258259223711451491452598088675519751548567112458094635497583569, 115792089210356248762697446949407573530086143415290314195533631308867097853951)]
[537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]

  */

/*
printed in fn double
[
    "FieldElement { ls: [18099821236414877728, 5092245993689235377, 7041010286886820137, 7284524506192033442] }",
    "FieldElement { ls: [7214726750803115408, 4252855811016884965, 10487075823600809682, 5289816126658556724] }",
    "FieldElement { ls: [12884901888, 8589934590, 18446744060824649730, 18446744065119617027] }",
    "FieldElement { ls: [7166778605029299033, 18155693884340548730, 1703741392458136724, 10205427827588253002] }",
    "FieldElement { ls: [4568643859538882287, 4322823196193874234, 17967445894621907278, 13748229301322843188] }",
    "FieldElement { ls: [11976420801272279623, 13850645975253386349, 9421061668449225141, 8193831690629627622] }",
    "FieldElement { ls: [17482518330107287254, 4658449774046088520, 9816440931638123809, 6134751002474298546] }",
    "FieldElement { ls: [8178952494405379769, 18041150114975315356, 670634891962685872, 17601809193598842499] }",
    "FieldElement { ls: [6250501007200851046, 8911305585062973486, 1856772681529381875, 11424567129132855271] }",
    "FieldElement { ls: [1452546935957033606, 1238469699646880663, 16485496329063198609, 10095750817030792521] }",
    "FieldElement { ls: [5693741130416990544, 16710687439042473880, 17117259295456214390, 2407560174300564014] }",
    "FieldElement { ls: [38654705666, 17179869178, 18446744035054845958, 18446744056529682441] }",
    "FieldElement { ls: [4352398218899180863, 12878295711091990713, 7193519790225008994, 18375841270726419469] }",
    "FieldElement { ls: [13057194656697542591, 1741398977266934315, 3133815296965475368, 18234035673350089766] }",
    "FieldElement { ls: [17405975523170824286, 15276737963887836955, 2676286825605614453, 3406829462046417885] }",
*/

  // [7716867327612699207, 17923454489921339634, 8575836109218198432, 17627433388654248598]
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

  println!("proj double x{:#?}", x_converted);
  println!("proj double y{:#?}", y_converted);
/*

proj double xFuelCallResponse {
    value: FieldElement {
        ls: [
            1041009870486039829,
            7586539782181911359,
            5014257758766121731,
            9511758770215838239,
        ],
    },


proj double yFuelCallResponse {
    value: FieldElement {
        ls: [
            9974546761783701891,
            3034566683288325207,
            13539152682327028406,
            16909859332478720903,
        ],
    },
*/
}


#[tokio::test]#[ignore]
async fn test_proj_add_P() {
  /* (this is the same as the double test, just here for easier comparison)
  EXPECTED from http://point-at-infinity.org/ecc/nisttv
  k = 1
x = 6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
y = 4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5

k = 2
x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978
 [9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]


y = 07775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1
[537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]

  Using GP Pari to test. Confirms 2G above.

p = 2^256 - 2^224 + 2^192 + 2^96 - 1;
a = -3;
b = 41058363725152142129326129780047268409114441015993725554835256314039467401291;
E = ellinit([a, b], p);
U = [Mod(48439561293906451759052585252797914202762949526041747995844080717082404635286, 115792089210356248762697446949407573530086143415290314195533631308867097853951), Mod(36134250956749795798585127919587881956611106672985015071877198253568414405109, 115792089210356248762697446949407573530086143415290314195533631308867097853951)];
V = elladd(E, U, U);
print(V);

[Mod(56515219790691171413109057904011688695424810155802929973526481321309856242040, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 
[9003393950442278782, 9967090510939364035, 13873736548487404341, 11964737083406719352]

Mod(3377031843712258259223711451491452598088675519751548567112458094635497583569, 115792089210356248762697446949407573530086143415290314195533631308867097853951)]
[537992211385471040, 2971701507003789531, 13438088067519447593, 11386427643415524305]

  */

  // [7716867327612699207, 17923454489921339634, 8575836109218198432, 17627433388654248598]
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

  let g_add_g = _instance
    .methods()
    .proj_add(generator_converted.clone(), generator_converted.clone())
    .tx_params(TxParameters::default().set_gas_limit(100_000_000))
    .call().await.unwrap();

// This prints all logs in fn add (point_arithmetic.sw)
  let log_g_add_g = g_add_g.get_logs().unwrap();
  println!("{:#?}", log_g_add_g);

  let affine_result = _instance
    .methods()
    .proj_to_affine(g_add_g.value)
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

  println!("g add g x{:#?}", x_converted);
  println!("g add g y{:#?}", y_converted);
/*

g add g xFuelCallResponse {
    value: FieldElement {
        ls: [
            13414369097469890704,
            9541241602842068969,
            18424207313872341752,
            11681539436332508528,
        ],
    },

g add g yFuelCallResponse {
    value: FieldElement {
        ls: [
            1470025092409025755,
            15565308325270801120,
            4239002935273656715,
            1808729045065017054,
        ],
    },

*/
}
