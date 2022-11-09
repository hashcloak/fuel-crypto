library integer_utils;

use std::{u128::U128};

//returns a + b + carry as (result, carry)
pub fn adc(a: u64, b: u64, carry: u64) -> (u64, u64) {
    let a_128: U128 = U128::from((0, a));
    let b_128: U128 = U128::from((0, b));
    let carry_128: U128 = U128::from((0, carry));

    let sum = a_128 + b_128 + carry_128;
    (
        sum.lower,
        sum.upper,
    )
}