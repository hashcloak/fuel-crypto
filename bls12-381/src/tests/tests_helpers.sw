library tests_helpers;


use ::fields::*;
use ::vect::*;
use ::test_helpers::*;

use std::{assert::assert, u128::*};

pub fn test_helpers() -> bool {
    assert(test_not());
    assert(tests_subtract_wrap());
    assert(tests_sbb());
    assert(tests_adc());
    assert(test_neg());
    assert(test_subtract_p());
    true
}

fn test_not() -> bool {
    let res = not(18417751708719972248);
    assert(res == 28992364989579367);
    true
}

fn tests_subtract_wrap() -> bool {
    let mut res = subtract_wrap(U128 {
        lower: 100, upper: 0
    },
    U128 {
        lower: 80, upper: 0
    });
    assert(res.lower == 20);
    assert(res.upper == 0);

    res = subtract_wrap(U128 {
        lower: 100, upper: 0
    },
    U128 {
        lower: 230, upper: 0
    });
    let res_should_be = ~U128::max() - U128 {
        lower: 130, upper: 0
    };
    // 2^128 - 230 = 340282366920938463463374607431768211226
    // [18446744073709551486, 18446744073709551615]
    assert(res.lower == 18446744073709551486);
    assert(res.upper == 18446744073709551615);
    true
}

fn tests_sbb() -> bool {
    // 0-0-0 should give (0,0)
    let mut res = sbb(0, 0, 0);
    assert(res.0 == 0);
    assert(res.1 == 0);

    // 0-1-0 should give (2^64 -1, 1)
    res = sbb(0, 1, 0);
    assert(res.0 == ~u64::max());
    assert(res.1 == 1);

    // 0-1-1 should give (2^64 -2, 1)
    res = sbb(0, 1, 1);
    assert(res.0 == ~u64::max() - 1);
    assert(res.1 == 1);

    // a-0-1 should give (a-1, 0)
    let a = 435983458;
    res = sbb(a, 0, 1);
    assert(res.0 == a - 1);
    assert(res.1 == 0);
    true
}

fn tests_adc() -> bool {
    assert(test_adc_random());
    assert(test_adc_random_with_carry());
    true
}

fn test_adc_random() -> bool {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let res: (u64, u64) = adc(a, b, 0);
    let a_plus_b: (u64, u64) = (1400544309406770619, 1);

    assert(res.0 == a_plus_b.0);
    assert(res.1 == a_plus_b.1);
    true
}

fn test_adc_random_with_carry() -> bool {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let res: (u64, u64) = adc(a, b, 1);
    let a_plus_b_and_carry: (u64, u64) = (1400544309406770620, 1);

    assert(res.0 == a_plus_b_and_carry.0);
    assert(res.1 == a_plus_b_and_carry.1);
    true
}

fn test_subtract_p() -> bool {
    assert(test_subtract_p_smaller());
    assert(test_subtract_p_larger());
    true
}

