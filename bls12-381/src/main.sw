script;

dep vect;
dep fields;
dep test_helpers;
dep consts;
dep tests/tests_vect_fp;
dep tests/tests_vect_fp2;
dep tests/tests_vect_subfunctions;
dep tests/tests_small_functions;

use std::{assert::assert, option::*, u128::*, vec::Vec};
use ::fields::*;
use ::vect::*;
use ::consts::*;
use ::test_helpers::*;
use std::logging::log;

use ::tests_vect_fp::fp_tests;
use ::tests_vect_fp2::fp2_tests;
use ::tests_vect_subfunctions::vect_subfunctions_tests;
use ::tests_small_functions::tests_small_functions;

fn main() {
    // assert(fp_tests());
    assert(fp2_tests());
    // assert(test_multiply_wrap());
    // assert(test_mac());
    // assert(vect_subfunctions_tests());
    // assert(tests_small_functions());
}

fn test_mac() -> bool {
    let a = 13282407956253574712;
    let b = 7557322358563246340;
    let c = 14991082624209354397;

    let res = mac(a, b, c, 0);
    assert(res.0 == 15211181400380206508);
    assert(res.1 == 6141595689857899799);

    let carry = 1234555432334;
    let res2 = mac(a, b, c, carry);
    assert(res2.0 == 15211182634935638842);
    assert(res2.1 == 6141595689857899799);

    true
}

fn test_multiply_wrap() -> bool {
    let a: u64 = 562706585515371056;
    let b: u64 = 2854579515609623853;
    let res: u64 = multiply_wrap(a, b);
    assert(res == 2259604989141998192);
    true
}
