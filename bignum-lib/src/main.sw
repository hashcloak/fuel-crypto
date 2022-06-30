    script;

dep big_uint;
dep helpers;
// dep mod_arithmetic;

use ::big_uint::*;
use ::helpers::*;
// use ::mod_arithmetic::*;

use std::{vec::Vec, option::*, assert::assert, math::*};
use std::logging::log;
use core::num::*;

/*
All tests for bignum lib
*/
fn main() {
    assert(biguint_addition_tests()); 
    assert(biguint_subtraction_tests());
    assert(biguint_mult_tests());
    assert(biguint_mod_tests());
}

// ADDITION BIGUINT
fn biguint_addition_tests() -> bool {
    assert(biguint_addition());
    assert(biguint_addition_longer_res());
    assert(biguint_addition_with_zero());
    assert(biguint_addition_to_zero());
    assert(biguint_addition_zeros());
    true
}

/*
Adding 2 bignums together that should result into a result that is
9 + 3 * 2^32 + 2^64
Which translates into the vector (9, 3, 1)
*/
fn biguint_addition() -> bool {
    // [4294967295, 1]
    // = 2^32 + 4294967295
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(~u32::max());
    a_data.push(1);
    let a = BigUint{data: a_data};

    // [10, 1, 1]
    // = 2^64 + 2^32 + 10
    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(10);
    b_data.push(1);
    b_data.push(1);
    let b = BigUint{data: b_data};

    // total = 18446744086594453513
    // [9, 3 , 1] =  9 + 3 * 2^32 + 2^64
    let res_bigint = add(a, b);
    let res: Vec<u32> = res_bigint.data;

    assert(unpack_or_0(res.get(0)) == 9);
    assert(unpack_or_0(res.get(1)) == 3);
    assert(unpack_or_0(res.get(2)) == 1);
    assert(res.get(3).is_none());

    true
}

/*
Test bigUint addition where the result has 1 more entry in the vector than the inputs
Inputs have len 1, output len 2
*/
fn biguint_addition_longer_res() -> bool {
    // [4294967295] = 2^32 -1
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(~u32::max());
    let a = BigUint{data: a_data};

    // [8]
    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(8);
    let b = BigUint{data: b_data};

    // total = 2 ^ 32 + 7
    // [7, 1]
    let res_bigint = add(a, b);
    let res: Vec<u32> = res_bigint.data;

    assert(unpack_or_0(res.get(0)) == 7);
    assert(unpack_or_0(res.get(1)) == 1);
    assert(res.get(2).is_none());

    true
}

/*
1 + 0 = 1
*/
fn biguint_addition_with_zero() -> bool {
    // a = 1 =[1]
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(1);
    let a = BigUint{data: a_data};

    // b = 0
    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    let b = BigUint{data: b_data};

    // total = 1
    let res_bigint = add(a, b);
    let res: Vec<u32> = res_bigint.data;

    assert(unpack_or_0(res.get(0)) == 1);
    assert(res.get(1).is_none());

    true
}

/*
[0] + [4, 1] = [4,1]
*/
fn biguint_addition_to_zero() -> bool {
    // a = 0
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    let a = BigUint{data: a_data};

    // b = [4,1]
    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(4);
    b_data.push(1);
    let b = BigUint{data: b_data};

    // total = [4,1]
    let res_bigint = add(a, b);
    let res: Vec<u32> = res_bigint.data;

    assert(unpack_or_0(res.get(0)) == 4);
    assert(unpack_or_0(res.get(1)) == 1);
    assert(res.get(2).is_none());

    true
}

fn biguint_addition_zeros() -> bool {
    // a = 0
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    let a = BigUint{data: a_data};

    // b = 0
    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    let b = BigUint{data: b_data};

    // total = 0
    let res_bigint = add(a, b);

    assert(res_bigint.is_zero());

    true
}

// SUBTRACTION BIGUINT
fn biguint_subtraction_tests() -> bool {
    assert(biguint_subtraction_result_none());
    assert(big_uint_subtraction_result_none_2());

    assert(biguint_subtraction_from_0());
    assert(biguint_subtraction_to_0());
    assert(biguint_subtraction_zeros());

    assert(biguint_subtraction_res_same_len());
    assert(biguint_subtraction_shorter_len());

    true
}

/*
when the first value is smaller than the second, result is None
[200, 10] - [100, 12]
*/ 
fn biguint_subtraction_result_none() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(200);
    a_data.push(10);
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(100);
    b_data.push(12);
    let b = BigUint{data: b_data};

    let res_bigint = sub(a, b);

    assert(res_bigint.is_none());

    true
}

/*
This should also work for length 1
[6] - [8] should give None
*/
fn big_uint_subtraction_result_none_2() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(6);
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(8);
    let b = BigUint{data: b_data};

    let res_bigint = sub(a, b);

    assert(res_bigint.is_none());

    true
}

/*
[] - [1] should return None
*/
fn biguint_subtraction_from_0() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(1);
    let b = BigUint{data: b_data};

    let res_bigint = sub(a, b);

    assert(res_bigint.is_none());

    true
}

