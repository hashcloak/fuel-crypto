use fuels::prelude::*;
use crate::utils::{Scalar, helpers::get_contract_methods};

mod success {
  use super::*;
  //41624337018869194729192205381537838788846303834619688597471765238035829032504
  const X_SCALAR: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
  
  //112889434785065900135211481371037383646282385554418514861667765615237067913479
  const Y_SCALAR: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};

  #[tokio::test]
  async fn test_bytes_to_scalar() {
    let (_methods, _id) = get_contract_methods().await;

    // test value: 112889434785065900135211481371037383646282385554418514861667765615237067913479
    let byte_array: [u8;32] = [249, 149, 39, 226, 134, 32, 66, 219, 182, 99, 19, 244, 76, 76, 71, 182, 192, 37, 158, 22, 246, 63, 0, 1, 148, 196, 213, 187, 227, 187, 57, 7];
    let result = _methods
      .scalar_from_bytes(byte_array)
      .call().await.unwrap();

    assert_eq!(result.value.ls[0], 10719928016004921607);
    assert_eq!(result.value.ls[1], 13845646450878251009);
    assert_eq!(result.value.ls[2], 13142370077570254774);
    assert_eq!(result.value.ls[3], 17984324540840297179);
  }

  #[tokio::test]
  async fn test_scalar_add() {
    let (_methods, _id) = get_contract_methods().await;

    // TEST 1
    //31416255128259651114300763853743354944401428675127717048158727858123196938092
    let x1: Scalar = Scalar{ls: [15982738825684268908, 12861376030615125811, 9837491998535547791, 5004898192290387222]};

    //3012016290743527304884562416673584005842165475579906631995563069167839294388
    let y1: Scalar = Scalar{ls:[ 10598342506117936052, 6743270311476307786, 2169871353760194456, 479841878898268594]};

    let scalar_add = _methods
      .scalar_add(x1, y1)
      .call().await.unwrap();

    // Result is also 34428271419003178419185326270416938950243594150707623680154290927291036232480
    assert_eq!(scalar_add.value.ls[0], 8134337258092653344);
    assert_eq!(scalar_add.value.ls[1], 1157902268381881982);
    assert_eq!(scalar_add.value.ls[2], 12007363352295742248);
    assert_eq!(scalar_add.value.ls[3], 5484740071188655816);

    // TEST 2
    //41624337018869194729192205381537838788846303834619688597471765238035829032504
    let x2: Scalar = Scalar{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};

    //112889434785065900135211481371037383646282385554418514861667765615237067913479
    let y2: Scalar = Scalar{ls:[ 10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};

    let scalar_add2 = _methods
      .scalar_add(x2, y2)
      .call().await.unwrap();

    // Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
    assert_eq!(scalar_add2.value.ls[0], 6440044811543714286);
    assert_eq!(scalar_add2.value.ls[1], 7791126261927965313);
    assert_eq!(scalar_add2.value.ls[2], 9686708628070057556);
    assert_eq!(scalar_add2.value.ls[3], 6168719932526873529);
  }

  #[tokio::test]
  async fn test_scalar_sub() {
    let (_methods, _id) = get_contract_methods().await;

    let scalar_sub = _methods
      .scalar_sub(X_SCALAR, Y_SCALAR)
      .call().await.unwrap();

    // Result = 38721682593578846101706239803167648905131734164902443116717271792204384901614
    assert_eq!(scalar_sub.value.ls[0], 1678027027253883522);
    assert_eq!(scalar_sub.value.ls[1], 7323518455198527368);
    assert_eq!(scalar_sub.value.ls[2], 1848712546639099622);
    assert_eq!(scalar_sub.value.ls[3], 7093558989675447812);
  }

  #[tokio::test]
  async fn test_scalar_mul() {
    let (_methods, _id) = get_contract_methods().await;

    let scalar_mul = _methods
      .scalar_mul(X_SCALAR, Y_SCALAR)
      .call().await.unwrap();

    // Result = 103996961415186572744923623518133659781096567566995581831564221704662704998922
    assert_eq!(scalar_mul.value.ls[0], 12652583779974793738);
    assert_eq!(scalar_mul.value.ls[1], 11510399856113002259);
    assert_eq!(scalar_mul.value.ls[2], 17112986354705659152);
    assert_eq!(scalar_mul.value.ls[3], 16567671801288747593);
  }

  #[tokio::test]
  async fn test_scalar_invert() {
    let (_methods, _id) = get_contract_methods().await;

    // 6024032581487054615307857608562388818842860057096001857409703737786438595508
    let x: Scalar = Scalar{ls: [10598342506117936052, 6743270311476307786, 2169871353760194456, 959683757796537189]};
    
    let invert_x = _methods
      .scalar_invert(x)
      .tx_params(TxParameters::default().set_gas_limit(100_000_000))
      .call().await.unwrap();

    // result should be 84801081494837761602111676842516221872243864255054144073280115004536303842931
    assert_eq!(invert_x.value.value.ls[0], 9530314696573515379);
    assert_eq!(invert_x.value.value.ls[1], 1325056620123427311);
    assert_eq!(invert_x.value.value.ls[2], 7698614219480972011);
    assert_eq!(invert_x.value.value.ls[3], 13509591698470992260);
  }


}