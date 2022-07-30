contract;

use bls12_381::{fp::*, fp2::*};

abi BlsTestContract {
    #[storage(read, write)]fn add_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn sub_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn square_fp(a: Fp) -> Fp;
    #[storage(read, write)]fn fp_from_raw_unchecked(v: [u64; 6]) -> Fp;

    #[storage(read, write)]fn mul_fp2(a: Fp2, b: Fp2) -> Fp2;
    
}

impl BlsTestContract for Contract {
    #[storage(read, write)]fn add_fp(a: Fp, b: Fp) -> Fp {
        a.add(b)
    }

    #[storage(read, write)]fn sub_fp(a: Fp, b: Fp) -> Fp {
        a.sub(b)
    }

    #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp {
        a.mul(b)
    }

    #[storage(read, write)]fn square_fp(a: Fp) -> Fp {
        a.square()
    }

    #[storage(read, write)]fn fp_from_raw_unchecked(v: [u64; 6]) -> Fp {
        from_raw_unchecked(v)
    }

    #[storage(read, write)]fn mul_fp2(a: Fp2, b: Fp2) -> Fp2 {
        a.mul(b)
    }
}