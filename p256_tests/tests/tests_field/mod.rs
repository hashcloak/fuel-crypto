use fuels::prelude::*;
use crate::utils::{FieldElement, helpers::get_contract_methods};
use crate::utils::MyContractMethods;

mod success {
  use super::*;

  async fn to_montgomery_ab(_methods: &MyContractMethods<WalletUnlocked>, a: FieldElement, b: FieldElement) -> (FieldElement, FieldElement) {
  let a_montgomery_form = _methods
    .fe_to_montgomery(a)
    .call().await.unwrap();

  let b_montgomery_form = _methods
    .fe_to_montgomery(b)
    .call().await.unwrap();

  (a_montgomery_form.value, b_montgomery_form.value)
  }

  async fn from_montgomery(_methods: &MyContractMethods<WalletUnlocked>, a: FieldElement) -> FieldElement {
    _methods
      .fe_from_montgomery(a)
      .call().await.unwrap().value
  }

  async fn to_montgomery(_methods: &MyContractMethods<WalletUnlocked>, a: FieldElement) -> FieldElement {
    _methods
      .fe_to_montgomery(a)
      .call().await.unwrap().value
  }

  #[tokio::test]
  async fn test_fe_mul_1() {
    let (_methods, _id) = get_contract_methods().await;

    // Test 1
    let a1: FieldElement = FieldElement{ls: [1,1,1,1]};
    let b1: FieldElement = FieldElement{ls: [1,0,0,0]};
    
    let (a1_montgomery_form, b1_montgomery_form) = to_montgomery_ab(&_methods, a1, b1).await;
    let result1 = _methods
      .fe_mul(a1_montgomery_form, b1_montgomery_form)
      .call().await.unwrap();
    let result1_converted = from_montgomery(&_methods, result1.value).await;
    
    assert_eq!(FieldElement{ls: [1,1,1,1]}, result1_converted);

    // Test 2
    let a2: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
    let b2: FieldElement = FieldElement{ls: [10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};
    
    let (a2_montgomery_form, b2_montgomery_form) = to_montgomery_ab(&_methods, a2, b2).await;
    let result2 = _methods
      .fe_mul(a2_montgomery_form, b2_montgomery_form)
      .call().await.unwrap();
    let result_converted2 = from_montgomery(&_methods, result2.value).await;
    
    let expected2: FieldElement = FieldElement{ls: [3855380404042364083, 4501942987140393524, 18012298605561464384, 6330810359896140563]};

    assert_eq!(expected2, result_converted2);

    // Test 3
    let a3: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
    let b3: FieldElement = FieldElement{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
    
    let (a3_montgomery_form, b3_montgomery_form) = to_montgomery_ab(&_methods, a3, b3).await;
    let result3 = _methods
      .fe_mul(a3_montgomery_form, b3_montgomery_form)
      .call().await.unwrap();
    let result_converted3 = from_montgomery(&_methods, result3.value).await;
    
    let expected3: FieldElement = FieldElement{ls: [2309392440375388613, 1135074464031845990, 12738695718013625742, 14519977860574561767]};

    assert_eq!(expected3, result_converted3);

  }

  #[tokio::test]
  async fn test_sqrt() {
    let (_methods, _id) = get_contract_methods().await;

    // Random nr 59139082389495374972926751946201499749231456944901481987554600995611674860084
    // 8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936
    let r: FieldElement = FieldElement{ls: [8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936]};

    let r_form = to_montgomery(&_methods, r).await;
    let sqrt_r = _methods
      .sqrt(r_form)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();
    let result_converted = from_montgomery(&_methods, sqrt_r.value.value).await;
    let expected: FieldElement = FieldElement{ls: [10414696227621044143, 5518441681270087222, 392556470792855661, 10489680726816654902]};

    assert_eq!(expected, result_converted);
  }

  #[tokio::test]
  async fn test_invert_1() {
    let (_methods, _id) = get_contract_methods().await;

    // TEST 1

    // root of unity 115792089210356248762697446949407573530086143415290314195533631308867097853950
    // [18446744073709551614, 4294967295, 0, 18446744069414584321]
    let root_of_unity = FieldElement { ls: [18446744073709551614, 4294967295, 0, 18446744069414584321]};
    let root_of_unity_montgomery_form = to_montgomery(&_methods, root_of_unity).await;

    let inv_montgomery_form = _methods
      .invert(root_of_unity_montgomery_form)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();

    let result1_converted = from_montgomery(&_methods, inv_montgomery_form.value.value).await;
    let expected1: FieldElement = FieldElement{ls: [18446744073709551614, 4294967295, 0, 18446744069414584321]};

    assert_eq!(expected1, result1_converted);

    // TEST 2

    let z = FieldElement { ls: [1993877568177495041, 10345888787846536528, 7746511691117935375, 14517043990409914413]};
    let z_montgomery_form = to_montgomery(&_methods, z).await;

    let inv_z_montgomery_form = _methods
      .invert(z_montgomery_form)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();

    let result2_converted = from_montgomery(&_methods, inv_z_montgomery_form.value.value).await;
    let expected2: FieldElement = FieldElement{ls: [4299806231468303744, 8024480717984164326, 11501998322799236989, 8789660679986197156]};

    assert_eq!(expected2, result2_converted);

    // TEST 3
    let x = FieldElement { ls: [10634854829044225757, 351552716085025155, 10645315080955407736, 3609262091244858135]};
    let x_montgomery_form = to_montgomery(&_methods, x).await;

    let inv_x_montgomery_form = _methods
      .invert(x_montgomery_form)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();

    let result3_converted = from_montgomery(&_methods, inv_x_montgomery_form.value.value).await;
    // z^(-1) = 88647100750625721153149943186404157918844683715528760041837114016635683486024
    let expected3: FieldElement = FieldElement{ls: [12758252840858302792, 2862372623786672612, 7477786404377448950, 14122297915116537490]};

    assert_eq!(expected3, result3_converted);
  }

  #[tokio::test]
  async fn test_pow_vartime() {
    let (_methods, _id) = get_contract_methods().await;

    // 59139082389495374972926751946201499749231456944901481987554600995611674860084
    let a: FieldElement = FieldElement{ls:[8293668300693101108, 9881061877981018291, 9534524411267565544, 9421399378650073936]};
    let a_montgomery_form = to_montgomery(&_methods, a).await;

    let pow_vartime = _methods
      .pow_vartime(a_montgomery_form.clone(), [4,0,0,0])
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();

    let result1_converted = from_montgomery(&_methods, pow_vartime.value).await;
    let expected1 = FieldElement{ls: [18077862325614776725, 13343880950817753919, 13722074626277446175, 18017497567293989711]};

    assert_eq!(expected1, result1_converted);
  }

  #[tokio::test]
  async fn test_fe_to_bytes() {
    let (_methods, _id) = get_contract_methods().await;

    // bigint 43872280807156713839160376167191808430140484563252114113014272064716834774966
    let x = FieldElement { ls:[16602909452612575158, 13855808666783054444, 14511138361138572648, 6989257567681289521] };

    let bytes = _methods
      .fe_to_bytes(x)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
      .call().await.unwrap();

    assert_eq!(bytes.value, [96, 254, 212, 186, 37, 90, 157, 49, 201, 97, 235, 116, 198, 53, 109, 104, 192, 73, 184, 146, 59, 97, 250, 108, 230, 105, 98, 46, 96, 242, 159, 182]);
  }
}