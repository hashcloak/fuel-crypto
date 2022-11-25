contract;

use bls12_381::{fp::Fp, fp2::Fp2, fp6::Fp6, scalar::Scalar};
use utils::choice::{CtOption, Choice};

abi BlsTestContract {
    #[storage(read, write)]fn add_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn sub_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn lexicographically_largest_fp(a: Fp) -> Choice;
    #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn square_fp(a: Fp) -> Fp;

    #[storage(read, write)]fn add_fp2(a: Fp2, b: Fp2) -> Fp2;
    #[storage(read, write)]fn sub_fp2(a: Fp2, b: Fp2) -> Fp2;
    #[storage(read, write)]fn neg_fp2(a: Fp2) -> Fp2;
    #[storage(read, write)]fn lexicographically_largest_fp2(a: Fp2) -> Choice;
    #[storage(read, write)]fn square_fp2(a: Fp2) -> Fp2;
    #[storage(read, write)]fn mul_fp2(a: Fp2, b: Fp2) -> Fp2;

//untested
    #[storage(read, write)]fn add_scalar(a: Scalar, b: Scalar) -> Scalar;
  
//untested
    // #[storage(read, write)]fn scalar_sqrt(a: Scalar) -> CtOption<Scalar>;

    #[storage(read, write)]fn mul_fp6(a: Fp6, b: Fp6) -> Fp6;
    #[storage(read, write)]fn square_fp6(a: Fp6) -> Fp6;

}

impl BlsTestContract for Contract {
    #[storage(read, write)]fn add_fp(a: Fp, b: Fp) -> Fp {
        a + b
    }

    #[storage(read, write)]fn sub_fp(a: Fp, b: Fp) -> Fp {
        a - b
    }

    #[storage(read, write)]fn lexicographically_largest_fp(a: Fp) -> Choice {
        a.lexicographically_largest()
    }

    #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp {
        a * b
    }

    #[storage(read, write)]fn square_fp(a: Fp) -> Fp {
        a.square()
    }

    #[storage(read, write)]fn add_fp2(a: Fp2, b: Fp2) -> Fp2 {
        a + b
    }

    #[storage(read, write)]fn sub_fp2(a: Fp2, b: Fp2) -> Fp2 {
        a - b
    }

    #[storage(read, write)]fn neg_fp2(a: Fp2) -> Fp2 {
        a.neg()
    }

    #[storage(read, write)]fn lexicographically_largest_fp2(a: Fp2) -> Choice {
        a.lexicographically_largest()
    }

    #[storage(read, write)]fn add_scalar(a: Scalar, b: Scalar) -> Scalar {
        a + b
    }

    #[storage(read, write)]fn square_fp2(a: Fp2) -> Fp2 {
        a.square()
    }

    #[storage(read, write)]fn mul_fp2(a: Fp2, b: Fp2) -> Fp2 {
        a * b
    }

    // #[storage(read, write)]fn scalar_sqrt(a: Scalar) -> CtOption<Scalar> {
    //     a.sqrt()
    // }

    #[storage(read, write)]fn mul_fp6(a: Fp6, b: Fp6) -> Fp6 {
        a * b
    }

    #[storage(read, write)]fn square_fp6(a: Fp6) -> Fp6 {
        a.square()
    }
}
