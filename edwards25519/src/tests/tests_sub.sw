library tests_sub;

use ::field_element::*;
use std::assert::assert;
use ::test_helpers::*;

pub fn tests_substract() -> bool {
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

    let res: Element = subtract(a, ZERO);
    res_equals(res, a)
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

    let res: Element = subtract(a, ONE);
    res_equals(res, b)
}

fn test_subtraction_by_max() -> bool {

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
    res_equals(res, b) && res_equals(res2, ONE)
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
    res_equals(res, a_minus_b) && res_equals(res2, b_minus_a)
}