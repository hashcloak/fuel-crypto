use fuels::{prelude::*, 
  tx::{ConsensusParameters, ContractId}
};
use fuel_core_chain_config::ChainConfig;

// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/p256_tests-abi.json"
));

pub mod helpers {
  use super::*;
  
  pub async fn get_contract_methods() -> (MyContractMethods<WalletUnlocked>, ContractId) {

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

  pub fn assert_scalar(res: Scalar, expected: Scalar) {
    assert_eq!(res.ls[0], expected.ls[0]);
    assert_eq!(res.ls[1], expected.ls[1]);
    assert_eq!(res.ls[2], expected.ls[2]);
    assert_eq!(res.ls[3], expected.ls[3]);
  }

  pub async fn convert_from_montgomery(_methods: &MyContractMethods<WalletUnlocked>, p: &AffinePoint) -> (FieldElement, FieldElement) {
    let x_converted = _methods
      .fe_from_montgomery(p.clone().x)
      .call().await.unwrap();

    let y_converted = _methods
      .fe_from_montgomery(p.clone().y)
      .call().await.unwrap();

    (x_converted.value, y_converted.value)
  }
}

