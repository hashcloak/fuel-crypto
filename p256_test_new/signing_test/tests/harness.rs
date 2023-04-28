use std::hash;
use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}, /*accounts::fuel_crypto::{coins_bip32::{enc::Test, prelude::VerifyingKey}, SecretKey, PublicKey},*/ types::Bits256
};
use fuel_core_chain_config::ChainConfig;
// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/signing_test-abi.json"
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
      "./out/debug/signing_test.bin",
      &wallet,
      DeployConfiguration::default(),
  )
  .await
  .unwrap();
  let instance = MyContract::new(id.clone(), wallet);
  (instance.methods(), id.into())
}

// assert that scalar are equal
fn assert_scalar(res: Scalar, expected: Scalar) {
  assert_eq!(res.ls[0], expected.ls[0]);
  assert_eq!(res.ls[1], expected.ls[1]);
  assert_eq!(res.ls[2], expected.ls[2]);
  assert_eq!(res.ls[3], expected.ls[3]);
}
// assert that field elements are equal
fn check_fieldelement(a: FieldElement, expected_res: FieldElement) {
  assert_eq!(a.ls[0], expected_res.ls[0]);
  assert_eq!(a.ls[1], expected_res.ls[1]);
  assert_eq!(a.ls[2], expected_res.ls[2]);
  assert_eq!(a.ls[3], expected_res.ls[3]);
}

// assert that 2 signing keys are equal
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

