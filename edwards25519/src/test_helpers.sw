library test_helpers;

dep field_element;

use field_element::*;
use std::logging::log;
use std::assert::assert;
use std::u128::*;

pub const ONE: Element = Element {
    l0: 1, l1: 0, l2: 0, l3: 0, l4: 0
};

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

pub fn equals_u128(res: U128, lower: u64, upper: u64) -> bool {
    assert(res.upper == upper);
    assert(res.lower == lower);
    true
}
