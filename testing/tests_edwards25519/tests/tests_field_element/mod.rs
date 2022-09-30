use fuels::{
    prelude::*,
    tx::{ConsensusParameters, ContractId},
};

abigen!(EdwardsTestContract, "out/debug/tests_edwards25519-abi.json");

async fn get_contract_instance() -> (EdwardsTestContractMethods, Bech32ContractId) {
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
const ZERO: Element = Element{ l_0: 0, l_1: 0, l_2: 0, l_3: 0, l_4: 0 };
const ONE: Element = Element{ l_0: 1, l_1: 0, l_2: 0, l_3: 0, l_4: 0 };

#[tokio::test]
async fn test_add_to_0() {
    let a = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };
    let expected_res = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add(ZERO, a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}


#[tokio::test]
async fn test_add_0() {
    let a = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };
    let expected_res = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add(a, ZERO)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_add_a_to_b() {
    let a = Element{ 
        l_0: 2251799813685247,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let b = Element{ 
        l_0: 8191, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };
    let expected_res = Element{ 
        l_0: 8209, 
        l_1: 225179, 
        l_2: 155647,
        l_3: 81918191,
        l_4: 85247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_add_a_to_a() {
    let a = Element{ 
        l_0: 2251799813685228,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let a_again = Element{ 
        l_0: 2251799813685228,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let expected_res = Element{ 
        l_0: 2251799813685227, 
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add(a, a_again)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn tests_multiply64() {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    // let ab = 98471291840283423519614919326553453204;

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.multiply64(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res.lower == 5960040633016627860);
    assert!(res.upper == 5338139427034470684);
}

#[tokio::test]
async fn test_add_multiply64() {
    let a = 496009164746885;
    let b = 24764068336973246;
    let r: U128 = U128{upper: 2516888776885, lower: 8614063320694916486};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_multiply64(r, a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res.lower == 10881738262824685884);
    assert!(res.upper == 3182762646142);
}

#[tokio::test]
async fn test_add_multiply64_2() {
    let a = 24764068336973246;
    let b = 137209507300112;
    let r: U128 = U128{upper: 95365234715, lower: 16956620749643293576};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_multiply64(r, a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res.lower == 18148778710141221224);
    assert!(res.upper == 279563898809);
}

#[tokio::test]
async fn test_carry_propagate_1() {
    let a = Element{ 
        l_0: u64::MAX,
        l_1: u64::MAX,
        l_2: u64::MAX,
        l_3: u64::MAX,
        l_4: u64::MAX
    };
    let expected_res = Element{ 
        l_0: 2251799813685247 + (19*8191), 
        l_1: 2251799813685247 + 8191, 
        l_2: 2251799813685247 + 8191,
        l_3: 2251799813685247 + 8191,
        l_4: 2251799813685247 + 8191
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.carry_propagate(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_carry_propagate_2() {
    let a = Element{ 
        l_0: 2251799813685250,
        l_1: 0,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };
    let expected_res = Element{ 
        l_0: 2,
        l_1: 1,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.carry_propagate(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_reduce() {
    let a = Element{ 
        l_0: 2251799813685250,
        l_1: 0,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };
    let expected_res = Element{ 
        l_0: 2,
        l_1: 1,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.reduce(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_reduce_2() {
    let a = Element{ 
        l_0: 2251799813685250,
        l_1: 2251799813685250,
        l_2: 2251799813685250,
        l_3: 2251799813685250,
        l_4: 2251799813685250
    };
    let expected_res = Element{ 
        l_0: 21,
        l_1: 3,
        l_2: 3,
        l_3: 3,
        l_4: 3
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.reduce(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_reduce_3() {
    let a = Element{ 
        l_0: u64::MAX,
        l_1: u64::MAX,
        l_2: u64::MAX,
        l_3: u64::MAX,
        l_4: u64::MAX
    };
    let expected_res = Element{ 
        l_0: 155647,
        l_1: 8191,
        l_2: 8191,
        l_3: 8191,
        l_4: 8191
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.reduce(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_reduce_4() {
    let a = Element{ 
        l_0: 4503599627370494,
        l_1: 4503599627370494,
        l_2: 4503599627370494,
        l_3: 4503599627370494,
        l_4: 4503599627370494
    };
    let expected_res = Element{ 
        l_0: 36,
        l_1: 0,
        l_2: 0,
        l_3: 0,
        l_4: 0
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.reduce(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_shift_right_by51_random() {
    let a: U128 = U128{upper: 16, lower: 0};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.shift_right_by51(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == 131072);
}

#[tokio::test]
async fn test_shift_right_by51_random_2() {
    let a: U128 = U128{upper: 349323232, lower: 456464};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.shift_right_by51(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == 2861655916544);
}

#[tokio::test]
async fn test_shift_right_by51_random_3() {
    let a: U128 = U128{upper: 349323232, lower: 18446744073709551615};

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.shift_right_by51(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == 2861655924735);
}

#[tokio::test]
async fn test_mult_by_0() {
    let a = Element{ 
        l_0: 2251799813685247,
        l_1: 5,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.scalar_mult(a, 0)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == ZERO);
}

#[tokio::test]
async fn test_mult_by_1() {
    let a = Element{ 
        l_0: 79611,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 555555333333222,
        l_4: 2251799813685247
    };
    let expected_res = Element{ 
        l_0: 79611,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 555555333333222,
        l_4: 2251799813685247
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.scalar_mult(a, 1)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_mult_by_2() {
    let a = Element{ 
        l_0: 79611,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 555555333333222,
        l_4: 2251799813685247
    };
    let expected_res = Element{ 
        l_0: 159241,
        l_1: 2251799813685246,
        l_2: 2251799813685247,
        l_3: 1111110666666445,
        l_4: 2251799813685246
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.scalar_mult(a, 2)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_mult_by_large_scalar() {
    let a = Element{ 
        l_0: 79611,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 555555333333222,
        l_4: 2251799813685247
    };
    let expected_res = Element{ 
        l_0: 342008245700831,
        l_1: 2251795518717953,
        l_2: 2251799813685247,
        l_3: 536152338865944,
        l_4: 2251796578355658
    };

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.scalar_mult(a, 4294967295)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res == expected_res);
}

#[tokio::test]
async fn test_square1() {
    let a = Element{ 
        l_0: 1292655137982008, 
        l_1: 1303372017735434, 
        l_2: 595911506101250,
        l_3: 312158315551803,
        l_4: 404732633123850 
    };
    let a_square = Element{ 
        l_0: 2144628324130663, 
        l_1: 596790797966485,
        l_2: 912635275234964,
        l_3: 713663780369466,
        l_4: 1207365348681671
    };   

    let (_instance, _id) = get_contract_instance().await;

    let squared_res = _instance.square(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(squared_res == a_square);
}

#[tokio::test]
async fn test_subtraction_by_0() {
    let a = Element{ 
        l_0: 2251799813685247, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };
    let expected_res = Element{ 
        l_0: 2251799813685247, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };   

    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(a, ZERO)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(subtract_res == expected_res);
}

#[tokio::test]
async fn test_subtraction_by_1() {
    let a = Element{ 
        l_0: 2251799813685247, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };
    let expected_res = Element{ 
        l_0: 2251799813685246, 
        l_1: 5, 
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 100 
    };   

    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(a, ONE)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(subtract_res == expected_res);
}

#[tokio::test]
async fn test_subtraction_by_max() {
    let a = Element{ 
        l_0: 2251799813685227,
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };
    let b = Element{ 
        l_0: 2251799813685228, 
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };   
    let expected_res = Element{ 
        l_0: 2251799813685228, 
        l_1: 2251799813685247,
        l_2: 2251799813685247,
        l_3: 2251799813685247,
        l_4: 2251799813685247
    };  
    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

    assert!(subtract_res == expected_res);
}

#[tokio::test]
async fn test_subtraction_random() {
    let a = Element{ 
        l_0: 1292655137982008,
        l_1: 1303372017735434,
        l_2: 595911506101250,
        l_3: 601879629470779,
        l_4: 50591579140481
    };
    let b = Element{ 
        l_0: 1360902863141127, 
        l_1: 807899991388824,
        l_2: 335483569739384,
        l_3: 293961277766182,
        l_4: 137209507300112
    };   
    let expected_res = Element{ 
        l_0: 2183552088526110, 
        l_1: 495472026346609,
        l_2: 260427936361866,
        l_3: 307918351704597,
        l_4: 2165181885525617
    };  
    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(a, b)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
        
    assert!(subtract_res == expected_res);
}

#[tokio::test]
async fn test_subtraction_random2() {
    let a = Element{ 
        l_0: 1292655137982008,
        l_1: 1303372017735434,
        l_2: 595911506101250,
        l_3: 601879629470779,
        l_4: 50591579140481
    };
    let b = Element{ 
        l_0: 1360902863141127, 
        l_1: 807899991388824,
        l_2: 335483569739384,
        l_3: 293961277766182,
        l_4: 137209507300112
    };   
    let expected_res = Element{ 
        l_0: 68247725159119, 
        l_1: 1756327787338638,
        l_2: 1991371877323381,
        l_3: 1943881461980650,
        l_4: 86617928159630
    };  
    let (_instance, _id) = get_contract_instance().await;

    let subtract_res = _instance.subtract(b, a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
        
    assert!(subtract_res == expected_res);
}

//Testing not done because of error Immediate18TooLarge
/* 
#[tokio::test]
async fn test_inverse_random() {
    /*
    TO_LIMB_T(0xf4df1f341c341746), TO_LIMB_T(0x0a76e6a609d104f1),
    TO_LIMB_T(0x8de5476c4c95b6d5), TO_LIMB_T(0x67eb88a9939d83c0),
    TO_LIMB_T(0x9a793e85b519952d), TO_LIMB_T(0x11988fe592cae3aa)
    */
    let a = Element{ 
        l_0: 715325916561861, 
        l_1: 1128975921026318, 
        l_2: 1696955067652624,
        l_3: 2081297221826529,
        l_4: 175872643896950
    };
    let expected_res = Element{ 
        l_0: 2187613694507759, 
        l_1: 1614434677729781,
        l_2: 1594711943325299,
        l_3: 378203143193209,
        l_4: 843416921835783
    };   

    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.inverse(a)
        .tx_params(TxParameters::new(None, Some(100_000_000), None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;

        assert!(res == expected_res);
}
*/