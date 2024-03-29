contract;

use bls12_381::{fp::Fp, fp2::Fp2, scalar::Scalar};
use utils::choice::{CtOption, Choice};

abi BlsTestContract {
    // Works
    #[storage(read, write)]fn add_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn sub_fp(a: Fp, b: Fp) -> Fp;
    // Running this one will give Immediate18TooLarge
    // #[storage(read, write)]fn lexicographically_largest_fp(a: Fp) -> Choice;

    // works but takes a long time
    #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp;

    // works if ran by itself
    // #[storage(read, write)]fn square_fp(a: Fp) -> Fp;

    // Works
    #[storage(read, write)]fn add_fp2(a: Fp2, b: Fp2) -> Fp2;
    #[storage(read, write)]fn sub_fp2(a: Fp2, b: Fp2) -> Fp2;
    #[storage(read, write)]fn neg_fp2(a: Fp2) -> Fp2;
    // Running this one will give Immediate18TooLarge
    // #[storage(read, write)]fn lexicographically_largest_fp2(a: Fp2) -> Choice;
    
    // // not tested, still gives Immediate18TooLarge error
    // #[storage(read, write)]fn square_fp2(a: Fp2) -> Fp2;

    #[storage(read, write)]fn mul_fp2(a: Fp2, b: Fp2) -> Fp2;

    #[storage(read, write)]fn add_scalar(a: Scalar, b: Scalar) -> Scalar;
  
//This function gives an error
    // #[storage(read, write)]fn scalar_sqrt(a: Scalar) -> CtOption<Scalar>;

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

    // #[storage(read, write)]fn lexicographically_largest_fp(a: Fp) -> Choice {
    //     a.lexicographically_largest()
    // }

    #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp {
        a * b
    }

    // #[storage(read, write)]fn square_fp(a: Fp) -> Fp {
    //     a.square()
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

    // #[storage(read, write)]fn lexicographically_largest_fp2(a: Fp2) -> Choice {
    //     a.lexicographically_largest()
    // }

    #[storage(read, write)]fn add_scalar(a: Scalar, b: Scalar) -> Scalar {
        a + b
    }

    // #[storage(read, write)]fn square_fp2(a: Fp2) -> Fp2 {
    //     a.square()
    // }

    #[storage(read, write)]fn mul_fp2(a: Fp2, b: Fp2) -> Fp2 {
        a * b
    }

    // #[storage(read, write)]fn scalar_sqrt(a: Scalar) -> CtOption<Scalar> {
    //     a.sqrt()
    // }

    // #[storage(read, write)]fn mul_fp6(a: Fp6, b: Fp6) -> Fp6 {
    //     a * b
    // }

    // #[storage(read, write)]fn square_fp6(a: Fp6) -> Fp6 {
    //     a.square()
    // }
}
