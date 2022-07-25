library test_helpers;

dep vect;

use vect::*;
use std::{assert::assert, logging::log, vec::Vec};

pub fn print_vec384(a: vec384) {
    log(a.ls[0]);
    log(a.ls[1]);
    log(a.ls[2]);
    log(a.ls[3]);
    log(a.ls[4]);
    log(a.ls[5]);
}

pub fn equals_vec384(a: vec384, b: vec384) {
    assert(a.ls[0] == b.ls[0]);
    assert(a.ls[1] == b.ls[1]);
    assert(a.ls[2] == b.ls[2]);
    assert(a.ls[3] == b.ls[3]);
    assert(a.ls[4] == b.ls[4]);
    assert(a.ls[5] == b.ls[5]);
}

pub fn equals_vec(a: Vec<u64>, b: Vec<u64>, n: u64) -> bool {
    let mut i = 0;
    while i < n {
        assert(unpack_or_0(a.get(i)) == unpack_or_0(a.get(i)));
        i += 1;
    }
    true
}
pub fn print_vec(a: Vec<u64>) {
    let mut i = 0;
    let l = a.len();
    while i < l {
        log(unpack_or_0(a.get(i)));
        i += 1;
    }
}
