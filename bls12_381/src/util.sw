library util;

use utils::choice::{Choice, ConditionallySelectable, CtOption, wrapping_neg};
use utils::integer_utils::adc; 
use std::{u128::U128};
use core::ops::{BitwiseXor};
use core::num::*;
use std::flags::{disable_panic_on_overflow, enable_panic_on_overflow};

// If input == 0u64, return 1. Otherwise return 0. 
// Done in assembly, because natively comparison becomes a bool. 
pub fn is_zero_u64(input: u64) -> u64 {
    asm(r1: input, r2) {// set register 1 (r1) to value input, and allocate r2
        eq r2 r1 zero; // r2 = r1 == zero
        r2: u64 // return r2 as a u64
    }
}

// TODO rewrite without if branch. This one is used with variable a and b
// If x >= y: x-y, else max::U128 - (y-x)
pub fn subtract_wrap(x: U128, y: U128) -> U128 {
    if y > x {
        U128::max() - (y - x - U128 {
            lower: 1,
            upper: 0,
        })
    } else {
        x - y
    }
}

// ** tailored to input x = 0 or x = 1 **
// subtract 1 and wrap if necessary. Returns 0 (when x=1) or u64::max (when x=0)
pub fn subtract_1_wrap(x: u64) -> u64 {
    /*
        Normally, Sway panics when underflow or overflow occurs.
        Therefore, to implement this function we need to temporary allow overflow.
        After completing the computations, the flag is set back to default

        - See example use of enabling overflow here: https://github.com/FuelLabs/sway/blob/master/sway-lib-std/src/u128.sw
        - See definition $of (used in the assembly portion of the code) here: https://github.com/FuelLabs/fuel-specs/blob/master/specs/vm/main.md
    */

    disable_panic_on_overflow(); 
    let res = asm(underflow, r1: x, r2, r3) { // set register 1 (r1) to value x, and allocate registers underflow, r2, r3
        subi r2 r1 i1; // r2 = r1 - 1 = x - 1
        move underflow of; // move the underflow (which goes into $of automatically) to a variable (named overflow)
        or r3 r2 underflow; // if 1-1 then this is (0 | 0 = 0), else if 0-1 this is (0 | u64::max = u64::max)
        r3
    };
    enable_panic_on_overflow();
    res
}

/// Compute a - (b + borrow), returning the result and the new borrow as (result, borrow)
pub fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64) {
    let a_128: U128 = U128::from((0, a));
    let b_128: U128 = U128::from((0, b));
    let borrow_128: U128 = U128::from((0, borrow >> 63));

    let res: U128 = subtract_wrap(a_128, b_128 + borrow_128);
    (
        res.lower,
        res.upper,
    )
}

//returns the result and new carry of a + b*c + carry as (result, carry)
pub fn mac(a: u64, b: u64, c: u64, carry: u64) -> (u64, u64) {
    let a_128: U128 = U128::from((0, a));
    let b_128: U128 = U128::from((0, b));
    let c_128: U128 = U128::from((0, c));
    let carry_128: U128 = U128::from((0, carry));

    let res: U128 = a_128 + (b_128 * c_128) + carry_128;
    (
        res.lower,
        res.upper,
    )
}

//returns a*b mod 2^64
pub fn wrapping_mul(a: u64, b: u64) -> u64 {
    let a_128: U128 = U128::from((0, a));
    let b_128: U128 = U128::from((0, b));
    (a_128 * b_128).lower
}
