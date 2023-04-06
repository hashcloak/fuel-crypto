library;

/*
Copyright (c) 2016-2017 Isis Agora Lovecruft, Henry de Valence. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

use std::convert::From;
use std::{option::Option, u128::U128, assert::assert};
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

// Conversion Choice <-> u8
impl From<u8> for Choice {
    fn from(input: u8) -> Self {
        Choice { c: input  }
    }

    fn into(self) -> u8 {
        self.c
    }
}

// returns false if a == 1, true if a == 0
pub fn opposite_choice_value(a: u8) -> bool {
    // using assembly to avoid if branch
    asm(r1: a, r2) { // setting register 1 (r1) to value a and allocating r2
        eq r2 r1 zero; // r2 = (r1 == zero)
        r2: bool // return r2 as a bool
    }
}

// Choice (instead of standard 'bool') is intended to be constant time
impl Choice {
    // Get the u8 out of the Choice
    pub fn unwrap_u8(self) -> u8 {
        self.c
    }

    // Unwrap the Choice as a boolean value
    pub fn unwrap_as_bool(self) -> bool {
        self.c == 1u8
    }

    // Create a Choice instance from a bool. 
    // true -> Choice { c: 1u8 }
    // false -> Choice { c: 0u8 }
    pub fn from_bool(b: bool) -> Choice {
        // using assembly to avoid if branch
        let b_as_u8 = asm(r1: b) { // set register 1 (r1) to value b
            r1: u8 //simply read the bool as a u8
        };
        Choice{ c: b_as_u8 }
    }
}

impl Choice {
    // return a Choice with the opposite internal value (1u8 or 0u8)
    pub fn not(self) -> Choice {
        Choice::from_bool(opposite_choice_value(self.c))
    }
}

// This trait intends to do conditional selection in constant time
pub trait ConditionallySelectable {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self;
}

impl ConditionallySelectable for u8 {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: u8, b: u8, choice: Choice) -> u8 {
        // If choice == 0, mask = 00...00
        // Else if choice == 1, mask = 11..11
        let mask = wrapping_neg(choice.unwrap_u8());
        // If choosing a: b ^ (a^b) = a
        // Else if choosing b: b
        b ^ (mask & (a ^b))
    }
}

impl ConditionallySelectable for u32 {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: u32, b: u32, choice: Choice) -> u32 {
        let choice_32: u32 = choice.unwrap_u8();
        // If choice == 0, mask = 00...00
        // Else if choice == 1, mask = 11..11
        let mask = wrapping_neg(choice_32);
        // If choosing a: b ^ (a^b) = a
        // Else if choosing b: b
        b ^ (mask & (a ^ b))
    }
}

impl ConditionallySelectable for u64 {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: u64, b: u64, choice: Choice) -> u64 {
        let choice_64: u64 = choice.unwrap_u8();
        // If choice == 0, mask = 00...00
        // Else if choice == 1, mask = 11..11
        let mask = wrapping_neg(choice_64);
        // If choosing a: b ^ (a^b) = a
        // Else if choosing b: b
        b ^ (mask & (a ^ b))
    }
}

impl ConditionallySelectable for Choice {
    // Select a if choice == 1 or select b if choice == 0, in constant time.
    fn conditional_select(a: Self, b: Self, choice: Choice) -> Self {
        Choice::from(u8::conditional_select(a.c, b.c, choice))
    }
}

impl BitwiseAnd for Choice {
    // Returns the choice for the binary 'and' of the inner values of self and other
    // Note that we still can't use the `&` operator for this binary_and, but have to use the function name
    fn binary_and(self, other: Self) -> Self {
        Choice::from(self.c & other.c)
    }
}

impl BitwiseOr for Choice {
    // Returns the choice for the binary 'or' of the inner values of self and other
    // Note that we still can't use the `|` operator for this binary_or, but have to use the function name
    fn binary_or(self, other: Self) -> Self {
        Choice::from(self.c | other.c)
    }
}

impl BitwiseXor for Choice {
    // Returns the choice for the binary 'xor' of the inner values of self and other
    // Note that we still can't use the `^` operator for this binary_xor, but have to use the function name
    fn binary_xor(self, other: Self) -> Self {
        Choice::from(self.c ^ other.c)
    }
}

// Optional value intended to be in constant time
pub struct CtOption<T> {
    value: T,
    is_some: Choice,
}

impl<T> CtOption<T> {
    // Create a new optional with a value and whether it contains a value.
    // If is_some = false, the value is still stored, but never returned
    pub fn new(value: T, is_some: Choice) -> CtOption<T> {
        CtOption {
            value: value,
            is_some: is_some,
        }
    }

    // Create a new optional, where the is_some value is wrapped in a Choice automatically
    pub fn new_from_bool(value: T, is_some: bool) -> CtOption<T> {
        let is_some_as_u8 = asm(r1: is_some) { // set register 1 (r1) to value is_some
            r1: u8 // simply cast the input to u8
        };
        CtOption {value: value, is_some: Choice{ c: is_some_as_u8 }}
    }

    // return whether this optional is none (this doesn't mean it doesn't have a value necessarily, but we don't return it either way)
    pub fn is_none(self) -> bool {
        // if the function body would reference the is_some function beneath, it would have to go in a separate impl due to restrictions in Sway
        !self.is_some.unwrap_as_bool()
    }

    // return whether this optional is some
    pub fn is_some(self) -> bool {
        self.is_some.unwrap_as_bool()
    }

    // return the wrapped value, if the optional is_some. Otherwise, revert
    pub fn unwrap(self) -> T {
        assert(self.is_some.unwrap_as_bool());
        self.value
    }

    /*
    A function from the original lib we can't implement:
        pub fn unwrap_or(self, def: T) -> T
    where
        T: ConditionallySelectable,
    {
        T::conditional_select(&def, &self.value, self.is_some)
    }

    There is no type restriction possible on generics in Sway
    See https://discord.com/channels/732892373507375164/734213700835082330/1007097764242522273
    */
}

// An Equal like trait that returns a Choice (instead of a bool)
pub trait ConstantTimeEq {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Self) -> Choice;
}

// returns a+b mod 2^64. The result loses the carry.
fn add_wrap_64(a: u64, b :u64) -> u64 {
    let a_128: U128 = U128::from((0, a));
    let b_128: U128 = U128::from((0, b));
    (a_128 + b_128).lower
}

// returns -a mod 2^64
pub fn wrapping_neg(a: u64) -> u64 {
   add_wrap_64(u64::max() - a, 1)
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
        Choice::from(res)
    }
}
