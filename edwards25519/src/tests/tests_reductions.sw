library tests_reductions;

use ::field_element::*;
use std::assert::assert;
use ::test_helpers::*;

pub fn test_reductions() -> bool {
    assert(test_carry_propagate_1());
    assert(test_carry_propagate_2());
    assert(test_reduce());
    assert(test_reduce_2());
    assert(test_reduce_3());
    assert(test_reduce_4());
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
    })
    // Note that this result is >2^255-19 because the function only does 1 round of reduction
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

    res_equals(res, Element{ l0: 2, l1: 1, l2: 0, l3: 0, l4: 0 })
}

fn test_reduce() -> bool {
    // 2251799813685250 = 2 + 2^51
    let e = Element{ 
    l0: 2251799813685250, 
    l1: 0, 
    l2: 0,
    l3: 0,
    l4: 0 };

    let res = reduce(e);

    res_equals(res, Element{ l0: 2, l1: 1, l2: 0, l3: 0, l4: 0 })
}

fn test_reduce_2() -> bool {
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

    let res = reduce(e);

    /* equals
    21 + 
    3 * 2^51 + 
    3 * 2^102 + 
    3 * 2^153 +
    3 * 2^204
    */
    res_equals(res, Element{ l0: 21, l1: 3, l2: 3, l3: 3, l4: 3 })
}

fn test_reduce_3() -> bool {
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

    let res = reduce(e);

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
    })
}

fn test_reduce_4() -> bool {
    /*
    4503599627370494 + 
    4503599627370494 * 2^51 +
    4503599627370494 * 2^102 +
    4503599627370494 * 2^153 + 
    4503599627370494 * 2^204
    mod 2^255 - 19
     
    = 36 
    */
    let e = Element{ 
        l0: 4503599627370494,
        l1: 4503599627370494,
        l2: 4503599627370494,
        l3: 4503599627370494,
        l4: 4503599627370494 };

    let res = reduce(e);

    /*
    should be 36
    */
    res_equals(res, Element{ 
        l0: 36, 
        l1: 0, 
        l2: 0, 
        l3: 0, 
        l4: 0 
    })
}
