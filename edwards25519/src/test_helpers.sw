library test_helpers;

dep field_element;

use field_element::*;
use std::logging::log;
use std::assert::assert;
use std::u128::*;

pub fn print_el(e: Element) {
    log(e.l0);
    log(e.l1);
    log(e.l2);
    log(e.l3);
    log(e.l4);
}

pub fn res_equals(res: Element, should_be: Element) -> bool {
    assert(res.l0 == should_be.l0);
    assert(res.l1 == should_be.l1);
    assert(res.l2 == should_be.l2);
    assert(res.l3 == should_be.l3);
    assert(res.l4 == should_be.l4);
    true
}

pub fn print_U128(a: U128) {
    log(a.upper);
    log(a.lower);
}

//converts element into array of bytes

// pub fn bytes_convert (a: Element) -> [u8;32] {
//     let a_mod = mod_25519(a);
// }