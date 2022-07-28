contract;

use bls::{fields::*, vect::*};
// unsure why this isn't working, bit it's needed for temp_fe_mont_mul
use std::u128::*;

abi BlsContract {
    //Small helper functions
    #[storage()]fn not(input: u64) -> u64;
    #[storage()]fn subtract_wrap(x: U128, y: U128) -> U128;
    #[storage()]fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64);
    #[storage()]fn adc(a: u64, b: u64, carry: u64) -> (u64, u64);
    #[storage()]fn subtract_p(a: vec384, p: vec384) -> vec384;
    #[storage()]fn neg(a: vec384, p: vec384) -> vec384;

    //Fp
    #[storage()]fn add_fp(a: vec384, b: vec384) -> vec384;
    #[storage()]fn sub_fp(a: vec384, b: vec384) -> vec384;
    #[storage()]fn mul_by_3_fp(a: vec384) -> vec384;
    #[storage()]fn mul_by_8_fp(a: vec384) -> vec384;
    #[storage()]fn lshift_fp(a: vec384, count: u64) -> vec384;
    #[storage()]fn rshift_fp(a: vec384, count: u64) -> vec384;
    #[storage()]fn div_by_2_fp(a: vec384) -> vec384;
    #[storage()]fn mul_fp(a: vec384, b: vec384) -> vec384;
    #[storage()]fn sqr_fp(a: vec384) -> vec384;
    #[storage()]fn cneg_fp(a: vec384, flag: u64) -> vec384;
    #[storage()]fn from_fp(a: vec384) -> vec384;
    // #[storage()]fn redc_fp(a: vec384) -> vec384;

    // Temp mul functions
    #[storage()]fn temp_mul_mont_n(a: vec384, b: vec384) -> vec384;
    #[storage()]fn rshift_mod_384(a: vec384, n: u64, p: vec384) -> vec384;
    // // Fp2
    // #[storage()]fn add_fp2(a: vec384, b: vec384) -> vec384;
    // #[storage()]fn sub_fp2(a: vec384, b: vec384) -> vec384;
    // #[storage()]fn mul_by_3_fp2(a: vec384) -> vec384;
    // #[storage()]fn mul_by_8_fp2(a: vec384) -> vec384;
    // #[storage()]fn lshift_fp2(a: vec384, count: u64) -> vec384;
    // #[storage()]fn rshift_fp2(a: vec384, count: u64) -> vec384;
    // #[storage()]fn div_by_2_f2(a: vec384) -> vec384;
    // #[storage()]fn mul_fp2(a: vec384, b: vec384) -> vec384;
    // #[storage()]fn sqr_fp2(a: vec384) -> vec384;
    // #[storage()]fn cneg_fp2(a: vec384, flag: u64) -> vec384;
}

impl BlsContract for Contract {

    //Small helper functions
    #[storage()]fn not(input: u64) -> u64 {
        not(input)
    }

    #[storage()]fn subtract_wrap(x: U128, y: U128) -> U128 {
        subtract_wrap(x, y)
    }

    #[storage()]fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64) {
        sbb(a, b, borrow)
    }

    #[storage()]fn adc(a: u64, b: u64, carry: u64) -> (u64, u64) {
        adc(a, b, carry)
    }

    #[storage()]fn subtract_p(a: vec384, p: vec384) -> vec384 {
        subtract_p(a, p)
    }

    #[storage()]fn neg(a: vec384, p: vec384) -> vec384 {
        neg(a, p)
    }

    // Fp
    #[storage()]fn add_fp(a: vec384, b: vec384) -> vec384 {
        add_fp(a, b)
    }
    
    #[storage()]fn sub_fp(a: vec384, b: vec384) -> vec384 {
        sub_fp(a, b)
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

    #[storage()]fn div_by_2_fp(a: vec384) -> vec384 {
        div_by_2_fp(a)
    }

    #[storage()]fn mul_fp(a: vec384, b: vec384) -> vec384 {
        mul_fp(a, b)
    }

    #[storage()]fn sqr_fp(a: vec384) -> vec384 {
        sqr_fp(a)
    }

    #[storage()]fn cneg_fp(a: vec384, flag: u64) -> vec384 {
        cneg_fp(a, flag)
    }

    #[storage()]fn from_fp(a: vec384) -> vec384 {
        from_fp(a)
    }

    #[storage()]fn temp_mul_mont_n(a: vec384, b: vec384) -> vec384 {
        temp_mul_mont_n(a, b)
    }

    #[storage()]fn rshift_mod_384(a: vec384, n: u64, p: vec384) -> vec384 {
        rshift_mod_384(a, n, p)
    }
    // #[storage()]fn redc_fp(a: vec384) -> vec384 {
    //     redc_fp(a)
    // }

    // // Fp2
    // #[storage()]fn add_fp2(a: vec384, b: vec384) -> vec384 {
    //     add_fp2(a, b)
    // }

    // #[storage()]fn add_fp2(a: vec384, b: vec384) -> vec384 {
    //     add_fp2(a, b)
    // }

    // #[storage()]fn mul_by_3_fp2(a: vec384) -> vec384 {
    //     mul_by_3_fp2(a)
    // }

    // #[storage()]fn mul_by_8_fp2(a: vec384) -> vec384 {
    //     mul_by_8_fp2(a)
    // }

    // #[storage()]fn lshift_fp2(a: vec384, count: u64) -> vec384 {
    //     lshift_fp2(a, count)
    // }

    // #[storage()]fn rshift_fp2(a: vec384, count: u64) -> vec384 {
    //     rshift_fp2(a, count)
    // }

    // #[storage()]fn div_by_2_fp2(a: vec384) -> vec384 {
    //     div_by_2_fp2(a)
    // }

    // #[storage()]fn mul_fp2(a: vec384, b: vec384) -> vec384 {
    //     mul_fp2(a, b)
    // }

    // #[storage()]fn sqr_fp2(a: vec384) -> vec384 {
    //     sqr_fp2(a)
    // }

    // #[storage()]fn cneg_fp2(a: vec384, flag: u64) -> vec384 {
    //     cneg_fp2(a, flag)
    // }
}