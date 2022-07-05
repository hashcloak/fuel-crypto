script;

dep field_element;
dep test_helpers;

use ::field_element::*;
use ::test_helpers::*;

use std::{assert::assert, option::*, vec::Vec};
use std::logging::log;
use core::num::*;
use std::u128::*;


fn main() {
    // assert(test_helpers());
    // assert(test_reductions());
    // assert(tests_add());
    // assert(tests_scalar_mult());
    // assert(tests_substract());
    assert(tests_multiply64());
    // assert(tests_multiply());

}

fn test_helpers() -> bool {
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

fn test_reductions() -> bool {
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

fn test_reduce() -> bool {
    // 2251799813685250 = 2 + 2^51
    let e = Element{ 
    l0: 2251799813685250, 
    l1: 0, 
    l2: 0,
    l3: 0,
    l4: 0 };

    let res = reduce(e);

    res_equals(res, Element{ l0: 2, l1: 1, l2: 0, l3: 0, l4: 0 });

    true
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
    res_equals(res, Element{ l0: 21, l1: 3, l2: 3, l3: 3, l4: 3 });

    true
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
    });

    true
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

    let res = add(a, a);

    res_equals(res, Element{ 
        l0: 2251799813685227, 
        l1: 2251799813685247, 
        l2: 2251799813685247, 
        l3: 2251799813685247, 
        l4: 2251799813685247
    });

    true
}

fn tests_scalar_mult() -> bool {
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
    res_equals(res, zero);
    true
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
    res_equals(res, a);
    true
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
    });

    true
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
    });

    true
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
    });
    
    true
}

fn tests_substract() -> bool {
    assert(test_subtraction_by_0());
    assert(test_subtraction_by_1());
    assert(test_subtraction_by_max());
    assert(test_subtraction_random());
    true
}

fn test_subtraction_by_0() -> bool {
    let a = Element{ 
        l0: 2251799813685247, 
        l1: 5, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 100 
    };

    let res: Element = subtract(a, zero);
    res_equals(res, a);
    
    true
}

fn test_subtraction_by_1() -> bool {
    let a = Element{ 
        l0: 2251799813685247, 
        l1: 5, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 100 
    };

    let b = Element{ 
        l0: 2251799813685246, 
        l1: 5, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 100 
    };

    let res: Element = subtract(a, one);
    res_equals(res, b);
    //print_el(res);
    true
}

fn test_subtraction_by_max() -> bool {

    //using GP-PARI one can convert a number into arbitrary base using the command digits(number, base)

    /*
    2^255 - 21  = 57896044618658097711785492504343953926634992332820282019728792003956564819947
                = [2251799813685247, 2251799813685247, 2251799813685247, 2251799813685247, 2251799813685227]
                = Element {
                    2251799813685227,
                    2251799813685247,
                    2251799813685247,
                    2251799813685247,
                    2251799813685247
                }
    */

    let a = Element{ 
        l0: 2251799813685227, 
        l1: 2251799813685247, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 2251799813685247 
    };

    /*
    2^255 - 20  = 57896044618658097711785492504343953926634992332820282019728792003956564819948
                = [2251799813685247, 2251799813685247, 2251799813685247, 2251799813685247, 2251799813685228]
                = Element {
                    2251799813685228,
                    2251799813685247,
                    2251799813685247,
                    2251799813685247,
                    2251799813685247
                }
    */
    
    let b = Element {
                    l0: 2251799813685228,
                    l1: 2251799813685247,
                    l2: 2251799813685247,
                    l3: 2251799813685247,
                    l4: 2251799813685247
                };
    
    let res: Element = subtract(a, b);
    let res2: Element = subtract(b,a);
    res_equals(res, b);
    res_equals(res2, one);
    true
}

fn test_subtraction_random() -> bool {
    /*
    subtraction of random 2 numbers generated using GP-PARI

    a = random({2^251}) = 1300760531839662334344262085631565818852980666446405835776058138544728770104
                        = [50591579140481, 601879629470779, 595911506101250, 1303372017735434, 1292655137982008]
                        = Element {
                        1292655137982008,
                        1303372017735434,
                        595911506101250,
                        601879629470779,
                        50591579140481
                        }

    b = random({2^251}) = 3527794837033309378261417350654351403080646879795459845564282655359926745351
                        = [137209507300112, 293961277766182, 335483569739384, 807899991388824, 1360902863141127]
                        = Element {
                        1360902863141127,
                        807899991388824,
                        335483569739384,
                        293961277766182,
                        137209507300112
                        }

    b - a               = 2227034305193647043917155265022785584227666213349054009788224516815197975247
                        = [86617928159630, 1943881461980650, 1991371877323381, 1756327787338638, 68247725159119]
                        = Element {
                            68247725159119,
                            1756327787338638,
                            1991371877323381,
                            1943881461980650,
                            86617928159630
                        }
    a - b + p           = 55669010313464450667868337239321168342407326119471228009940567487141366844702
                        = [2165181885525617, 307918351704597, 260427936361866, 495472026346609, 2183552088526110]
                        = Element {
                            2183552088526110,
                            495472026346609,
                            260427936361866,
                            307918351704597,
                            2165181885525617
                        }
    */

    let a = Element {
        l0: 1292655137982008,
        l1: 1303372017735434,
        l2: 595911506101250,
        l3: 601879629470779,
        l4: 50591579140481
    };

    let b = Element {
        l0: 1360902863141127,
        l1: 807899991388824,
        l2: 335483569739384,
        l3: 293961277766182,
        l4: 137209507300112
    };

    let a_minus_b = Element {
        l0: 2183552088526110,
        l1: 495472026346609,
        l2: 260427936361866,
        l3: 307918351704597,
        l4: 2165181885525617
    };

    let b_minus_a = Element {
        l0: 68247725159119,
        l1: 1756327787338638,
        l2: 1991371877323381,
        l3: 1943881461980650,
        l4: 86617928159630
    };

    let res: Element = subtract(a, b);
    let res2: Element = subtract(b,a);
    res_equals(res, a_minus_b);
    res_equals(res2, b_minus_a);
    //print_el(res2);
    true
}

fn tests_multiply() -> bool {
    //assert(test_multiply_by_0());
    //assert(test_multiply_by_1());
    true
}

fn test_multiply_by_0() -> bool {

    //a = 2^255 - 21
    let a = Element{ 
        l0: 2251799813685227, 
        l1: 2251799813685247, 
        l2: 2251799813685247,
        l3: 2251799813685247,
        l4: 2251799813685247 
    };
    let res: Element = multiply(a, zero);
    res_equals(res, zero);
    true
}


fn tests_multiply64() -> bool {
    assert(test_multiply64_random());
    true
}

fn test_multiply64_random()-> bool{
    let a = 9837491998535547791;
    let b = 10009796384580774444;
/*
a*b = 98471291840283423519614919326553453204
    = [5338139427034470684, 5960040633016627860]
*/
    let ab: U128 = U128 {
        upper: 5338139427034470684,
        lower: 5960040633016627860
    };

    let res = multiply64(a, b);
    assert(res == ab);
    //print_U128(res);

    true
}

//---------------------------------------------------------------------------------------------------------------
// fn test_multiply_by_1() -> bool {

//     //a = 2^255 - 21
//     let a = Element{ 
//         l0: 2251799813685227, 
//         l1: 2251799813685247, 
//         l2: 2251799813685247,
//         l3: 2251799813685247,
//         l4: 2251799813685247
//     };
//     let res: Element = multiply(a, one);
//     res_equals(res, a);
//     true
// }