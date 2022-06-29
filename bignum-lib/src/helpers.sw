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

// TODO remove, just for testing
pub fn print_vec(vec: Vec<u32>) {
    let mut i = 0;
    while i < vec.len() {
        log(unpack_or_0(vec.get(i)));
        i += 1;
    }
}