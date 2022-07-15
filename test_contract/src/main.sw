contract;
dep test_helpers;

use edwards25519::*;

use std::assert::assert;
use std::u128::*;

use ::test_helpers::*;

abi EdContract {
    #[storage()]fn equals_test(a: Element, b: Element) -> bool;
    #[storage()]fn multiply_test(a: Element, b: Element) -> Element;
    
}

impl EdContract for Contract {
    #[storage()]fn equals_test(a: Element, b: Element) -> bool {
        equals(a, b)
    }

    #[storage()]fn multiply_test(a: Element, b: Element) -> Element {
        multiply(a, b)
    }
}