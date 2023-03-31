contract;

use p256::{
  field64::FieldElement, 
  field64::{fe_mul, fe_to_montgomery, fe_from_montgomery},
  field::*
};

use p256::{
  scalar64::Scalar,
  scalar::*
};

use utils::choice::CtOption;

abi MyContract {
  // field64.sq
    fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement;
    fn fe_to_montgomery(w: FieldElement) -> FieldElement;
    fn fe_from_montgomery(w: FieldElement) -> FieldElement;

  //field.sw
    fn sqrt(w: FieldElement) -> CtOption<FieldElement>;
    fn invert(w: FieldElement) -> CtOption<FieldElement>;
    fn pow_vartime(w: FieldElement, exp: Vec<u64>) -> FieldElement;

  //scalar64
    fn scalar_add(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_sub(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_mul(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_invert(a: Scalar) -> CtOption<Scalar>;

}

impl MyContract for Contract {
    fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement {
        a * b
    }

    fn fe_to_montgomery(w: FieldElement) -> FieldElement {
      fe_to_montgomery(w)
    }

    fn fe_from_montgomery(w: FieldElement) -> FieldElement {
      fe_from_montgomery(w)
    }

    fn sqrt(w: FieldElement) -> CtOption<FieldElement> {
      w.sqrt()
    }

    fn invert(w: FieldElement) -> CtOption<FieldElement> {
      w.invert()
    }

    fn pow_vartime(w: FieldElement, exp: Vec<u64>) -> FieldElement {
      w.pow_vartime(exp)
    }

    fn scalar_add(a: Scalar, b: Scalar) -> Scalar {
        a + b
    }

    fn scalar_sub(a: Scalar, b: Scalar) -> Scalar {
        a - b
    }

    fn scalar_mul(a: Scalar, b: Scalar) -> Scalar {
        a * b
    }

    fn scalar_invert(a: Scalar) -> CtOption<Scalar> {
        a.scalar_invert()
    }
    
}
