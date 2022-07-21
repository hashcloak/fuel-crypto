contract;
dep test_helpers;

use edwards25519::*;

use std::assert::assert;
use std::u128::*;

use ::test_helpers::*;

abi EdContract {
    #[storage()]fn equals(a: Element, b: Element) -> bool;
    #[storage()]fn multiply(a: Element, b: Element) -> Element;
    #[storage()]fn square(a: Element) -> Element;
    #[storage()]fn subtract(a: Element, b: Element) -> Element;
    #[storage()]fn add(a: Element, b: Element) -> Element;
    #[storage()]fn carry_propagate(a: Element) -> Element;
    #[storage()]fn reduce(a: Element) -> Element;
    #[storage()]fn multiply64(a: u64, b: u64) -> U128;
    #[storage()]fn add64(a: u64, b: u64, carry: u64) -> (u64, u64);
    #[storage()]fn add_multiply64(res: U128, a: u64, b: u64) -> U128;
    #[storage()]fn scalar_mult(a: Element, x: u32) -> Element;
    #[storage()]fn shift_right_by51(a: U128) -> u64;

}

impl EdContract for Contract {
    #[storage()]fn equals(a: Element, b: Element) -> bool {
        equals(a, b)
    }

    #[storage()]fn multiply(a: Element, b: Element) -> Element {
        multiply(a, b)
    }

    #[storage()]fn square(a: Element) -> Element {
        square(a)
    }

    #[storage()]fn subtract(a: Element, b: Element) -> Element {
        subtract(a, b)
    }

    #[storage()]fn add(a: Element, b: Element) -> Element {
        add(a, b)
    }

    #[storage()]fn carry_propagate(a: Element) -> Element {
        carry_propagate(a)
    }

    #[storage()]fn reduce(a: Element) -> Element {
        reduce(a)
    }

    #[storage()]fn multiply64(a: u64, b: u64) -> U128 {
        multiply64(a, b)
    }

    #[storage()]fn add64(a: u64, b: u64, carry: u64) -> (u64, u64) {
        add64(a, b, carry)
    }

    #[storage()]fn add_multiply64(res: U128, a: u64, b: u64) -> U128 {
        add_multiply64(res, a, b)
    }

    #[storage()]fn scalar_mult(a: Element, x: u32) -> Element {
        scalar_mult(a, x)
    }

    #[storage()]fn shift_right_by51(a: U128) -> u64 {
        shift_right_by51(a)
    }
}