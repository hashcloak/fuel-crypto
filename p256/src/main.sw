script;
dep field64;

// use field64::{Fe, fe_add, fe_mul, fe_sub};
use field64::*;

use std::u256::U256;

fn main() {
  test_fe_add();
  test_fe_sub();
  test_fe_mul();
}

fn assert_eq_fe(a: Fe, b: Fe) {
  assert(a.ls[0] == b.ls[0]);
  assert(a.ls[1] == b.ls[1]);
  assert(a.ls[2] == b.ls[2]);
  assert(a.ls[3] == b.ls[3]);
}

fn log_fe(a: Fe) {
  log(a.ls[0]);
  log(a.ls[1]);
  log(a.ls[2]);
  log(a.ls[3]);
}

fn test_fe_add() {
  //31416255128259651114300763853743354944401428675127717048158727858123196938092
  let x = Fe{ls: [15982738825684268908, 12861376030615125811, 9837491998535547791, 5004898192290387222]};

  //3012016290743527304884562416673584005842165475579906631995563069167839294388
  let y = Fe{ls:[ 10598342506117936052, 6743270311476307786, 2169871353760194456, 479841878898268594]};

  // x+y
  //34428271419003178419185326270416938950243594150707623680154290927291036232480
  let res_xy = Fe{ls: [8134337258092653344, 1157902268381881982, 12007363352295742248, 5484740071188655816]};
  assert_eq_fe(fe_add(x, y), res_xy);

  // 41624337018869194729192205381537838788846303834619688597471765238035829032504
  let a = Fe{ ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670] };

  // 112889434785065900135211481371037383646282385554418514861667765615237067913479
  let b = Fe{ ls: [10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179] };
  
  // a+b mod p 
  //38721682593578846101706239803167648905042545973747889263605899544405799092032
  let res = Fe { ls: [5555591898548944704, 2956224731436978438, 9686708628070057556, 6168719932526873529]};
  let calculated_res = fe_add(a,b);
  assert_eq_fe(calculated_res, res);
}

fn test_fe_sub() {
  //31416255128259651114300763853743354944401428675127717048158727858123196938092
  let x = Fe{ls: [15982738825684268908, 12861376030615125811, 9837491998535547791, 5004898192290387222]};

  //3012016290743527304884562416673584005842165475579906631995563069167839294388
  let y = Fe{ls:[ 10598342506117936052, 6743270311476307786, 2169871353760194456, 479841878898268594]};

  // x-y mod p
  //28404238837516123809416201437069770938559263199547810416163164788955357643704
  let res_xy = Fe{ls: [5384396319566332856, 6118105719138818025, 7667620644775353335, 4525056313392118628]};
  assert_eq_fe(fe_sub(x, y), res_xy);

  // 41624337018869194729192205381537838788846303834619688597471765238035829032504
  let a = Fe{ ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670] };

  // 112889434785065900135211481371037383646282385554418514861667765615237067913479
  let b = Fe{ ls: [10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179] };
  
  // a-b mod p 
  //44526991444159543356678170959908028672650061695491487931337630931665858972976
  let res = Fe { ls: [2562479940248653104, 12158419985689514243, 1848712546639099622, 7093558989675447812]};
  let calculated_res = fe_sub(a,b);
  assert_eq_fe(calculated_res, res);
}


fn test_fe_mul() {
  let a = Fe{ ls: [1,1,1,1] };
  let b = Fe{ ls: [1,0,0,0] };

  let output = fe_mul(fe_to_montgomery(a),fe_to_montgomery(b));
  assert_eq_fe(fe_from_montgomery(output), a);

  // 41624337018869194729192205381537838788846303834619688597471765238035829032504
  let a: Fe = Fe{ls: [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670]};
  // 112889434785065900135211481371037383646282385554418514861667765615237067913479
  let b: Fe = Fe{ls: [10719928016004921607, 13845646450878251009, 13142370077570254774, 17984324540840297179]};
  
  let result: Fe = Fe{ls: [3855380404042364083, 4501942987140393524, 18012298605561464384, 6330810359896140563]};


  let output = fe_mul(fe_to_montgomery(a),fe_to_montgomery(b));
  // log_fe(fe_from_montgomery(output));
  assert_eq_fe(result, fe_from_montgomery(output));
}
