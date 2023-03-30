contract;

use p256::{
  field64::Fe, 
  field64::{fe_mul, fe_to_montgomery, fe_from_montgomery},
  field::*
};
use utils::choice::CtOption;

abi MyContract {
  // field64.sq
    fn fe_mul(a: Fe, b: Fe) -> Fe;
    fn fe_to_montgomery(w: Fe) -> Fe;
    fn fe_from_montgomery(w: Fe) -> Fe;

  //field.sw
    fn sqrt(w: Fe) -> CtOption<Fe>;
}

impl MyContract for Contract {
    fn fe_mul(a: Fe, b: Fe) -> Fe {
        a * b
    }

    fn fe_to_montgomery(w: Fe) -> Fe {
      fe_to_montgomery(w)
    }

    fn fe_from_montgomery(w: Fe) -> Fe {
      fe_from_montgomery(w)
    }

    fn sqrt(w: Fe) -> CtOption<Fe> {
      w.sqrt()
    }
}