fn test_subtract_p_smaller() -> bool {
    let a_smaller_than_p = vec384 {
        ls: [13402431016077863508,
        2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    };
    let res = subtract_p(a_smaller_than_p, BLS12_381_P);
    equals_vec384(res, a_smaller_than_p);
    true
}

fn test_subtract_p_larger() -> bool {
    // p+200
    let a_larger_than_p = vec384 {
        ls: [13402431016077863795,
        2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    };
    let res = subtract_p(a_larger_than_p, BLS12_381_P);
    equals_vec384(res, vec384 {
        ls: [200, 0, 0, 0, 0, 0]
    });
    true
}

fn test_neg() -> bool {
    assert(test_neg_p());
    assert(test_neg_1());
    assert(test_neg_random());
    true
}

// neg(p, p) should result in 0
fn test_neg_p() -> bool {
    let p = vec384 {
        ls: [0xb9feffffffffaaab,
        0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a]
    };
    let res = neg(p, BLS12_381_P);
    equals_vec384(res, ZERO);
    true
}

fn test_neg_1() -> bool {
    /* p (=BLS12_381_P)
    [13402431016077863595, 
    2210141511517208575, 
    7435674573564081700, 
    7239337960414712511, 
    5412103778470702295, 
    1873798617647539866]
    */
    let res = neg(vec384 {
        ls: [1, 0, 0, 0, 0, 0]
    },
    BLS12_381_P);
    let p_minus_1 = vec384 {
        ls: [13402431016077863594,
        2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    };

    equals_vec384(res, p_minus_1);
    true
}

fn test_neg_random() -> bool {
    //1281534117852017820269267861584320258656990227317793864009951923807317297699607442944495077621627898376663719366433
    //[13059245463466299169, 17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };

    // p-r =
    // 2720875437369649573148521964151583897899892592621214021322106212316714352791230421498192551507387765661230553193354
    let res = neg(r, BLS12_381_P);
    equals_vec384(res, vec384 {
        ls: [343185552611564426, 2882282484148780005, 6545683898001206309, 12914691390957992833, 41210333997197102, 1273825819919628179]
    });
    true
}

fn test_sub_fp() -> bool {
    // assert(test_sub_zero_from_zero());
    // assert(test_sub_zero_from_random());
    // assert(test_sub_random_from_zero());
    // assert(test_sub_random_from_small());
    assert(test_sub_2_randoms());
    assert(test_sub_2_randoms_reverse());
    true
}

fn test_sub_zero_from_zero() -> bool {
    let res = sub_fp(ZERO, ZERO);
    equals_vec384(res, ZERO);
    true
}

fn test_sub_zero_from_random() -> bool {
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };
    let res = sub_fp(r, ZERO);
    equals_vec384(res, r);
    true
}

fn test_sub_random_from_zero() -> bool {
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };
    let res = sub_fp(ZERO, r);
    // p-r (is the same as 0-r mod p)
    equals_vec384(res, vec384 {
        ls: [343185552611564426, 2882282484148780005, 6545683898001206309, 12914691390957992833, 41210333997197102, 1273825819919628179]
    });
    true
}

fn test_sub_random_from_small() -> bool {
    // 1 + 2 *2^64 + 3*2^128 + 4 * 2^192 + 5 * 2^256 + 6 * 2^320
    //12815922215525460494949090683203893664759190466124902882004963575055114655935967659265637031608321
    let small = vec384 {
        ls: [1,
        2, 3, 4, 5, 6]
    };
    //1281534117852017820269267861584320258656990227317793864009951923807317297699607442944495077621627898376663719366433
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };

    let res: vec384 = sub_fp(small, r);
    //result should be 2720875437369649585964444179677044392848983275825107686081296678441617234796193996553307207443355424926867584801675
    //[343185552611564427, 2882282484148780007, 6545683898001206312, 12914691390957992837, 41210333997197107, 1273825819919628185]
    equals_vec384(res, vec384 {
        ls: [343185552611564427, 2882282484148780007, 6545683898001206312, 12914691390957992837, 41210333997197107, 1273825819919628185]
    });
    true
}

fn test_sub_2_randoms() -> bool {
    //a = 1636725880549280067486622211868244649555599468607198938781220718077581339058902572863029175226410795172800087248680
    //[10587454305359941416, 4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194]
    let a = vec384 {
        ls: [10587454305359941416,
        4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194]
    };
    //b = 633982047616931537296775994873240773075794315607478597677958352919546237170580686209956468014669319291596219488262
    //[13403040667047958534, 405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174]
    let b = vec384 {
        ls: [13403040667047958534,
        405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174]
    };
    //res =
    //1002743832932348530189846216995003876479805152999720341103262365158035101888321886653072707211741475881203867760418
    //[15631157712021534498, 4210040059583301456, 2072967503069563536, 7744598167717445820, 16967452369712105079, 469452209245280019]
    let res: vec384 = sub_fp(a, b);
    equals_vec384(res, vec384 {
        ls: [15631157712021534498, 4210040059583301456, 2072967503069563536, 7744598167717445820, 16967452369712105079, 469452209245280019]
    });
    true
}

fn test_sub_2_randoms_reverse() -> bool {
    // Same a,b from test_sub_2_randoms only subtract the other way around
    let a = vec384 {
        ls: [10587454305359941416,
        4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194]
    };
    let b = vec384 {
        ls: [13403040667047958534,
        405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174]
    };

    //res =
    //-1002743832932348530189846216995003876479805152999720341103262365158035101888321886653072707211741475881203867760418
    // => mod p
    //2999665722289318863227943608740900280077077666939287544228795770965996548602515977789614921917274188156690404799369
    //[16218017377765880713, 16446845525643458734, 5362707070494518163, 17941483866406818307, 6891395482468148831, 1404346408402259846]
    let res: vec384 = sub_fp(b, a);
    equals_vec384(res, vec384 {
        ls: [16218017377765880713, 16446845525643458734, 5362707070494518163, 17941483866406818307, 6891395482468148831, 1404346408402259846]
    });
    true
}
