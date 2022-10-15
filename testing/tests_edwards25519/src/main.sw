contract;

use edwards25519::{field_element::Element, 
    field_element::multiply64, 
    field_element::add_multiply64, 
    field_element::shift_right_by51, 
    ge25519::*};
use std::u128::U128;

abi EdwardsTestContract {
    // Light functions, all OK
    #[storage()]fn equals(a: Element, b: Element) -> bool;
    #[storage()]fn multiply(a: Element, b: Element) -> Element;
    #[storage()]fn square(a: Element) -> Element;
    #[storage()]fn subtract(a: Element, b: Element) -> Element;
    #[storage()]fn add(a: Element, b: Element) -> Element;
    #[storage()]fn carry_propagate(a: Element) -> Element;
    #[storage()]fn reduce(a: Element) -> Element;
    #[storage()]fn multiply64(a: u64, b: u64) -> U128;
    #[storage()]fn add_multiply64(res: U128, a: u64, b: u64) -> U128;
    #[storage()]fn scalar_mult(a: Element, x: u32) -> Element;
    #[storage()]fn shift_right_by51(a: U128) -> u64;

    // Can't test yet because of Immediate18TooLarge
    #[storage()]fn inverse(a: Element) -> Element;

    // Can't compile
    // #[storage()]fn dbl_p1p1(p: ge25519_p2) -> ge25519_p1p1;
}

impl EdwardsTestContract for Contract {
#[storage()]fn equals(a: Element, b: Element) -> bool {
        a == b
    }

    #[storage()]fn multiply(a: Element, b: Element) -> Element {
        a * b
    }

    #[storage()]fn square(a: Element) -> Element {
        a.square()
    }

    #[storage()]fn subtract(a: Element, b: Element) -> Element {
        a - b
    }

    #[storage()]fn add(a: Element, b: Element) -> Element {
        a + b
    }

    #[storage()]fn carry_propagate(a: Element) -> Element {
        a.carry_propagate()
    }

    #[storage()]fn reduce(a: Element) -> Element {
        a.reduce()
    }

    #[storage()]fn multiply64(a: u64, b: u64) -> U128 {
        multiply64(a, b)
    }

    #[storage()]fn add_multiply64(res: U128, a: u64, b: u64) -> U128 {
        add_multiply64(res, a, b)
    }

    #[storage()]fn scalar_mult(a: Element, x: u32) -> Element {
        a.scalar_mult(x)
    }

    #[storage()]fn shift_right_by51(a: U128) -> u64 {
        shift_right_by51(a)
    }

    #[storage()]fn inverse(a: Element) -> Element {
        a.inverse()
    }

    // #[storage()]fn dbl_p1p1(p: ge25519_p2) -> ge25519_p1p1 {
    //     dbl_p1p1(p)
    // }
}
