script;

dep vec384;
dep fp;
dep test_helpers;

use std::{assert::assert, u128::*};
use ::fp::*;
use ::vec384::*;
use ::test_helpers::*;
use std::logging::log;

fn main() {
    assert(test_add());
    assert(test_helpers());
}

fn test_helpers() -> bool {
    assert(test_not());
    assert(tests_subtract_wrap());
    assert(tests_sbb());
    assert(tests_adc());
    assert(tests_subtract_p());
    true
}

fn test_not() -> bool {
    let res = not(18417751708719972248);
    assert(res == 28992364989579367);
    true
}

fn tests_subtract_wrap() -> bool {
    let mut res = subtract_wrap(U128 { lower: 100, upper: 0}, U128 { lower: 80, upper: 0});
    assert(res.lower == 20);
    assert(res.upper == 0);

    res = subtract_wrap(U128 { lower: 100, upper: 0}, U128 { lower: 230, upper: 0});
    let res_should_be = ~U128::max() - U128 { lower: 130, upper: 0};
    assert(res == res_should_be);
    true
}

fn tests_sbb() -> bool {
    // 0-0-0 should give (0,0)
    let mut res = sbb(0, 0, 0);
    assert(res.0 == 0);
    assert(res.1 == 0);

    // 0-1-0 should give (-1, 1)
    res = sbb(0, 1, 0);
    assert(res.0 == ~u64::max() - 1);
    assert(res.1 == 1);

    // 0-1-1 should give (-2, 1)
    res = sbb(0, 1, 1);
    assert(res.0 == ~u64::max() - 2);
    assert(res.1 == 1);

    // a-0-1 should give (a-1, 0)
    let a = 435983458;
    res = sbb(a, 0, 1);
    assert(res.0 == a-1);
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
    let res:(u64,u64) = adc(a, b, 0);
    let a_plus_b: (u64,u64) = (1400544309406770619, 1);

    assert(res.0 == a_plus_b.0);
    assert(res.1 == a_plus_b.1);
    true
}

fn test_adc_random_with_carry() -> bool {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let res:(u64,u64) = adc(a, b, 1);
    let a_plus_b_and_carry: (u64,u64) = (1400544309406770620, 1);

    assert(res.0 == a_plus_b_and_carry.0);
    assert(res.1 == a_plus_b_and_carry.1);
    true
}

/*
These tests won't run at the same time...
*/
fn tests_subtract_p() -> bool {
    // assert(test_subtract_p_smaller());
    assert(test_subtract_p_larger());
    true
}

fn test_subtract_p_smaller() -> bool {
    let a_smaller_than_p =  vec384 {
        ls: [13402431016077863508,
        2210141511517208575,
        7435674573564081700,
        7239337960414712511,
        5412103778470702295,
        1873798617647539866]
    };
    let res = subtract_p(a_smaller_than_p, BLS12_381_P);
    equals_vec384(res, a_smaller_than_p);
    true
}

fn test_subtract_p_larger() -> bool {
      // p+200
    let a_larger_than_p = vec384 { ls: [13402431016077863795, 
        2210141511517208575, 
        7435674573564081700, 
        7239337960414712511, 
        5412103778470702295, 
        1873798617647539866]};
    let res = subtract_p(a_larger_than_p, BLS12_381_P);
    equals_vec384(res, vec384 { ls: [200,0,0,0,0,0] });
    true
}

fn test_add() -> bool {
    assert(test_add_zero_to_zero());
    assert(test_add_zero_to_random());
    assert(test_add_random_to_zero());
    assert(test_add_random_to_small());
    assert(test_add_larger_than_p());
    assert(test_add_2_randoms());
    true
}

fn test_add_zero_to_zero() -> bool {
    let res: vec384 = add_fp(ZERO, ZERO);
    equals_vec384(res, ZERO);
    true
}

fn test_add_zero_to_random() -> bool {
    let random = vec384 {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a,
        0xdc70c19599cb699e,
        0xebefda8057d5747a,
        0xcf20e11f0b1c323,
        0xe979cbf960fe51d]
    };
    let res: vec384 = add_fp(random, ZERO);
    equals_vec384(res, random);
    true
}

fn test_add_random_to_zero() -> bool {
    let random = vec384 {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a,
        0xdc70c19599cb699e,
        0xebefda8057d5747a,
        0xcf20e11f0b1c323,
        0xe979cbf960fe51d]
    };
    /*
4478030004447473542
2814704111667093002
15884408734010272158
17001047363111187578
932823543034528547
1051481384684610845
    */
    let res: vec384 = add_fp(ZERO, random);
    equals_vec384(res, random);
    true
}

fn test_add_random_to_small() -> bool {
    let small = vec384 {
        ls: [0x1, 0x2, 0x3, 0x4, 0x5, 0x6]
    };
    let random = vec384 {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a,
        0xdc70c19599cb699e,
        0xebefda8057d5747a,
        0xcf20e11f0b1c323,
        0xe979cbf960fe51d]
    };
    let res: vec384 = add_fp(small, random);
    equals_vec384(res, vec384 {
        ls: [4478030004447473543,
        2814704111667093004,
        15884408734010272161,
        17001047363111187582,
        932823543034528552,
        1051481384684610851]
    });
    true
}

fn test_add_larger_than_p() -> bool {
    /*
    4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559700
    +
    100
    is a little bit larger than p
    */
    //[13402431016077863508, 2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    let a = vec384 {
        ls: [13402431016077863508,
        2210141511517208575,
        7435674573564081700,
        7239337960414712511,
        5412103778470702295,
        1873798617647539866]
    };

    let b = vec384 { ls: [100,0,0,0,0,0] };

// should be 13
    let res: vec384 = add_fp(a, b);
    equals_vec384(res, vec384 {ls: [13,0,0,0,0,0]});
    true
}

fn test_add_2_randoms() -> bool {
    //[4510245898505151773, 8849327944066866226, 11451510199254766964, 782624411996506985, 9666712539018543006, 17492304704872943]
    let random_1 = vec384 {
        ls: [4510245898505151773,
        8849327944066866226,
        11451510199254766964,
        782624411996506985,
        9666712539018543006,
        17492304704872943]
    };

//[8877477209635348035, 16708328088811667500, 14014037299927741552, 1795070958963053268, 10606788931721547929, 841903545056265961]
    let random_2 = vec384 {
        ls: [8877477209635348035, 
        16708328088811667500, 
        14014037299927741552, 
        1795070958963053268, 
        10606788931721547929, 
        841903545056265961]
    };
/*
a=37363336077986948456666213736586466128287562369519105825429602984091321919274233302919361890839579644111801541917
b=1798295057736039902482424641059918570220554796267905001254827923367760771974871956830417883729301310309317980773955
a+b=1835658393814026850939090854796505036348842358637424107080257526351852093894146190133337245620140889953429782315872
[13387723108140499808, 
7110911959168982110, 
7018803425472956901, 
2577695370959560254, 
1826757397030539319, 
859395849761138905]

a+b< p is true
*/
    let res: vec384 = add_fp(random_1, random_2);
    equals_vec384(res, vec384{ ls: [13387723108140499808, 
        7110911959168982110, 
        7018803425472956901, 
        2577695370959560254, 
        1826757397030539319, 
        859395849761138905] });
    true
}