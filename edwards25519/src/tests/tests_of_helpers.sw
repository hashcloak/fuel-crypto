library tests_of_helpers;

use ::field_element::*;
use std::assert::assert;
use ::test_helpers::*;

pub fn test_helpers() -> bool {
    assert(test_get_zero());
    assert(test_equals());
    true
}

fn test_get_zero() -> bool {
    res_equals(zero, Element{ l0: 0, l1: 0, l2: 0, l3: 0, l4: 0 });
    true
}

fn test_equals() -> bool {
    let zero_equals_zero = equals(zero, zero);
    let zero_equals_one = equals(zero, one);
    let one_equals_one = equals(one, one);

    let a = Element{ 
        l0: 2251799813685247, 
        l1: 5, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 100 
    };
    let b = Element{ 
        l0: 2251799813685247, 
        l1: 5, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 100 
    };   
    let c = Element{ 
        l0: 60, 
        l1: 5, 
        l2: 2251799813685247,
        l3: 500,
        l4: 100 
    }; 
    let a_equals_a = equals(a,a);
    let a_equals_b = equals(a,b); //a and b have same coefficients
    let a_equals_c = equals(a,c);
    let b_equals_c = equals(b,c);

    assert(zero_equals_zero);
    assert(!zero_equals_one);
    assert(one_equals_one);

    assert(a_equals_a);
    assert(a_equals_b);
    assert(!a_equals_c);
    assert(!b_equals_c);

    true
}