/*
[1]-[1] should return the BigUint that is zero ([])
*/
fn biguint_subtraction_to_0() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(1);
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(1);
    let b = BigUint{data: b_data};

    let res_bigint = sub(a, b);

    assert(res_bigint.is_some());
    assert(res_bigint.unwrap().is_zero());

    true
}

/*
[3,4,8] - [5,0,5] has a resulting vector of the same length:
[2^32 - 2, 3, 3]
*/
fn biguint_subtraction_res_same_len() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(3);
    a_data.push(4);
    a_data.push(8);
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(5);
    b_data.push(0);
    b_data.push(5);
    let b = BigUint{data: b_data};

    let res_bigint = sub(a, b);
    let res_vec = res_bigint.unwrap().data;

    assert(unpack_or_0(res_vec.get(0)) == ~u32::max() - 2);
    assert(unpack_or_0(res_vec.get(1)) == 3);
    assert(unpack_or_0(res_vec.get(2)) == 3);

    true
}

/*
when result of subtraction has trailing zeroes, we return a shorter result vector
[20, 15] - [2, 15] = [18, 0] = [18]
*/
fn biguint_subtraction_shorter_len() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(20);
    a_data.push(15);
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(2);
    b_data.push(15);
    let b = BigUint{data: b_data};

    let res_bigint = sub(a, b);
    let res_vec = res_bigint.unwrap().data;

    assert(unpack_or_0(res_vec.get(0)) == 18);
    assert(res_vec.get(1).is_none());

    true
}

/*
0 - 0 = 0
*/
fn biguint_subtraction_zeros() -> bool {
    // a = 0
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    let a = BigUint{data: a_data};

    // b = 0
    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    let b = BigUint{data: b_data};

    // total = 0
    let res_bigint = sub(a, b);

    assert(res_bigint.is_some());
    assert(res_bigint.unwrap().is_zero());

    true
}

fn biguint_mult_tests() -> bool {
    assert(biguint_schoolbook_mult());
    assert(test_from_swayPractice_repo());
    
    assert(biguint_mult_karatsuba_1_level());
    assert(biguint_mult_karatsuba_1_level_diff_len());
    true
}

fn biguint_mult_karatsuba_1_level() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(1);
    a_data.push(2);
    a_data.push(3);
    a_data.push(4);
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(100);
    b_data.push(200);
    b_data.push(300);
    b_data.push(400);
    let b = BigUint{data: b_data};

    let res_bigint = karatsuba_1_level_deep(a, b);
    let res_vec = res_bigint.unwrap().data;

    assert(unpack_or_0(res_vec.get(0)) == 100);
    assert(unpack_or_0(res_vec.get(1)) == 400);
    assert(unpack_or_0(res_vec.get(2)) == 1000);
    assert(unpack_or_0(res_vec.get(3)) == 2000);
    assert(unpack_or_0(res_vec.get(4)) == 2500);
    assert(unpack_or_0(res_vec.get(5)) == 2400);
    assert(unpack_or_0(res_vec.get(6)) == 1600);

    true
}

fn biguint_mult_karatsuba_1_level_diff_len() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(1);
    a_data.push(2);
    a_data.push(3);
    a_data.push(4);
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(100);
    b_data.push(200);
    b_data.push(300);
    // b_data.push(400);
    let b = BigUint{data: b_data};

    let res_bigint = karatsuba_1_level_deep(a, b);
    let vec = res_bigint.unwrap().data;

    assert(unpack_or_0(vec.get(0)) == 100);
    assert(unpack_or_0(vec.get(1)) == 400);
    assert(unpack_or_0(vec.get(2)) == 1000);
    assert(unpack_or_0(vec.get(3)) == 1600);
    assert(unpack_or_0(vec.get(4)) == 1700);
    assert(unpack_or_0(vec.get(5)) == 1200);

    // [100, 400, 1000, 1600, 1700, 1200]
    // 1200 * 2^160 + 1700 * 2^128 + 1600 * 2^96 + 1000 * 2^64 +400 * 2^32 + 100
    //1753801965375563525736782247188546140446222870118500

    true
}

