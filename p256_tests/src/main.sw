contract;

use p256::{field64::Fe, 
  field64::{fe_mul, fe_to_montgomery, fe_from_montgomery}
};

abi MyContract {
    fn fe_mul(a: Fe, b: Fe) -> Fe;
    fn fe_to_montgomery(w: Fe) -> Fe;
    fn fe_from_montgomery(w: Fe) -> Fe;
}

impl MyContract for Contract {
    fn fe_mul(a: Fe, b: Fe) -> Fe {
        fe_mul(a, b)
    }

    fn fe_to_montgomery(w: Fe) -> Fe {
      fe_to_montgomery(w)
    }

    fn fe_from_montgomery(w: Fe) -> Fe {
      fe_from_montgomery(w)
    }
}
