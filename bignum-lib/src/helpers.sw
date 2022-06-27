library helpers;

use std::option::*;

pub fn unpack_or_0 (x: Option<u32>) -> u32 {
    match x {
        Option::Some(val) => val ,
        Option::None => 0,
    }
}