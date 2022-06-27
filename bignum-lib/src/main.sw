script;

dep big_uint;
dep helpers;

use ::big_uint::*;
use ::helpers::*;

use std::{vec::Vec, option::*, assert::assert, math::*};
use std::logging::log;
use core::num::*;

fn main() {
   assert(addition_tests_big_uint()); 
}

fn addition_tests_big_uint() -> bool {
    assert(big_uint_addition());
    assert(big_uint_addition_longer_res());
    true
}

/*
Adding 2 bignums together that should result into a result that is
9 + 3 * 2^32 + 2^64
Which translates into the vector (9, 3, 1)
*/
fn big_uint_addition() -> bool {
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
fn big_uint_addition_longer_res() -> bool {
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