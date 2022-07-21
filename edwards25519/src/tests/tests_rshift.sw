library tests_rshift;

use ::field_element::*;
use std::assert::assert;
use ::test_helpers::*;
use std::u128::*;

pub fn tests_shift_right_by51() -> bool {
    assert(test_shift_right_by51_random());
    assert(test_shift_right_by51_random_2());
    assert(test_shift_right_by51_random_3());
    true
}

fn test_shift_right_by51_random() -> bool {
    
    let a = U128{upper: 16, lower:0};
    let res = shift_right_by51(a);
    assert(res == 131072);
    true
}

fn test_shift_right_by51_random_2() -> bool {
    /*
456464 + (349323232 << 64) = 6443876259705066799772399376

>>51 = 2861655916544
    */
    let a = U128{upper: 349323232, lower:456464};
    let res = shift_right_by51(a);
    assert(res == 2861655916544);
    true
}

fn test_shift_right_by51_random_3() -> bool {
    /*
18446744073709551615 + (349323232 << 64) = 6443876278151810873481494527

>>51 = 2861655924735
    */
    let a = U128{upper: 349323232, lower:18446744073709551615};
    let res = shift_right_by51(a);
    assert(res == 2861655924735);
    true
}
