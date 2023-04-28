use std::hash;
use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}, /*accounts::fuel_crypto::{coins_bip32::{enc::Test, prelude::VerifyingKey}, SecretKey, PublicKey},*/ types::Bits256
};
use fuel_core_chain_config::ChainConfig;
// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/verifying_test-abi.json"
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
      "./out/debug/verfiying_test.bin",
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

pub fn assert_xy(x: FieldElement, y: FieldElement, x_res: [u64; 4], y_res: [u64;4]) {
  assert_eq!(x.ls[0], x_res[0]);
  assert_eq!(x.ls[1], x_res[1]);
  assert_eq!(x.ls[2], x_res[2]);
  assert_eq!(x.ls[3], x_res[3]);
  assert_eq!(y.ls[0], y_res[0]);
  assert_eq!(y.ls[1], y_res[1]);
  assert_eq!(y.ls[2], y_res[2]);
  assert_eq!(y.ls[3], y_res[3]);
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
/*
running 1 test
test tests_verification::success::test_verify_prehash_with_pubkey has been running for over 60 seconds
test tests_verification::success::test_verify_prehash_with_pubkey ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 774.50s
*/
    #[tokio::test]//#[ignore] // WORKS
    async fn test_verify_prehash_with_pubkey() {
        // test vectors taken from https://datatracker.ietf.org/doc/html/rfc6979#appendix-A.2.5

        let (_methods, _id) = get_contract_methods().await;

        // With SHA-256, message = "sample":
        // sha256 of "sample" af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf
        let hash1 = [
            175, 43, 219, 225, 170, 155, 110, 193, 226, 173, 225, 214, 148, 244, 31, 199, 26, 131,
            29, 2, 104, 233, 137, 21, 98, 17, 61, 138, 98, 173, 209, 191,
        ];
        let r1 = Scalar {
            ls: [
                14072920526640068374,
                11325576126734727569,
                1243237162801856982,
                17281590685529975037,
            ],
        };
        let s1 = Scalar {
            ls: [
                5603792056925998504,
                17575579964503225350,
                15291629082155065189,
                17855396570382826561,
            ],
        };

        // With SHA-256, message = "test":
        // sha256 of "test" 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
        let hash2 = [
            159, 134, 208, 129, 136, 76, 125, 101, 154, 47, 234, 160, 197, 90, 208, 21, 163, 191,
            79, 27, 43, 11, 130, 44, 209, 93, 108, 21, 176, 240, 10, 8,
        ];
        let r2 = Scalar {
            ls: [
                5704041684016530279,
                17095379372343503669,
                8203448929688135267,
                17414206049896059341,
            ],
        };
        let s2 = Scalar {
            ls: [
                921059038994563203,
                6856306437048585036,
                13629460836803561749,
                116883667144026900,
            ],
        };

        // pubkey
        let a = AffinePoint {
            x: FieldElement {
                ls: [
                    16602909452612575158,
                    13855808666783054444,
                    14511138361138572648,
                    6989257567681289521,
                ],
            },
            y: FieldElement {
                ls: [
                    8620948056189575833,
                    17505968991938453329,
                    11825020959996820580,
                    8720092648338668697,
                ],
            },
            infinity: 0,
        };

        let vk = VerifyingKey {
            inner: PublicKey { point: a },
        };
        let sign1 = Signature { r: r1, s: s1 };
        // verification for signature on "sample"
        let verify1 = _methods
            .verify_prehash_with_pubkey(vk.clone(), hash1.clone(), sign1)
            .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
            .call()
            .await
            .unwrap();

        assert!(verify1.value);

        let sign2 = Signature {
            r: r2.clone(),
            s: s2.clone(),
        };
        // verification for signature on "test"
        let verify2 = _methods
            .verify_prehash_with_pubkey(vk.clone(), hash2, sign2.clone())
            .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
            .call()
            .await
            .unwrap();

        assert!(verify2.value);

        // Check for a failing verification
        let verify_failed = _methods
            .verify_prehash_with_pubkey(vk.clone(), hash1.clone(), sign2.clone()) // hash1, with signature for hash2 should fail
            .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
            .call()
            .await
            .unwrap();

        assert!(!verify_failed.value);
    }

    #[tokio::test]//#[ignore]
    async fn test_generate_verifyingkey() {
      // test vectors taken from https://datatracker.ietf.org/doc/html/rfc6979#appendix-A.2.5

      let (_methods, _id) = get_contract_methods().await;

      // private scalar C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721
      let x = Scalar { ls: [8902035550577321761, 5643225679381699346, 7736094919201248915, 14533021268895757590]};

      // verification for signature on "sample"
      let get_verifying_key = _methods
        .from_secret_scalar(x)
        .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
        .call().await.unwrap();

      // convert the coordinates to compare them with the value from the doc
      let converted_coordinates = convert_from_montgomery(&_methods, &get_verifying_key.value.inner.point).await;

      // should be equal to the pubkey given in the doc
      assert_xy(converted_coordinates.0, converted_coordinates.1, [16602909452612575158, 13855808666783054444, 14511138361138572648, 6989257567681289521], [8620948056189575833, 17505968991938453329, 11825020959996820580, 8720092648338668697]);
    }

/*
ERROR
This test cannot be compiled. Will give:

thread 'main' panicked at 'Unable to offset into the data section more than 2^12 bits. Unsupported data section length.', sway-core/src/asm_lang/allocated_ops.rs:608:19
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace 
*/
    // #[tokio::test]#[ignore]
    // async fn test_verify_prehash_with_secret_scalar() {
    //   // test vectors taken from https://datatracker.ietf.org/doc/html/rfc6979#appendix-A.2.5

    //   let (_methods, _id) = get_contract_methods().await;

    //   // private scalar C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721
    //   let x = Scalar { ls: [8902035550577321761, 5643225679381699346, 7736094919201248915, 14533021268895757590]};

    //   // If test passes, remove this commented code
    //   // // verification for signature on "sample"
    //   // let verifying_key = _methods
    //   //   .from_secret_scalar(x)
    //   //   .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    //   //   .call().await.unwrap();

    //   // With SHA-256, message = "sample":
    //   // sha256 of "sample" af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf
    //   let hash1 = [175, 43, 219, 225, 170, 155, 110, 193, 226, 173, 225, 214, 148, 244, 31, 199, 26, 131, 29, 2, 104, 233, 137, 21, 98, 17, 61, 138, 98, 173, 209, 191];
    //   let r1 = Scalar{ls:[14072920526640068374, 11325576126734727569, 1243237162801856982, 17281590685529975037]};
    //   let s1 = Scalar{ls:[5603792056925998504, 17575579964503225350, 15291629082155065189, 17855396570382826561]};
    //   let signature1 = Signature { r: r1, s: s1};

    //   // With SHA-256, message = "test":
    //   // signature of that hashed message
    //   let r2 = Scalar{ls: [5704041684016530279, 17095379372343503669, 8203448929688135267, 17414206049896059341]};
    //   let s2 = Scalar{ls: [921059038994563203, 6856306437048585036, 13629460836803561749, 116883667144026900]};
    //   let signature2 = Signature { r: r2, s: s2};

    //   // verification for signature on "sample"
    //   let verify1 = _methods
    //     .verify_prehash_with_secret_scalar(x, hash1.clone(), signature1)
    //     .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    //     .call().await.unwrap();

    //   assert!(verify1.value);

    //   // Check for a failing verification
    //   let verify_failed = _methods
    //     .verify_prehash_with_secret_scalar(x, hash1.clone(), signature2)
    //     .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    //     .call().await.unwrap();

    //   assert!(!verify_failed.value);
    // }