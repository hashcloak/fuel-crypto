script;

dep big_uint;
dep helpers;

use ::big_uint::*;
use ::helpers::*;

use std::{vec::Vec, option::*, assert::assert, math::*};
use std::logging::log;
use core::num::*;

/*
All tests for bignum lib
*/
fn main() {
    assert(biguint_addition_tests()); 
    assert(biguint_subtraction_tests());
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

    assert(biguint_subtraction_from_0());
    assert(biguint_subtraction_to_0());

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