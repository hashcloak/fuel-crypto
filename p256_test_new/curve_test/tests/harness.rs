use std::hash;
use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}, /*accounts::fuel_crypto::{coins_bip32::{enc::Test, prelude::VerifyingKey}, SecretKey, PublicKey},*/ types::Bits256
};
use fuel_core_chain_config::ChainConfig;
// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/curve_test-abi.json"
));
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
      "./out/debug/curve_test.bin",
      &wallet,
      DeployConfiguration::default(),
  )
  .await
  .unwrap();
  let instance = MyContract::new(id.clone(), wallet);
  (instance.methods(), id.into())
}

const g: AffinePoint = AffinePoint {
  x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
  y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
  infinity: 0,
};

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
  let p_converted_projective = ProjectivePoint {
    x: x_converted_p.value,
    y: y_converted_p.value,
    z: p_proj.value.z,
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

async fn to_montgomery(_methods: &MyContractMethods<WalletUnlocked>, a: FieldElement) -> FieldElement {
  _methods
    .fe_to_montgomery(a)
    .call().await.unwrap().value
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