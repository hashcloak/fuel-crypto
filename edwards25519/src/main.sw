script;

dep field_element;
dep test_helpers;

// Import all tests
dep tests/tests_add;
dep tests/tests_helpers64;
dep tests/tests_multiply;
dep tests/tests_of_helpers;
dep tests/tests_reductions;
dep tests/tests_rshift;
dep tests/tests_scalar_mult;
dep tests/tests_square;
dep tests/tests_sub;
dep tests/tests_inverse;

use ::tests_add::tests_add;
use ::tests_helpers64::test_helpers64;
use ::tests_multiply::tests_multiply;
use ::tests_of_helpers::test_helpers;
use ::tests_reductions::test_reductions;
use ::tests_rshift::tests_shift_right_by51;
use ::tests_scalar_mult::tests_scalar_mult;
use ::tests_square::tests_square;
use ::tests_sub::tests_substract;
use ::tests_inverse::tests_inverse;

use ::field_element::*;
use ::test_helpers::*;

use std::{assert::assert, option::*, vec::Vec};
use std::logging::log;
use core::num::*;
use std::u128::*;

fn main() {

    // assert(tests_add());
    // assert(test_helpers64());
    // assert(test_reductions());
    // assert(tests_shift_right_by51());
    // assert(tests_scalar_mult());
    // assert(tests_substract());


    // assert(tests_square());
    // assert(tests_inverse());

    //Doesnt' terminate
    // assert(tests_inverse());
}

