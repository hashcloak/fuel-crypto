library util;

dep choice; 

use choice::{Choice, CtOption, ConditionallySelectable, wrapping_neg};
use std::{u128::U128};
use core::ops::{BitwiseXor};
use core::num::*;
use std::flags::{disable_panic_on_overflow, enable_panic_on_overflow};


impl ConditionallySelectable for u64 {
    fn conditional_select(a: u64, b: u64, choice: Choice) -> u64 {
        // if choice = 0, mask = (-0) = 0000...0000
        // if choice = 1, mask = (-1) = 1111...1111
        let choice_64: u64 = choice.unwrap_u8();
        let mask = wrapping_neg(choice_64);
        b ^ (mask & (a ^ b))
    }
}

impl BitwiseXor for u32 {
    fn binary_xor(self, other: Self) -> Self {
        asm(r1: self, r2: other, r3) {
            xor r3 r1 r2;
            r3: u32
        }
    }
}

impl ConditionallySelectable for u32 {
    fn conditional_select(a: u32, b: u32, choice: Choice) -> u32 {
        let choice_32: u32 = choice.unwrap_u8();
        let mask = wrapping_neg(choice_32);
        b ^ (mask & (a ^ b))
    }
}

// If input == 0u64, return 1. Otherwise return 0. 
// Done in assembly, because natively comparison becomes a bool. 
pub fn is_zero_u64(input: u64) -> u64 {
    asm(r1: input, r2) {
        eq r2 r1 zero;
        r2: u64
    }
}

// TODO rewrite without if branch. This one is used with variable a and b
// See resources below
// If x >= y: x-y, else max::U128 - (y-x)
pub fn subtract_wrap(x: U128, y: U128) -> U128 {
    if y > x {
        ~U128::max() - (y - x - U128 {
            lower: 1, upper: 0
        })
    } else {
        x - y
    }
}

// TODO rewrite without if branch
// In practice this is only being called with fixed values, so we can make it more specific. 
// 1 -1
// 0 -1
// If x >= y: x-y, else max::U64 - (y-x)
pub fn subtract_wrap_64(x: u64, y: u64) -> u64 {
    if y > x {
        ~u64::max() - (y - x - 1)
    } else {
        x - y
    }
}

//
pub fn subtract_1_wrap(x: u64) -> u64 {
    disable_panic_on_overflow();
    let res = asm(underflow, r1: x, r2, r3) {
        subi r2 r1 i1; // x - 1
        move underflow of; // move the underflow to a variable
        or r3 r2 underflow; // if 1-1 then this is 0 | 0 = 0, if 0-1 this is 0 | u64::max
        r3
    };
    enable_panic_on_overflow();
    res
}

/// Compute a - (b + borrow), returning the result and the new borrow.
pub fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64) {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let borrow_128: U128 = ~U128::from(0, borrow >> 63);

    let res: U128 = subtract_wrap(a_128, b_128 + borrow_128);
    (res.lower, res.upper) //(result, borrow)
}

//returns sum with carry of a and b
pub fn adc(a: u64, b: u64, carry: u64) -> (u64, u64) {
    let a_128: U128 =  ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let carry_128: U128 =  ~U128::from(0, carry);

    let sum = a_128 + b_128 + carry_128;
    (sum.lower, sum.upper)
}


//returns the result and new carry of a + b*c + carry
pub fn mac(a: u64, b: u64, c: u64, carry: u64) -> (u64, u64) {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let c_128: U128 = ~U128::from(0, c);
    let carry_128: U128 = ~U128::from(0, carry);

    let res: U128 = a_128 + (b_128 * c_128) + carry_128;
    (res.lower, res.upper)
}

//returns a*b mod(2^64)
pub fn wrapping_mul(a: u64, b: u64) -> u64 {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);

    (a_128 * b_128).lower
}
