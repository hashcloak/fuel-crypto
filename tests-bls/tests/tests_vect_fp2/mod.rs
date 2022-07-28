use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;

abigen!(BlsContract, "out/debug/tests-bls-abi.json");

async fn get_contract_instance() -> (BlsContract, ContractId) {
    let mut wallets = launch_provider_and_get_wallets(WalletsConfig::new_single(Some(1), Some(100_000_000))).await;
    let wallet = wallets.pop().unwrap();
    let id = Contract::deploy("./out/debug/tests-bls.bin", &wallet, TxParameters::default()).await.unwrap();
    let instance = BlsContract::new(id.to_string(), wallet);
    (instance, id)
}

pub fn res_equals(res: vec384, should_be: vec384) -> bool {
    assert!(res.ls[0] == should_be.ls[0]);
    assert!(res.ls[1] == should_be.ls[1]);
    assert!(res.ls[2] == should_be.ls[2]);
    assert!(res.ls[3] == should_be.ls[3]);
    assert!(res.ls[4] == should_be.ls[4]);
    assert!(res.ls[5] == should_be.ls[5]);
    true
}

fn get_a1() -> vec384x {
    let r_1 = vec384 {
        ls: [14795151457364307190, 6622185142386025417, 
        17709159039044576520, 1719961663313476946, 
        4148264363906786574, 980769587779429096].to_vec()
    };
    //1854013830343626212433083622699305309002946726548085159596712876339371488002438401231777242990713512722976854546804
    let i_1 = vec384 {
        ls: [8306319196692453748, 10328470218072223240, 
        3451314819045096133, 17542580433704256157, 
        9684937745078445131, 867989271079206780].to_vec()
    };
    let a_1 = vec384x {
        r: r_1,
        i: i_1,
    };
    a_1
}


fn get_a2() -> vec384x {
    let r2_vec = vec384{
        ls: [16448140995118783999, 9520526689676604696, 
        7916863578364318753, 8691145487628551970, 
        16531338352426028355, 1893914179705411585].to_vec()
    };

    let i2_vec = vec384{
        ls: [1139524850979729662, 10226030227531743340, 
        16078343496594203218, 16066350528929326807, 
        17232578759082026236, 1990003151713484304].to_vec()
    };

    let a_2 = vec384x {
        r: r2_vec,
        i: i2_vec,
    };
    a_2
}

#[tokio::test]
async fn tests_add_fp2() {
    let a_1 = get_a1();
    let a_2 = get_a2();

    let expected_r = vec384 {
        ls: [17840861436405227594, 13932570320545421538, 18190348043844813573, 3171769190527316405, 15267498937862112634, 1000885149837300815].to_vec()
    };
    let expected_i = vec384 {
        ls: [14490157105303871431, 18344358934086758004, 12093983742075217651, 7922848928509318837, 3058668651980217457, 984193805145151219].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.add_fp2(a_1, a_2)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res.r, expected_r));
    assert!(res_equals(res.i, expected_i));
}

#[tokio::test]
async fn tests_sub_fp2() {
    let a_1 = get_a1();
    let a_2 = get_a2();

    let expected_r = vec384 {
        ls: [11749441478323386786, 17758544037936180912, 17227970034244339466, 268154136099637487, 11475773863661012130, 960654025721557376].to_vec()
    };
    let expected_i = vec384 {
        ls: [2122481288081036065, 2312581502057688476, 13255389969724526231, 8715567865189641860, 16311206838176672806, 751784737013262341].to_vec()
    };
    let (_instance, _id) = get_contract_instance().await;

    let res = _instance.sub_fp2(a_1, a_2)
        .tx_params(TxParameters::new(None, Some(100_000_000), None, None))
        .call_params(CallParameters::new(None, None, Some(100_000_000)))
        .call().await.unwrap().value;
    assert!(res_equals(res.r, expected_r));
    assert!(res_equals(res.i, expected_i));
}