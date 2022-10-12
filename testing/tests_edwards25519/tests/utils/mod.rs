use fuels::{
  prelude::*,
  tx::{ConsensusParameters, ContractId},
};

abigen!(EdwardsTestContract, "out/debug/tests_edwards25519-abi.json");

pub mod helpers {
  use super::*;

  pub async fn get_contract_methods() -> (EdwardsTestContractMethods, Bech32ContractId) {
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
    let consensus_parameters_config = ConsensusParameters::DEFAULT.with_max_gas_per_tx(1000000000);

    let (client, addr) = setup_test_client(coins, vec![], None, Some(consensus_parameters_config)).await;
    
    let provider = Provider::new(client);
    wallet.set_provider(provider.clone());

    let id = Contract::deploy(
        "./out/debug/tests_edwards25519.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::default(),
    ).await.unwrap();

    let instance = EdwardsTestContract::new(id.to_string(), wallet);
    (instance.methods(), id)
  }
}