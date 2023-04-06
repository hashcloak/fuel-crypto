contract;

use p256::{
  field::FieldElement,
  scalar64::Scalar,
  scalar::*,
  affine::AffinePoint,
  projective::ProjectivePoint,
  point_arithmetic::{double, add, add_mixed}
};

use utils::choice::CtOption;

abi MyContract {
  // field
    fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement;
    fn fe_to_montgomery(w: FieldElement) -> FieldElement;
    fn fe_from_montgomery(w: FieldElement) -> FieldElement;
    fn sqrt(w: FieldElement) -> CtOption<FieldElement>;
    fn invert(w: FieldElement) -> CtOption<FieldElement>;
    fn pow_vartime(w: FieldElement, exp: [u64;4]) -> FieldElement;

  //scalar64
    fn scalar_add(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_sub(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_mul(a: Scalar, b: Scalar) -> Scalar;
    fn scalar_invert(a: Scalar) -> CtOption<Scalar>;

  // point arithmetic
    fn affine_to_proj(p: AffinePoint) -> ProjectivePoint;
    fn proj_to_affine(p: ProjectivePoint) -> AffinePoint;
    fn proj_double(p: ProjectivePoint) -> ProjectivePoint;
    fn proj_add(p1: ProjectivePoint, p2: ProjectivePoint) -> ProjectivePoint;
    fn proj_aff_add(p1_proj: ProjectivePoint, p2_aff: AffinePoint) -> ProjectivePoint;
}

impl MyContract for Contract {
    fn fe_mul(a: FieldElement, b: FieldElement) -> FieldElement {
        a * b
    }

    fn fe_to_montgomery(w: FieldElement) -> FieldElement {
      w.fe_to_montgomery()
    }

    fn fe_from_montgomery(w: FieldElement) -> FieldElement {
      w.fe_from_montgomery()
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

    fn affine_to_proj(p: AffinePoint) -> ProjectivePoint {
      ProjectivePoint::from(p)
    }

    fn proj_to_affine(p: ProjectivePoint) -> AffinePoint {
      p.into()
    }

    fn proj_double(p: ProjectivePoint) -> ProjectivePoint {
      double(p)
    }

    fn proj_add(p1: ProjectivePoint, p2: ProjectivePoint) -> ProjectivePoint {
      add(p1, p2)
    }

    fn proj_aff_add(p1_proj: ProjectivePoint, p2_aff: AffinePoint) -> ProjectivePoint {
      add_mixed(p1_proj, p2_aff)
    }
    
}
