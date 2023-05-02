use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}
};
use fuel_core_chain_config::ChainConfig;
// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/hmac_test-abi.json"
));

pub async fn get_contract_methods() -> (MyContractMethods<WalletUnlocked>, ContractId) {

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
      "./out/debug/hmac_test.bin",
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

#[tokio::test]
async fn test_hmac() {
  let (_methods, _id) = get_contract_methods().await;

  //test vector from https://www.rfc-editor.org/rfc/rfc4231#section-4
  
  // TEST CASE 1
  // Data = 4869205468657265 "Hi There"
  let data: Vec<u8> = vec![72, 105, 32, 84, 104, 101, 114, 101];

  // key = 0x0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b
  let key: [u8; 32] = [11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  let result = _methods
    .hmac(data, key)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  // HMAC-SHA-256 = b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7
  let expected = [176, 52, 76, 97, 216, 219, 56, 83, 92, 168, 175, 206, 175, 11, 241, 43, 136, 29, 194, 0, 201, 131, 61, 167, 38, 233, 55, 108, 46, 50, 207, 247];
  assert_eq!(result.value, expected);

  // TEST CASE 2
  // Data =         7768617420646f2079612077616e7420  ("what do ya want ")
  //                666f72206e6f7468696e673f          ("for nothing?")
  let data2: Vec<u8> = vec![119, 104, 97, 116, 32, 100, 111, 32, 121, 97, 32, 119, 97, 110, 116, 32, 102, 111, 114, 32, 110, 111, 116, 104, 105, 110, 103, 63];

  let key2: [u8;32] = [74, 101, 102, 101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

  let result2 = _methods
    .hmac(data2, key2)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  // HMAC-SHA-256 = 5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843
  let expected2 = [91, 220, 193, 70, 191, 96, 117, 78, 106, 4, 36, 38, 8, 149, 117, 199, 90, 0, 63, 8, 157, 39, 57, 131, 157, 236, 88, 185, 100, 236, 56, 67];
  assert_eq!(result2.value, expected2);
}

#[tokio::test]
async fn test_generate_k() {
  let (_methods, _id) = get_contract_methods().await;
  
  // https://datatracker.ietf.org/doc/html/rfc6979#appendix-A.2.5

  //TEST 1
  // message = "sample"
  let data: Vec<u8> = vec![115, 97, 109, 112, 108, 101];

  let key: [u8;32] = [201, 175, 169, 216, 69, 186, 117, 22, 107, 92, 33, 87, 103, 177, 214, 147, 78, 80, 195, 219, 54, 232, 155, 18, 123, 138, 98, 43, 18, 15, 103, 33];
  let result = _methods
    .generate_k(data, key)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  // k = A6E3C57DD01ABE90086538398355DD4C3B17AA873382B0F24D6129493D8AAD60
  let expected = Scalar{ls: [5575783208203234656, 4258059470363603186, 604951544618933580, 12025672574162353808]};
  assert_scalar(result.value, expected);

  //TEST 2
  // message = "test"
  let data2: Vec<u8> = vec![116, 101, 115, 116];

  let result2 = _methods
    .generate_k(data2, key)
    .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
    .call().await.unwrap();

  //   k = D16B6AE827F17175E040871A1C7EC3500192C4C92677336EC2537ACAEE0008E0
  let expected2 = Scalar{ls: [14002670678419966176, 113369308850500462, 16159064009222308688, 15090272521770070389]};
  assert_scalar(result2.value, expected2);
}
