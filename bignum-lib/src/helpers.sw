library helpers;

use std::{option::*, vec::Vec};
use std::logging::log;

pub fn unpack_or_0 (x: Option<u32>) -> u32 {
    match x {
        Option::Some(val) => val ,
        Option::None => 0,
    }
}

pub trait Zero {
    fn is_zero(self) -> bool;
}

pub fn copy_vec_from_to(vec: Vec<u32>, start: u64, end: u64) -> Vec<u32> {
    let mut res_vec: Vec<u32> = ~Vec::new::<u32>();
    let mut i = start;
    while i < end {
        res_vec.push(unpack_or_0(vec.get(i)));
        i += 1;
    }
    res_vec
}

// Vectors are not yet mutable, so we create a new one and fill it up until possible trailing zeroes
pub fn normalized(vec: Vec<u32>) -> Vec<u32> {
    let mut most_significant_bit_index = vec.len() - 1;
    let mut index_found = false;
    while !index_found && most_significant_bit_index > 0 {
        if (unpack_or_0(vec.get(most_significant_bit_index)) != 0) {
            index_found = true;
        } else {
            most_significant_bit_index = most_significant_bit_index - 1;
        }
    }

    let mut normalized_res: Vec<u32> = ~Vec::new::<u32>();
    let res_is_zero = most_significant_bit_index == 0 && unpack_or_0(vec.get(0)) == 0;
    if(!res_is_zero) {
        let mut j = 0;
        while j <= most_significant_bit_index {
            normalized_res.push(unpack_or_0(vec.get(j)));    
            j = j + 1;
        }

    }
    normalized_res
}


// TODO remove, just for testing
pub fn print_vec(vec: Vec<u32>) {
    let mut i = 0;
    while i < vec.len() {
        log(unpack_or_0(vec.get(i)));
        i += 1;
    }
}