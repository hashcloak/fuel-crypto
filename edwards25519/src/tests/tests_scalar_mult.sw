library tests_scalar_mult;

use ::field_element::*;
use std::assert::assert;
use ::test_helpers::*;

pub fn tests_scalar_mult() -> bool {
    assert(test_mult_by_0());
    assert(test_mult_by_1());
    assert(test_mult_by_2());
    assert(test_mult_by_2_again());
    assert(test_mult_by_large_scalar());
    true
}

fn test_mult_by_0() -> bool {
    let a = Element{ 
        l0: 2251799813685247, 
        l1: 5, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 100 
    };

    let res: Element = scalar_mult(a, 0);
    res_equals(res, ZERO)
}

fn test_mult_by_1() -> bool {
    let a = Element{ 
        l0: 79611, 
        l1: 2251799813685247, 
        l2: 2251799813685247,
        l3: 555555333333222,
        l4: 2251799813685247 
    };

    let res: Element = scalar_mult(a, 1);
    res_equals(res, a)
}

fn test_mult_by_2() -> bool {
    /*
    79611 + 
    2251799813685247 * 2^51 +
    2251799813685247 * 2^102 +
    555555333333222 * 2^153 +
    2251799813685247 * 2^204
    */
    let a = Element{ 
        l0: 79611, 
        l1: 2251799813685247, 
        l2: 2251799813685247,
        l3: 555555333333222,
        l4: 2251799813685247 
    };

    /* 57896044618658058976409158941982667984400415217654165675094330160006532591113
    =[159241, 
    2251799813685246, 
    2251799813685247, 
    1111110666666445, 
    2251799813685246] */
    let res: Element = scalar_mult(a, 2);
    
    res_equals(res, Element{ 
        l0: 159241, 
        l1: 2251799813685246, 
        l2: 2251799813685247, 
        l3: 1111110666666445, 
        l4: 2251799813685246
    })
}

fn test_mult_by_2_again() -> bool {
    // 2^255 - 20 (the largest number) expressed in radix-51
    /*
    2251799813685228 +
    2251799813685247 * 2^51 +
    2251799813685247 * 2^102 +
    2251799813685247 * 2^153 + 
    2251799813685247 * 2^204
    */
    let a = Element{ 
        l0: 2251799813685228, 
        l1: 2251799813685247, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 2251799813685247 
        };


    let res: Element = scalar_mult(a, 2);
    
    /*
    2251799813685227
    2251799813685247* 2^51 +
    2251799813685247* 2^102 +
    2251799813685247* 2^153 + 
    2251799813685247 * 2^204
    */
    res_equals(res, Element{ 
        l0: 2251799813685227, 
        l1: 2251799813685247, 
        l2: 2251799813685247, 
        l3: 2251799813685247, 
        l4: 2251799813685247
    })
}

fn test_mult_by_large_scalar() -> bool {
    /*
    79611 + 
    2251799813685247 * 2^51 +
    2251799813685247 * 2^102 +
    555555333333222 * 2^153 +
    2251799813685247 * 2^204
    */
    let a = Element{ 
        l0: 79611, 
        l1: 2251799813685247, 
        l2: 2251799813685247,
        l3: 555555333333222,
        l4: 2251799813685247 
    };

    /* 
    248661618146997193275445770277948644497863737508141907291226725252005565483705230608645
    reduced mod 2^255 - 19
    = 57895961435070841628109209456323569962738033236635300844883400985433276860639
    = [342008245700831, 2251795518717953, 2251799813685247, 536152338865944, 2251796578355658]
    */  
    // Largest scalar input possible is 2^32 -1 = 4294967295
    let res: Element = scalar_mult(a, 4294967295);
    
    res_equals(res, Element{ 
        l0: 342008245700831, 
        l1: 2251795518717953, 
        l2: 2251799813685247, 
        l3: 536152338865944, 
        l4: 2251796578355658
    })
}