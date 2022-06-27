library big_uint;

dep helpers;
use helpers::*;

use std::{assert::assert, option::*, vec::Vec};
use std::logging::log;
use core::num::*;

/*
Representation of a big unsigned number of arbitrary length

Note: The largest primitive type in Sway is u64, therefore the BigUint consists of a vector with u32 entries.
When 2 BigUints are added, the result might require more than 32 bits and this will fit into a u64. 
*/
pub struct BigUint {
    data: Vec<u32>,
}

fn max(left: u64, right: u64) -> u64 {
    if(left >= right) { left } else { right }
}

/*
returns the result of the 3 numbers added together
*/
fn add_limb(a_i: u32, b_i: u32, carry_i: u32) -> u64 {
    let A_i: u64 = a_i;
    let B_i: u64 = b_i;

    A_i + B_i + carry_i
}

/*
returns the 2 bigUints added together. 

Note: This result might be 1 longer than the longest entry. 
*/
pub fn add(a: BigUint, b: BigUint) -> BigUint {
    let a_vec: Vec<u32> = a.data;
    let b_vec: Vec<u32> = b.data;
    let len_a :u32 = a_vec.len();
    let len_b :u32 = b_vec.len();
    let max_len: u32 = max(len_a, len_b);

    let mut res: Vec<u32> = ~Vec::new::<u32>();
    let mut i = 0;
    let mut carry_i: u32 = 0;
    let mut z: u64 = 0;

    while i < max_len {
        z = add_limb(unpack_or_0(a_vec.get(i)), unpack_or_0(b_vec.get(i)), carry_i);

        res.push(z & 0xffffffff);
        carry_i = ((z>>32) & 0xffffffff);
        i = i + 1;
    }

    if carry_i != 0 {
        res.push(carry_i);
    }

    BigUint{data: res}
}