library choice;


use core::num::*;
use std::{option::Option, u128::U128};
use core::ops::{Eq, BitwiseAnd, BitwiseOr, BitwiseXor};

/////////////// IMPORTANT<start> ///////////////

// All of this is coming from the dalek cryptograhpy project
// see https://github.com/dalek-cryptography/subtle/blob/main/src/lib.rs

/////////////// IMPORTANT<end> ///////////////

/// The `Choice` struct represents a choice for use in conditional assignment.
///
/// It is a wrapper around a `u8`, which should have the value either `1` (true)
/// or `0` (false).
pub struct Choice { c: u8 }

// Can't use name "From" because of collision with trait in U128 (even though not importing u128::*). 
// This seems to be a bug in Sway, see discussion in Discord https://discord.com/channels/732892373507375164/734213700835082330/1007067117029433405
pub trait From {
    fn from(input: u8) -> Self;
    fn into(self) -> u8;
}

impl From for Choice {
    fn from(input: u8) -> Self {
        Choice { c: input  }
    }

    fn into(self) -> u8 {
        self.c
    }
}

// If equals 1u8 => false, if 0u8 => true
pub fn opposite_choice_value(a: u8) -> bool {
    asm(r1: a, r2) {
        eq r2 r1 zero;
        r2: bool
    }
}

impl Choice {
    pub fn unwrap_u8(self) -> u8 {
        self.c
    }

    pub fn unwrap_as_bool(self) -> bool {
        self.c == 1u8
    }
    pub fn from_bool(b: bool) -> Choice {
        if b {
            Choice{ c: 1u8}
        } else {
            Choice{ c: 0u8}
        }
    }
}

impl Choice {
    pub fn not(self) -> Choice {
        ~Choice::from_bool(opposite_choice_value(self.c))
    }
}

impl BitwiseXor for u8 {
    fn binary_xor(self, other: Self) -> Self {
        asm(r1: self, r2: other, r3) {
            xor r3 r1 r2;
            r3: u8
        }
    }
}

impl ConditionallySelectable for u8 {
    fn conditional_select(a: u8, b: u8, choice: Choice) -> u32 {
        let mask = wrapping_neg(choice.unwrap_u8());
        b.binary_xor(mask & (a.binary_xor(b)))
    }
}

impl ConditionallySelectable for Choice {
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        ~Choice::from(~u8::conditional_select(a.c, b.c, choice))
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

impl BitwiseOr for u8 {
    fn binary_or(self, other: Self) -> Self {
        asm(r1: self, r2: other, r3) {
            or r3 r1 r2;
            r3: u8
        }
    }
}

impl BitwiseOr for Choice {
    fn binary_or(self, other: Self) -> Self {
        ~Choice::from(self.c | other.c)
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

    //To reference `is_some` this would have to go in a separate Impl
    pub fn is_none(self) -> bool {
        !self.is_some.unwrap_as_bool()
    }

    pub fn is_some(self) -> bool {
        self.is_some.unwrap_as_bool()
    }

    pub fn unwrap(self) -> T {
        self.value
    }

    // unwrap_or can't be implemented here..
    // There is no type restriction possible on generics in Sway
    // See https://discord.com/channels/732892373507375164/734213700835082330/1007097764242522273
}

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