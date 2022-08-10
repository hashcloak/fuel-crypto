library util;

dep choice; 

use choice::{Choice, CtOption, ConditionallySelectable, wrapping_neg};
use std::{u128::U128};
use core::ops::{BitwiseXor};


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

// TODO rewrite without if branch
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

/// Compute a - (b + borrow), returning the result and the new borrow (0 or 1).
pub fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64) {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let borrow_128: U128 = ~U128::from(0, borrow);

    let res: U128 = subtract_wrap(a_128, b_128 + borrow_128);
    (res.lower, res.upper >> 63) //(result, borrow)
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
