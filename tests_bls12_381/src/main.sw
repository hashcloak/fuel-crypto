contract;

use bls12_381::{fp::*};

abi BlsTestContract {
    #[storage(read, write)]fn add_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn sub_fp(a: Fp, b: Fp) -> Fp;
    #[storage(read, write)]fn mul_fp(a: Fp, b: Fp) -> Fp;
    
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
}
