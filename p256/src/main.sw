script;
dep field64;

use field64::{Fe, fe_add, fe_mul};
use std::u256::U256;

fn main() {
  test_fe_add();
  // test_fe_mul();
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
  let a = Fe{ ls: [1,1,1,1] };
  let b = Fe{ ls: [1,1,1,1] };
  let res = fe_add(a, b);
  assert_eq_fe(res, Fe { ls: [2,2,2,2]});

  // modulus + 1
  let res_2 = fe_add(Fe{ls: [0xffffffff00000001,0x0000000000000000,0x00000000ffffffff,0xffffffffffffffff]}, Fe{ls:[0,0,0,1]});
  assert_eq_fe(res_2, Fe { ls: [0,0,0,1]});

  // modulus + [1,0,0,1]
  let res_3 = fe_add(Fe{ls: [0xffffffff00000001,0x0000000000000000,0x00000000ffffffff,0xffffffffffffffff]}, Fe{ls:[1,0,0,1]});
  assert_eq_fe(res_3, Fe{ls: [1,0,0,1]});

  // should give the same result als res_3
  let res_4 = fe_add(Fe{ls: [1,0,0x00000000ffffffff,0xffffffffffffffff]}, Fe{ls:[0xffffffff00000001,0,0,1]});
  assert_eq_fe(res_4, Fe{ls: [1,0,0,1]});
}

fn test_fe_mul() {
  let a = Fe{ ls: [1,1,1,1] };
  let b = Fe{ ls: [0,0,0,1] };
  let res = fe_mul(a, b); // TODO continue here!
}
