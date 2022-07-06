script;

dep fp;
dep test_helpers;

use std::{assert::assert};
use ::fp::*;
use ::test_helpers::*;
use std::logging::log;

fn main() {
    assert(test_add());
}

fn test_add() -> bool {
    assert(test_add_zero_to_zero());
    assert(test_add_zero_to_random());
    assert(test_add_random_to_zero());
    assert(test_add_random_to_small());
    assert(test_add_random_to_large());
    // assert(test_add_2_randoms());
    true
}

fn test_add_zero_to_zero() -> bool {
    let res: Fp = ZERO.add(ZERO);
    equals_fp(res, ZERO);
    true
}

fn test_add_zero_to_random() -> bool {
    let random = Fp {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a,
        0xdc70c19599cb699e,
        0xebefda8057d5747a,
        0xcf20e11f0b1c323,
        0xe979cbf960fe51d]
    };
    let res: Fp = random.add(ZERO);
    equals_fp(res, random);
    true
}

fn test_add_random_to_zero() -> bool {
    let random = Fp {
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
    let res: Fp = ZERO.add(random);
    equals_fp(res, random);
    true
}

fn test_add_random_to_small() -> bool {
    let small = Fp {
        ls: [0x1, 0x2, 0x3, 0x4, 0x5, 0x6]
    };
    let random = Fp {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a,
        0xdc70c19599cb699e,
        0xebefda8057d5747a,
        0xcf20e11f0b1c323,
        0xe979cbf960fe51d]
    };
    let res: Fp = small.add(random);
    equals_fp(res, Fp {
        ls: [4478030004447473543,
        2814704111667093004,
        15884408734010272161,
        17001047363111187582,
        932823543034528552,
        1051481384684610851]
    });
    true
}

// TODO continue here and next test
fn test_add_random_to_large() -> bool {
    let large = Fp {
        ls: [~u64::max(), ~u64::max(), ~u64::max(), ~u64::max(), ~u64::max(), ~u64::max()]
    };
    let random = Fp {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a,
        0xdc70c19599cb699e,
        0xebefda8057d5747a,
        0xcf20e11f0b1c323,
        0xe979cbf960fe51d]
    };
    let res: Fp = large.add(random);
    print_fp(res);

    true
}

fn test_add_2_randoms() -> bool {
    let random_1 = Fp {
        ls: [0x3e2528903ca1ef86,0x270fd67a03bf9e0a,0xdc70c19599cb699e,0xebefda8057d5747a,0xcf20e11f0b1c323,0xe979cbf960fe51d]
    };

    let random_2 = Fp {
        ls: [0xbaf0ad04a3886e99,0x332e25612ced0991,0x8e95f86c79cd2d4,0xc27bdcacbb447470,0xe7dfe7df4c4d002c,0x7b33227cbdf0de43]
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
    let res: Fp = random_1.add(random_2);
    print_fp(res);
// this seems to be incorrect
    true
}