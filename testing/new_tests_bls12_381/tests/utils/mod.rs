use fuels::{
  prelude::*,
  tx::{ConsensusParameters, ContractId},
};
use fuel_chain_config::{ChainConfig, CoinConfig, StateConfig};

abigen!(BlsTestContract, "out/debug/tests_bls12_381-abi.json");

pub mod helpers {
  use super::*;

  pub async fn get_contract_instance() -> (BlsTestContractMethods, Bech32ContractId) {
    let mut wallet = WalletUnlocked::new_random(None);
    let num_assets = 1;
    let coins_per_asset = 100;
    let amount_per_coin = 1_000_000_000;

    let (coins, asset_ids) = setup_multiple_assets_coins(
        wallet.address(),
        num_assets,
        coins_per_asset,
        amount_per_coin,
    );

    // Apparently have to add this, otherwise get the following error:
    // Response errors; not enough resources to fit the target
    let coin_configs = coins.clone()
        .into_iter()
        .map(|(utxo_id, coin)| CoinConfig {
            tx_id: Some(*utxo_id.tx_id()),
            output_index: Some(utxo_id.output_index() as u64),
            block_created: Some(coin.block_created),
            maturity: Some(coin.maturity),
            owner: coin.owner,
            amount: coin.amount,
            asset_id: coin.asset_id,
        })
        .collect::<Vec<_>>();

    let consensus_parameters_config = ConsensusParameters::DEFAULT.with_max_gas_per_tx(u64::MAX).with_gas_per_byte(0);
    let chain_config = ChainConfig {
      initial_state: Some(StateConfig {
        coins: Some(coin_configs),
        contracts: None,
        messages: None,
        ..StateConfig::default()}),
        chain_name: "local".into(),
        block_gas_limit: u64::MAX,
        transaction_parameters: consensus_parameters_config,
        ..Default::default()
    };

    // let consensus_parameters_config = ConsensusParameters::DEFAULT.with_max_gas_per_tx(100_000_000_000).with_gas_per_byte(0).with_gas_price_factor(1);

    // let (client, addr) = setup_test_client(coins, vec![], None, None, Some(consensus_parameters_config)).await;
    
    // let (client, _) = setup_test_client(coins,vec![],None,Some(chain_config),Some(consensus_parameters_config)).await;

    let (client, _) = setup_test_client(coins,vec![],None,Some(chain_config), None).await;
    
    let provider = Provider::new(client);
    wallet.set_provider(provider.clone());
    let id = Contract::deploy(
        "./out/debug/tests_bls12_381.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(Some(
            "./out/debug/tests_bls12_381-storage_slots.json".to_string(),
        )),
    )
    .await
    .unwrap();

    // dbg!(provider.chain_info().await?.consensus_parameters);
    let info = provider.chain_info().await;
    // dbg!(info.unwrap().consensus_parameters);
    let instance = BlsTestContract::new(id.clone(), wallet);

    (instance.methods(), id)
  }
}