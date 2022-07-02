script;

dep field_element;
dep test_helpers;

use ::field_element::*;
use ::test_helpers::*;

use std::{assert::assert, option::*, vec::Vec};
use std::logging::log;
use core::num::*;


fn main() {
    assert(test_helpers());
    assert(test_reductions());
    assert(tests_add());
}

fn test_helpers() -> bool {
    assert(test_get_zero());
    true
}

fn test_get_zero() -> bool {
    res_equals(zero, Element{ l0: 0, l1: 0, l2: 0, l3: 0, l4: 0 });
    true
}

fn test_reductions() -> bool {
    assert(test_carry_propagate_1());
    assert(test_carry_propagate_2());
    assert(test_mod_25519());
    assert(test_mod_25519_2());
    //assert(test_mod_25519_3());
    true
}

fn test_carry_propagate_1() -> bool {
    /*
    2^64 -1 = 18446744073709551615

    18446744073709551615 + 
    18446744073709551615 * 2^51 + 
    18446744073709551615 * 2^102 + 
    18446744073709551615 * 2^153 +
    18446744073709551615 * 2^204
    */
    let e = Element{ 
        l0: ~u64::max(), 
        l1: ~u64::max(), 
        l2: ~u64::max(),
        l3: ~u64::max(),
        l4: ~u64::max() };

    let res = carry_propagate(e);

    // Each limb has a carry of 8191 and a coeff of 2251799813685247
    // So after a round of reduction this is 
    /* equals
    2251799813685247 + (19*8191) + 
    (2251799813685247 + 8191) * 2^51 + 
    (2251799813685247 + 8191) * 2^102 + 
    (2251799813685247 + 8191) * 2^153 +
    (2251799813685247 + 8191) * 2^204
    = 57896044618868696584113898827420068118245036358148060739095062128926159691756
    */
    res_equals(res, Element{ 
        l0: 2251799813685247 + (19*8191), 
        l1: 2251799813685247 + 8191, 
        l2: 2251799813685247 + 8191, 
        l3: 2251799813685247 + 8191, 
        l4: 2251799813685247 + 8191 
    });

    // Note that this result is >2^255-19 because the function only does 1 round of reduction

    true
}

fn test_carry_propagate_2() -> bool {
    // 2251799813685250 = 2 + 2^51
    let e = Element{ 
    l0: 2251799813685250, 
    l1: 0, 
    l2: 0,
    l3: 0,
    l4: 0 };

    let res = carry_propagate(e);

    res_equals(res, Element{ l0: 2, l1: 1, l2: 0, l3: 0, l4: 0 });

    true
}

fn test_mod_25519() -> bool {
    // 2251799813685250 = 2 + 2^51
    let e = Element{ 
    l0: 2251799813685250, 
    l1: 0, 
    l2: 0,
    l3: 0,
    l4: 0 };

    let res = mod_25519(e);

    res_equals(res, Element{ l0: 2, l1: 1, l2: 0, l3: 0, l4: 0 });

    true
}

fn test_mod_25519_2() -> bool {
    /*
    2^51 + 2 = 2251799813685250

    2251799813685250 + 
    2251799813685250 * 2^51 + 
    2251799813685250 * 2^102 + 
    2251799813685250 * 2^153 +
    2251799813685250 * 2^204
     mod 2^255-19
    */
    let e = Element{ 
        l0: 2251799813685250, 
        l1: 2251799813685250, 
        l2: 2251799813685250,
        l3: 2251799813685250,
        l4: 2251799813685250 };

    let res = mod_25519(e);

    /* equals
    21 + 
    3 * 2^51 + 
    3 * 2^102 + 
    3 * 2^153 +
    3 * 2^204
    */
    res_equals(res, Element{ l0: 21, l1: 3, l2: 3, l3: 3, l4: 3 });

    true
}

fn test_mod_25519_3() -> bool {
    /*
    2^64 -1 = 18446744073709551615

    18446744073709551615 + 
    18446744073709551615 * 2^51 + 
    18446744073709551615 * 2^102 + 
    18446744073709551615 * 2^153 +
    18446744073709551615 * 2^204
    mod 2^255 -19
    = 210598872328406323076114191610044025327778719366270124969594871807
    */
    let e = Element{ 
        l0: ~u64::max(), 
        l1: ~u64::max(), 
        l2: ~u64::max(),
        l3: ~u64::max(),
        l4: ~u64::max() };

    let res = mod_25519(e);

    /*
    155647 +
    8191 * 2^51 +
    8191 * 2^102 +
    8191 * 2^153 + 
    8191 * 2^204
    = 210598872328406323076114191610044025327778719366270124969594871807
    */
    res_equals(res, Element{ 
        l0: 155647, 
        l1: 8191, 
        l2: 8191, 
        l3: 8191, 
        l4: 8191 
    });

    true
}

fn tests_add() -> bool {
    assert(test_add_to_0());
    assert(test_add_0());
    assert(test_add_a_to_b());
    assert(test_add_a_to_a());
    true

}

fn test_add_to_0() -> bool {
    let b = Element{ 
    l0: 8191, 
    l1: 225179, 
    l2: 155647,
    l3: 81918191,
    l4: 85247 
    };

    let res = add(zero, b);

    assert(res_equals(res, b));
    true
}

fn test_add_0() -> bool {
    let b = Element{ 
    l0: 8191, 
    l1: 225179, 
    l2: 155647,
    l3: 81918191,
    l4: 85247 
    };

    let res = add(b, zero);

    assert(res_equals(res, b));
    true
}

fn test_add_a_to_b() -> bool {
    // coefficients are 2^51-1 
    /*
    2251799813685247 +
    2251799813685247 * 2^51 +
    2251799813685247 * 2^102 +
    2251799813685247 * 2^153 + 
    2251799813685247 * 2^204
    = 57896044618658097711785492504343953926634992332820282019728792003956564819967
    */
    let a = Element{ 
        l0: 2251799813685247, 
        l1: 2251799813685247, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 2251799813685247 
        };

    //  random
    /*
    8191 +
    225179 * 2^51 +
    155647 * 2^102 +
    81918191 * 2^153 + 
    85247 * 2^204
    = 2191786359344073644698773448800701597704682582429191096092436996095
    */
    let b = Element{ 
        l0: 8191, 
        l1: 225179, 
        l2: 155647,
        l3: 81918191,
        l4: 85247 
        };

    // a+b mod 2^255 -19 
    // should be 2191786359344073644698773448800701597704682582429191096092436996113
    let res = add(a,b);

    /*
    8209 +
    225179 * 2^51 +
    155647 * 2^102 +
    81918191 * 2^153 + 
    85247 * 2^204
    = 2191786359344073644698773448800701597704682582429191096092436996113
    */
    res_equals(res, Element{ 
        l0: 8209, 
        l1: 225179, 
        l2: 155647, 
        l3: 81918191, 
        l4: 85247 
    });

    true
}

fn test_add_a_to_a() -> bool {
    // coefficients are 2^51-1 
    /*
    2251799813685247 +
    2251799813685247 * 2^51 +
    2251799813685247 * 2^102 +
    2251799813685247 * 2^153 + 
    2251799813685247 * 2^204
    = 57896044618658097711785492504343953926634992332820282019728792003956564819967
    */
    let a = Element{ 
        l0: 2251799813685247, 
        l1: 2251799813685247, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 2251799813685247 
        };

    // a+a mod 2^255 -19 
    // should be 
    let res = add(a, a);

    print_el(res);

    true
}