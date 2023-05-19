contract;

use p256::{
  field::FieldElement,
  scalar::Scalar,
  affine::AffinePoint,
  projective::ProjectivePoint,
};
use utils::choice::CtOption;

abi MyContract {

  // field
    fn fe_to_montgomery(w: FieldElement) -> FieldElement;
    fn fe_from_montgomery(w: FieldElement) -> FieldElement;

  // point arithmetic
    fn affine_to_proj(p: AffinePoint) -> ProjectivePoint;
    fn proj_to_affine(p: ProjectivePoint) -> AffinePoint;
    fn proj_double(p: ProjectivePoint) -> ProjectivePoint;
    fn proj_add(p1: ProjectivePoint, p2: ProjectivePoint) -> ProjectivePoint;
    fn proj_aff_add(p1_proj: ProjectivePoint, p2_aff: AffinePoint) -> ProjectivePoint;
    fn proj_mul(p: ProjectivePoint, k: Scalar) -> ProjectivePoint;
}

impl MyContract for Contract {

    // field
    fn fe_to_montgomery(w: FieldElement) -> FieldElement {
      w.fe_to_montgomery()
    }

    fn fe_from_montgomery(w: FieldElement) -> FieldElement {
      w.fe_from_montgomery()
    }

    // point arithmetic
    fn affine_to_proj(p: AffinePoint) -> ProjectivePoint {
      ProjectivePoint::from(p)
    }

    fn proj_to_affine(p: ProjectivePoint) -> AffinePoint {
      p.into()
    }

    fn proj_double(p: ProjectivePoint) -> ProjectivePoint {
      p.double()
    }

    fn proj_add(p1: ProjectivePoint, p2: ProjectivePoint) -> ProjectivePoint {
      p1.add(p2)
    }

    fn proj_aff_add(p1_proj: ProjectivePoint, p2_aff: AffinePoint) -> ProjectivePoint {
      p1_proj.add_mixed(p2_aff)
    }

    fn proj_mul(p: ProjectivePoint, k: Scalar) -> ProjectivePoint {
      p.mul(k)
    }
}
