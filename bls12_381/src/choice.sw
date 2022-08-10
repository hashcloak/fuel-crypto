library choice;

use std::{option::Option, u128::*};
use core::ops::BitwiseAnd;

/////////////// IMPORTANT<start> ///////////////

// All of this is coming from the dalek cryptograhpy project
// see https://github.com/dalek-cryptography/subtle/blob/main/src/lib.rs

// The intention is that these implementations will provide constant time functionality.
// However, it's not clear how to achieve this in Sway. 
// So we use the traits and names, but have to fill out the correct implementations when we know have
// and Sway supports this. 

/////////////// IMPORTANT<end> ///////////////

/// The `Choice` struct represents a choice for use in conditional assignment.
///
/// It is a wrapper around a `u8`, which should have the value either `1` (true)
/// or `0` (false).

pub struct Choice { c: u8 }

impl Choice {
    pub fn unwrap_u8(self) -> u8 {
        self.c
    }

    pub fn unwrap_as_bool(self) -> bool {
        self.c == 1u8
    }

    pub fn from(input: u8) -> Choice {
        Choice{ c: input}
    }

    pub fn from_bool(b: bool) -> Choice {
        if b {
            Choice{ c: 1u8}
        } else {
            Choice{ c: 0u8}
        }
    }
}

impl BitwiseAnd for u8 {
    fn binary_and(self, other: Self) -> Self {
        asm(r1: self, r2: other, r3) {
            and r3 r1 r2;
            r3: u8
        }
    }
}

impl BitwiseAnd for Choice {
    fn binary_and(self, other: Self) -> Self {
        ~Choice::from(self.c & other.c)
    }
}


/// The `CtOption<T>` type represents an optional value similar to the
/// [`Option<T>`](core::option::Option) type but is intended for
/// use in constant time APIs.

pub struct CtOption<T> {
    value: T,
    is_some: Choice,
}

impl<T> CtOption<T> {
    /// This method is used to construct a new `CtOption<T>` and takes
    /// a value of type `T`, and a `Choice` that determines whether
    /// the optional value should be `Some` or not. If `is_some` is
    /// false, the value will still be stored but its value is never
    /// exposed.
    pub fn new(value: T, is_some: Choice) -> CtOption<T> {
        CtOption {
            value: value,
            is_some: is_some,
        }
    }

    pub fn new_from_bool(value: T, is_some: bool) -> CtOption<T> {
        match is_some {
            true => CtOption {value: value, is_some: Choice{ c: 1 },},
            false => CtOption {value: value, is_some: Choice{ c: 0 },},
        }
    }

    pub fn is_none(self) -> bool {
        !self.is_some.unwrap_as_bool()
    }

    pub fn unwrap(self) -> T {
        self.value
    }
}

// impl<T> From<CtOption<T>> for Option<T> {
//     fn from(source: CtOption<T>) -> Option<T> {
//         if source.is_some().unwrap_u8() == 1u8 {
//             Option::Some(source.value)
//         } else {
//             None
//         }
//     }
// }

// This should have constant time implementations, but not sure atm how to do this in Sway
pub trait ConditionallySelectable {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self;
}

// From https://github.com/dalek-cryptography/subtle/blob/main/src/lib.rs
pub trait ConstantTimeEq {
    fn ct_eq(self, other: Self) -> Choice;
}

fn add_wrap_64(a: u64, b :u64) -> u64 {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    (a_128 + b_128).lower
}

pub fn wrapping_neg(a: u64) -> u64 {
   add_wrap_64(~u64::max() - a, 1)
}

impl ConstantTimeEq for u64 {
    fn ct_eq(self, other: u64) -> Choice {
        // comments from reference impl
        // x == 0 if and only if self == other
        let x: u64 = self ^ other;

        // If x == 0, then x and -x are both equal to zero;
        // otherwise, one or both will have its high bit set.
        let y: u64 = (x | wrapping_neg(x)) >> 63;

        // Result is the opposite of the high bit (now shifted to low).
        let res: u8 = y ^ (1u64);
        ~Choice::from(res)
    }
}