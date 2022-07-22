library tests_temp_fe_mont_mul;

use ::vect::*;
use std::{assert::assert, vec::Vec};
use ::test_helpers::*;
use std::logging::log;

pub fn tests_temp_fe_mont_mul() -> bool {
    // assert(test_temp_mul_random_by_random());
    assert(test_temp_mul_mont_n());
    true
}

fn test_temp_mul_mont_n() -> bool {
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

    //Sway can't handle this. Error:
    /*
  {
    "Panic": {
      "id": "0000000000000000000000000000000000000000000000000000000000000000",
      "is": 10352,
      "pc": 169804,
      "reason": {
        "instruction": {
          "imm06": 0,
          "imm12": 0,
          "imm18": 0,
          "imm24": 0,
          "op": 96,
          "ra": 0,
          "rb": 0,
          "rc": 0,
          "rd": 0
        },
        "reason": "OutOfGas"
      }
    }
  },
  {
    "ScriptResult": {
      "gas_used": 100000000,
      "result": "Panic"
    }
  }
    */
    let res = temp_mul_mont_n(r1_vec, r2_vec);
    print_vec(res);
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

    // let a_mont = fe_to_mont(r1_vec);
    // print_vec(a_mont);
    /*
17993655965713306301
15604842006860479165
10837926002905938402
13429498400065700031
1823694494885156540
933350646299434799
    */

    // let b_mont = fe_to_mont(r2_vec);
    // print_vec(b_mont);
    /*
5720430457560562798
2568557665684583703
15870134958983808442
14065062413899436375
12262047246709729804
1303068506660090079
    */

    // let res = temp_fe_mont_mul(a_mont, b_mont);
    // print_vec(res);
    /*
8042921339150017446
4899742317194411181
11922910400151252689
7736564210120511729
10892349319971706476
542573957820843489
    */

    /*
    This is what res has as a value at this point, but running all the operations gives the error 
    out of gas, so just run with this known value. All intermediate steps are correct with 
    the ncc ref implementation
    */
    let mut intermediate_res_vec = ~Vec::new::<u64>();
    intermediate_res_vec.push(8042921339150017446);
    intermediate_res_vec.push(4899742317194411181);
    intermediate_res_vec.push(11922910400151252689);
    intermediate_res_vec.push(7736564210120511729);
    intermediate_res_vec.push(10892349319971706476);
    intermediate_res_vec.push(542573957820843489);
    // let res_norm = fe_to_norm(res);
    let res_norm = fe_to_norm(intermediate_res_vec);
    // print_vec(res_norm);
    /*
16494539950903960225 + 
6909894500484332639 * 2^64 +
10854278113294925999 * 2^128 +
10279541547892741855 * 2^192 +
12499445441687670930 * 2^256 +
440910865060157199 *2^320

941779891765169534644661530249600716619032215997678548055171344032200486581648291416343986992810576160191745532577
which is a*b mod p
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