fn assert_signature(a: Signature, b: Signature) {
  assert_scalar(a.r, b.r);
  assert_scalar(a.s, b.s);
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


#[tokio::test]
async fn test_try_sign_prehashed() {
  let (_methods, _id) = get_contract_methods().await;


  // https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/P256_SHA256.pdf

  // bytes = msg digest  = A41A41A12A799548211C410C65D8133AFDE34D28BDD542E4B680CF2899C8A8C4
  let bytes =  [164, 26, 65, 161, 42, 121, 149, 72, 33, 28, 65, 12, 101, 216, 19, 58, 253, 227, 77, 40, 189, 213, 66, 228, 182, 128, 207, 40, 153, 200, 168, 196];

  // k = random number = 7A1A7E52797FC8CAAA435D2A4DACE39158504BF204FBE19F14DBB427FAEE50AE 
  let k: Scalar = Scalar {ls: [1502992984464838830, 6363669776312295839, 12268752246160548753, 8798483714712520906]};

  // d = secret key  = C477F9F65C22CCE20657FAA5B2D1D8122336F851A508A1ED04E479C34985BF96
  let d: Scalar = Scalar{ls: [352540550500827030, 2537488469614698989, 457109476778039314, 14157058790165499106]};

  let sign = _methods
    .try_sign_prehashed(d, k, bytes)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  // Signature 
  // R: 2B42F576D07F4165FF65D1F3B1500F81E44C316F1F0B3EF57325B69ACA46104F
  // S: DC42C2122D6392CD3E3A993A89502A8198C1886FE69D262C4B329BDB6B63FAF1

  let expected_sign = Signature{r: Scalar{ls:[8297238664434815055, 16450577892209540853, 18403346296901472129, 3117323782746751333]}, s: Scalar{ls:[5418564668381985521, 11007228978462008876, 4484064855691635329, 15871461420133749453]}};

  assert_signature(sign.value, expected_sign);
}



#[tokio::test]
async fn test_try_sign_prehashed_and_check_hash_digest() {
  // This test is for checking the hash digest as well as the signature  
  // test vector taken from https://datatracker.ietf.org/doc/html/rfc6979#appendix-A.2.5

  let (_methods, _id) = get_contract_methods().await;

  // z = sha256("sample") calculated using https://emn178.github.io/online-tools/sha256.html = af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf
  let bytes = [175, 43, 219, 225, 170, 155, 110, 193, 226, 173, 225, 214, 148, 244, 31, 199, 26, 131, 29, 2, 104, 233, 137, 21, 98, 17, 61, 138, 98, 173, 209, 191];

  //k = random secret 
  let k: Scalar = Scalar {ls: [5575783208203234656, 4258059470363603186, 604951544618933580, 12025672574162353808]};
  //d = secret key 
  let x: Scalar = Scalar{ls: [8902035550577321761, 5643225679381699346, 7736094919201248915, 14533021268895757590]};

  let sign = _methods
    .try_sign_prehashed(x, k, bytes)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let expected_sign = Signature{r: Scalar{ls:[14072920526640068374, 11325576126734727569, 1243237162801856982, 17281590685529975037]}, s: Scalar{ls:[5603792056925998504, 17575579964503225350, 15291629082155065189, 17855396570382826561]}};

  assert_signature(sign.value, expected_sign);
}


#[tokio::test]
async fn test_try_sign_prehashed_with_k_generated() {
  let (_methods, _id) = get_contract_methods().await;

  //z = msg digest into scalar
  // let z: Scalar = Scalar{ls: [13150738685207554244, 18294550948687987428, 2385853424103592762, 11824835932072809800]};
  let bytes = [164, 26, 65, 161, 42, 121, 149, 72, 33, 28, 65, 12, 101, 216, 19, 58, 253, 227, 77, 40, 189, 213, 66, 228, 182, 128, 207, 40, 153, 200, 168, 196];
  let bytes_as_vec: Vec<u8> = bytes.to_vec();
  //d = secret key 
  let d: Scalar = Scalar{ls: [352540550500827030, 2537488469614698989, 457109476778039314, 14157058790165499106]};
  let d_bytes: [u8;32] = [196, 119, 249, 246, 92, 34, 204, 226, 6, 87, 250, 165, 178, 209, 216, 18, 35, 54, 248, 81, 165, 8, 161, 237, 4, 228, 121, 195, 73, 133, 191, 150];
  // pubkey
  let a = AffinePoint {
    x: FieldElement { ls:[16602909452612575158, 13855808666783054444, 14511138361138572648, 6989257567681289521] },
    y: FieldElement { ls:[8620948056189575833, 17505968991938453329, 11825020959996820580, 8720092648338668697] },
    infinity: 0
  };

  let k_generated = _methods
    .generate_k(bytes_as_vec, d_bytes)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  let sign = _methods
    .try_sign_prehashed(d, k_generated.value, bytes)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  // verification for signature on "sample"
  let verify_sample = _methods
    .verify_prehashed(a.clone(), bytes.clone(), sign.value)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  assert!(!verify_sample.value);
}


#[tokio::test]
async fn rfc6979() {
  let (_methods, _id) = get_contract_methods().await;
  
  // https://github.com/RustCrypto/elliptic-curves/blob/master/p256/src/ecdsa.rs#L99

  //TEST 1
  // message = "sample"
  let data: Vec<u8> = vec![115, 97, 109, 112, 108, 101];

  // secret key = c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721

  let sign_key = SigningKey {
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
            }
        }
    }
  };


  let result = _methods
    .try_sign(sign_key.clone(), data)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();
  
  //   Expected signature (r,s) = 
  //     (efd48b2aacb6a8fd1140dd9cd45e81d69d2c877b56aaf991c34d0ea84eaf3716,
  //      f7cb1c942d657c41d436c7a1b6e29f65f3e900dbb9aff4064dc4ab2f843acda8)

  let expected = Signature{r: Scalar{ls: [14072920526640068374, 11325576126734727569, 1243237162801856982, 17281590685529975037]}, s: Scalar{ls: [5603792056925998504, 17575579964503225350, 15291629082155065189, 17855396570382826561]}};
  assert_signature(result.value, expected);

    // TEST 2
    // msg = "test"
    let data2 = vec![116, 101, 115, 116];

    let result2 = _methods
    .try_sign(sign_key.clone(), data2)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

    // Expected signature (r, s) = 
    // (f1abb023518351cd71d881567b1ea663ed3efcf6c5132b354f28d3b0b7d38367,
    // 019f4113742a2b14bd25926b49c649155f267e60d3814b4c0cc84250e46f0083)

    let expected2 = Signature{r: Scalar{ls: [5704041684016530279, 17095379372343503669, 8203448929688135267, 17414206049896059341]}, s: Scalar{ls: [921059038994563203, 6856306437048585036, 13629460836803561749, 116883667144026900]}};
    assert_signature(result2.value, expected2);
}