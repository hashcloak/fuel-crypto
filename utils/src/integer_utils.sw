library;

use std::{u128::U128};

pub fn adc(a: u64, b: u64, carry: u64) -> (u64, u64) {
    let res = U128::from((0, a)) + U128::from((0, b)) + U128::from((0, carry));
    (res.lower, res.upper)
}

// TODO rewrite without if branch. This one is used with variable a and b
// If x >= y: x-y, else max::U128 - (y-x)
pub fn subtract_wrap(x: U128, y: U128) -> U128 {
    if y > x {
        (U128::max() - (y - x)) + U128::from((0,1))
    } else {
        x - y
    }
}

/// Compute a - (b + borrow), returning the result and the new borrow as (result, borrow)
pub fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64) {
    let a_128: U128 = U128::from((0, a));
    let b_128: U128 = U128::from((0, b));
    let borrow_128: U128 = U128::from((0, borrow >> 63));

    let res: U128 = subtract_wrap(a_128, b_128 + borrow_128);
    (res.lower, res.upper)
}

//returns the result and new carry of a + b*c + carry as (result, carry)
pub fn mac(a: u64, b: u64, c: u64, carry: u64) -> (u64, u64) {
    let a_128: U128 = U128::from((0, a));
    let b_128: U128 = U128::from((0, b));
    let c_128: U128 = U128::from((0, c));
    let carry_128: U128 = U128::from((0, carry));

    let res: U128 = a_128 + (b_128 * c_128) + carry_128;
    (res.lower, res.upper)
}