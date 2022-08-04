contract;

use bls12_381::{
    fp::Fp, 
    fp::from_raw_unchecked, 
    fp2::Fp2, 
    fp6::Fp6, 
    scalar::Scalar};
use bls12_381::choice::CtOption;

abi BlsTestContract {
    #[storage(read, write)]fn add_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn sub_fp(a: Fp, b: Fp) -> Fp;
    // #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp;
    // #[storage(read, write)]fn square_fp(a: Fp) -> Fp;
    #[storage(read, write)]fn fp_from_raw_unchecked(v: [u64; 6]) -> Fp;

    // #[storage(read, write)]fn square_fp2(a: Fp2) -> Fp2;
    // #[storage(read, write)]fn mul_fp2(a: Fp2, b: Fp2) -> Fp2;
    #[storage(read, write)]fn add_fp2(a: Fp2, b: Fp2) -> Fp2;
    #[storage(read, write)]fn sub_fp2(a: Fp2, b: Fp2) -> Fp2;
    #[storage(read, write)]fn neg_fp2(a: Fp2) -> Fp2;

    #[storage(read, write)]fn add_scalar(a: Scalar, b: Scalar) -> Scalar;
  
    // this returntype CtOption seems to cause the error:
    /*
error: Internal compiler error: Verification failed: Function anon_11103 return type must match its RET instructions.
Please file an issue on the repository and include the code that triggered this error.
*/
    #[storage(read, write)]fn scalar_sqrt(a: Scalar) -> CtOption<Scalar>;

// These can't be compiled yet.. 
    // #[storage(read, write)]fn mul_fp6(a: Fp6, b: Fp6) -> Fp6;
    // #[storage(read, write)]fn square_fp6(a: Fp6) -> Fp6;

}

impl BlsTestContract for Contract {
    #[storage(read, write)]fn add_fp(a: Fp, b: Fp) -> Fp {
        a + b
    }

    #[storage(read, write)]fn sub_fp(a: Fp, b: Fp) -> Fp {
        a - b
    }

    // #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp {
    //     a * b
    // }

    // #[storage(read, write)]fn square_fp(a: Fp) -> Fp {
    //     a.square()
    // }

    #[storage(read, write)]fn fp_from_raw_unchecked(v: [u64; 6]) -> Fp {
        from_raw_unchecked(v)
    }

    // #[storage(read, write)]fn square_fp2(a: Fp2) -> Fp2 {
    //     a.square()
    // }

    // #[storage(read, write)]fn mul_fp2(a: Fp2, b: Fp2) -> Fp2 {
    //     a * b
    // }

    #[storage(read, write)]fn add_fp2(a: Fp2, b: Fp2) -> Fp2 {
        a + b
    }

    #[storage(read, write)]fn sub_fp2(a: Fp2, b: Fp2) -> Fp2 {
        a - b
    }

    #[storage(read, write)]fn neg_fp2(a: Fp2) -> Fp2 {
        a.neg()
    }

    #[storage(read, write)]fn add_scalar(a: Scalar, b: Scalar) -> Scalar {
        a + b
    }

    #[storage(read, write)]fn scalar_sqrt(a: Scalar) -> CtOption<Scalar> {
        a.sqrt()
    }

    // #[storage(read, write)]fn mul_fp6(a: Fp6, b: Fp6) -> Fp6 {
    //     a * b
    // }

    // #[storage(read, write)]fn square_fp6(a: Fp6) -> Fp6 {
    //     a.square()
    // }
}