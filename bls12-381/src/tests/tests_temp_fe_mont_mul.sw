library tests_temp_fe_mont_mul;

use ::vect::*;
use std::{assert::assert, vec::Vec};
use ::test_helpers::*;

pub fn tests_temp_fe_mont_mul() -> bool {
    assert(test_temp_mul_random_by_random());
    true
}

fn test_temp_mul_random_by_random() -> bool {
    let mut p_vec = ~Vec::new::<u64>();
    p_vec.push(0xb9feffffffffaaab);
    p_vec.push(0x1eabfffeb153ffff);
    p_vec.push(0x6730d2a0f6b0f624);
    p_vec.push(0x64774b84f38512bf);
    p_vec.push(0x4b1ba7b6434bacd7);
    p_vec.push(0x1a0111ea397fe69a);
    
    //28700440645560700010247999350858186656965165501286811298915027297835050275063552879691348405696442872566701753802544
    let mut r1_vec = ~Vec::new::<u64>();
    r1_vec.push(6071868568151433008);
    r1_vec.push(12105094901188801210);
    r1_vec.push(2389211775905699303);
    r1_vec.push(7838417195104481535);
    r1_vec.push(5826366508043997497);
    r1_vec.push(13436617433956842131);
    //845585313160814446158446407435059620350609671735802091463220815564059525214346533476776130630310896229502998576879
    let mut r2_vec = ~Vec::new::<u64>();
    r2_vec.push(16964885827015180015);
    r2_vec.push(12035734743809705289);
    r2_vec.push(10517060043363161601);
    r2_vec.push(1119606639881808286);
    r2_vec.push(2211903887497377980);
    r2_vec.push(395875676649998273);

    // a * b mod p
    //941779891765169534644661530249600716619032215997678548055171344032200486581648291416343986992810576160191745532577
    //[16494539950903960225, 6909894500484332639, 10854278113294925999, 10279541547892741855, 12499445441687670930, 440910865060157199]
    let a_mont = fe_to_mont(r1_vec);
    let b_mont = fe_to_mont(r2_vec);
    let res = temp_fe_mont_mul(a_mont, b_mont);
    let res_norm = fe_to_norm(res);
    print_vec(res_norm);
/*
current output...
18417799008695130381
18138064264643904941
8275434384499309183
7900175912883409568
10537467630215797999
*/
    true
}

/*
Note: from the reference impl, you can see it's being tested as follows:


            let a_big = rnd_big_mod_n();
            let b_big = rnd_big_mod_n();
            fe_to_mont(&mut a_mont, &big_to_6u64(&a_big));
            fe_to_mont(&mut b_mont, &big_to_6u64(&b_big));

            let expected = (&a_big * &b_big) % &(*N_BIG);
            fe_mont_mul(&mut actual_mont, &a_mont, &b_mont);

            fe_to_norm(&mut actual_norm, &actual_mont);
            assert_eq!(big_to_6u64(&expected), actual_norm);

So there is a conversion to and from the mont form
*/
