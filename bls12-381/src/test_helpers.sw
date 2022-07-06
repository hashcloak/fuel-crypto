library test_helpers;

dep fp;

use fp::*;
use std::{logging::log, assert::assert};

pub fn print_fp(a: Fp) {
    log(a.ls[0]);
    log(a.ls[1]);
    log(a.ls[2]);
    log(a.ls[3]);
    log(a.ls[4]);
    log(a.ls[5]);
}

pub fn equals_fp(a: Fp, b: Fp) {
    assert(a.ls[0] == b.ls[0]);
    assert(a.ls[1] == b.ls[1]);
    assert(a.ls[2] == b.ls[2]);
    assert(a.ls[3] == b.ls[3]);
    assert(a.ls[4] == b.ls[4]);
    assert(a.ls[5] == b.ls[5]);
}