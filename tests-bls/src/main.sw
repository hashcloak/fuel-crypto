contract;

use bls::{fields::*, vect::*};

abi BlsContract {
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