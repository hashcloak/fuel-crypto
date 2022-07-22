contract;

use bls::*;
//need to import vect.sw

abi BlsContract {
    #[storage()]fn add_fp(a: vec384, b: vec384) -> vec384;
    #[storage()]fn sub_fp(a: vec384, b: vec384) -> vec384;
    #[storage()]fn mul_by_3_fp(a: vec384) -> vec384;
    #[storage()]fn mul_by_8_fp(a: vec384) -> vec384;
    #[storage()]fn lshift_fp(a: vec384, count: u64) -> vec384;
    #[storage()]fn rshift_fp(a: vec384, count: u64) -> vec384;

}

impl BlsContract for Contract {
    #[storage()]fn add_fp(a: vec384, b: vec384) -> vec384 {
        add_fp(a, b)
    }

    #[storage()]fn add_fp(a: vec384, b: vec384) -> vec384 {
        add_fp(a, b)
    }

    #[storage()]fn mul_by_3_fp(a: vec384) -> vec384 {
        mul_by_3_fp(a)
    }

    #[storage()]fn mul_by_8_fp(a: vec384) -> vec384 {
        mul_by_8_fp(a)
    }

    #[storage()]fn lshift_fp(a: vec384, count: u64) -> vec384 {
        lshift_fp(a, count)
    }

    #[storage()]fn rshift_fp(a: vec384, count: u64) -> vec384 {
        rshift_fp(a, count)
    }

}