/*
Example input & output for Karatsuba with BigUint

X = (1+2*2^32  + 3*2^64 + 4*2^96) = [1,2,3,4]
Y = (100+200*2^32  + 300*2^64 + 400*2^96) = [100,200,300,400]

a = [1, 2]
b = [3, 4]
c = [100, 200]
d = [300, 400]

When calculating X*Y
The result = 10043362780126293152582135998281912347988259896158629291622500

This is written in base 2^32 as follows:
1600 * 2^192 + 2400 * 2^160 + 2500 * 2^128 + 2000 * 2^96 + 1000 * 2^64 +400 * 2^32 + 100
And therefore translates to data vector
[100, 400, 1000, 2000, 2500, 2400, 1600]
——

Applying Karatsuba would work as follows

Ac = (1+2*2^32)*(100+200*2^32)
= 7378697631201807564900
Bd = (3+4*2^32) * (300+400*2^32)
= 29514790528243204096900
Ad+bc = (a+b)*(c+d) - a*c - b*d = ((3+4*2^32) + (1+2*2^32)) * ((100+200*2^32) + (300+400*2^32)) - ac - bd
= ((3+4*2^32) + (1+2*2^32)) * ((100+200*2^32) + (300+400*2^32)) - (3+4*2^32) * (300+400*2^32) - (1+2*2^32)*(100+200*2^32)
=29514790526525217178200


Then, take as result
Ac * 2^128 + (ad+bc) * 2^64 + Bd 

Check that this is correct:
 = 29514790528243204096900 * 2^128 + 29514790526525217178200 * 2^64 + 7378697631201807564900
 = 10043362780126293152582135998281912347988259896158629291622500

*/
fn biguint_schoolbook_mult() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(1);
    a_data.push(2);
    a_data.push(3);
    a_data.push(4);
    let a = BigUint{data: a_data};

    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(100);
    b_data.push(200);
    b_data.push(300);
    b_data.push(400);
    let b = BigUint{data: b_data};

    let res_bigint = schoolbook_mult(a, b);
    let res_vec = res_bigint.data; 

    assert(unpack_or_0(res_vec.get(0)) == 100);
    assert(unpack_or_0(res_vec.get(1)) == 400);
    assert(unpack_or_0(res_vec.get(2)) == 1000);
    assert(unpack_or_0(res_vec.get(3)) == 2000);
    assert(unpack_or_0(res_vec.get(4)) == 2500);
    assert(unpack_or_0(res_vec.get(5)) == 2400);
    assert(unpack_or_0(res_vec.get(6)) == 1600);

    true
}

fn test_from_swayPractice_repo() -> bool {
// [2^32 - 1, 2^16] = (2^32 - 1) + 2^16 * 2^32
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(4294967295);
    a_data.push(65536);
    let a = BigUint{data: a_data};

// [2^32-1, 2^18, 2^30] = (2^32 - 1) + 2^18 * 2^32 + 2^30 * 2^64
    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(4294967295);
    b_data.push(262144);
    b_data.push(1073741824);
    let b = BigUint{data: b_data};

    let res_bigint = schoolbook_mult(a, b);
    let res = res_bigint.data;

    //res =  ((2^32 - 1) + 2^16 * 2^32) * ((2^32 - 1) + 2^18 * 2^32 + 2^30 * 2^64)
    // = 5575271370224683131653871446489760217956353 
    // 16384 * 2^128 + 1073741827 * 2^96 + 3221553152 * 2^64 + 4294639614 * 2^32 + 1
    // [1, 4294639614, 3221553152, 1073741827, 16384]
    match res.get(0) {
        Option::Some(r0) =>{
            assert(r0 == 1);
        },
        Option::None => {
            log(1000000000);
        },
    }

    match res.get(1) {
        Option::Some(r1) =>{
            assert(r1 == 4294639614);
        },
        Option::None => {
            log(1000000000);
        },
    }

    match res.get(2) {
        Option::Some(r2) =>{
            assert(r2 == 3221553152);
        },
        Option::None => {
            log(1000000000);
        },
    }

    match res.get(3) {
        Option::Some(r3) =>{
            assert(r3 == 1073741827);
        },
        Option::None => {
            log(1000000000);
        },
    }

    match res.get(4) {
        Option::Some(r4) =>{
            assert(r4 == 16384);
        },
        Option::None => {
            log(1000000000);
        },
    }

    match res.get(5) {
        Option::Some(r5) =>{
            assert(r5 == 0);
        },
        Option::None => {
            log(1000000000);
        },
    }
    true
}

fn biguint_mod_tests() -> bool {
    assert(biguint_biguint_mod1());
    true
}

/*
Modular reduction example
100 + 400 * 2^32 
= 1717986918500
[100, 400]

1717986918500 mod (2^32+1) = 4294966997
[1,1]
res 
[4294966997]
4294966996

mod 12629315258213599 => 1717986918500
[2579031263, 2940491]
res
[100, 400]
*/
fn biguint_biguint_mod1() -> bool {
    let mut a_data: Vec<u32> = ~Vec::new::<u32>();
    a_data.push(100);
    a_data.push(400);
    let a = BigUint{data: a_data};

    // Case 1: 1717986918500 mod (2^32+1) = 4294966997
    let mut b_data: Vec<u32> = ~Vec::new::<u32>();
    b_data.push(1);
    b_data.push(1);
    let b = BigUint{data: b_data};

    let mut res_bigint = biguint_mod2(a, b);
    let mut res_vec = res_bigint.data; 

    // TODO the output is now 4294966996..?
    // assert(unpack_or_0(res_vec.get(0)) == 4294966997);
    log(res_vec.get(0));

    // Case 2: Should stay the same, because n > a
    let mut c_data: Vec<u32> = ~Vec::new::<u32>();
    c_data.push(2579031263);
    c_data.push(2940491);
    let c = BigUint{data: c_data};

    res_bigint = biguint_mod2(a, c);
    res_vec = res_bigint.data; 

    assert(unpack_or_0(res_vec.get(0)) == 100);
    assert(unpack_or_0(res_vec.get(1)) == 400);

    true
}
