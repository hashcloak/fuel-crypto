library tests_helpers64;

use ::field_element::*;
use std::assert::assert;
use ::test_helpers::*;
use std::u128::*;

pub fn test_helpers64() -> bool {
    assert(tests_multiply64());
    assert(tests_add64());
    assert(tests_add_multiply64());
    true
}


fn tests_multiply64() -> bool {
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

    true
}

fn tests_add64() -> bool {
    assert(test_add64_random());
    assert(test_add64_random_with_carry());
    true
}

fn test_add64_random() -> bool {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let res:(u64,u64) = add64(a, b, 0);
    let a_plus_b: (u64,u64) = (1400544309406770619, 1);

    assert(res.0 == a_plus_b.0);
    assert(res.1 == a_plus_b.1);
    true
}

fn test_add64_random_with_carry() -> bool {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let res:(u64,u64) = add64(a, b, 1);
    let a_plus_b_and_carry: (u64,u64) = (1400544309406770620, 1);

    assert(res.0 == a_plus_b_and_carry.0);
    assert(res.1 == a_plus_b_and_carry.1);
    true
}

fn tests_add_multiply64() -> bool {
    assert(test_add_multiply64());
    assert(test_add_multiply64_2());
    true
}

fn test_add_multiply64() -> bool {
    let a = 496009164746885;
    let b = 24764068336973246;
    //ab=12283204851556881218686606838710

    let r = U128{upper: 2516888776885, lower: 8614063320694916486};
    //r=46428403129198069714856710112646

    // should be 
    //58711607980754950933543316951356
    //[10881738262824685884, 3182762646142]
    let mut res = add_multiply64(r,a,b);
    equals_u128(res, 10881738262824685884, 3182762646142)
}

fn test_add_multiply64_2() -> bool {
    let a = 24764068336973246;
    let b = 137209507300112;
    //ab=3397865615262403032595436803552

    // r= 1759178078333803271346890843016
    //[16956620749643293576, 95365234715]
    let r = U128{upper: 95365234715, lower: 16956620749643293576};

    // should be 
    //5157043693596206303942327646568
    //[18148778710141221224, 279563898809]
    let mut res = add_multiply64(r,a,b);

    equals_u128(res, 18148778710141221224, 279563898809)
}