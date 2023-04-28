contract;

use p256::{
  field::FieldElement,
  scalar::{Scalar, *},
};

use utils::choice::CtOption;

abi MyContract {

  // field
    fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement;
    fn sqrt(w: FieldElement) -> CtOption<FieldElement>;
    fn invert(w: FieldElement) -> CtOption<FieldElement>;
    fn pow_vartime(w: FieldElement, exp: [u64;4]) -> FieldElement;
    fn fe_to_bytes(a: FieldElement) -> [u8;32];
    fn fe_to_montgomery(w: FieldElement) -> FieldElement;
    fn fe_from_montgomery(w: FieldElement) -> FieldElement;

  // scalar
    fn scalar_add(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_sub(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_mul(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_invert(a: Scalar) -> CtOption<Scalar>;
    fn scalar_from_bytes(in: [u8; 32]) -> Scalar;
}

impl MyContract for Contract {

    // field
    fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement {
        a * b
    }


    fn sqrt(w: FieldElement) -> CtOption<FieldElement> {
      w.sqrt()
    }

    fn invert(w: FieldElement) -> CtOption<FieldElement> {
      w.invert()
    }

    fn pow_vartime(w: FieldElement, exp: [u64;4]) -> FieldElement {
      w.pow_vartime(exp)
    }

    fn fe_to_bytes(a: FieldElement) -> [u8;32] {
      a.to_bytes()
    }

    fn fe_to_montgomery(w: FieldElement) -> FieldElement {
      w.fe_to_montgomery()
    }

    fn fe_from_montgomery(w: FieldElement) -> FieldElement {
      w.fe_from_montgomery()
    }

  // scalar
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

    fn scalar_from_bytes(in: [u8; 32]) -> Scalar {
      Scalar::from_bytes(in)
    }

}
