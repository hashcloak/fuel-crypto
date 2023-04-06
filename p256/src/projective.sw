library;

use ::affine::AffinePoint;
use ::field::FieldElement;
use ::std::convert::From;
use ::utils::choice::{ConditionallySelectable, Choice, CtOption};

pub struct ProjectivePoint {
    x: FieldElement,
    y: FieldElement,
    z: FieldElement,
}

impl ProjectivePoint {

  fn identity() -> Self {
    Self {
      x: FieldElement::zero(),
      y: FieldElement::one(),
      z: FieldElement::zero()
    }
  }
}

impl ConditionallySelectable for ProjectivePoint {
  // Select a if choice == 1 or select b if choice == 0, in constant time.
  fn conditional_select(a: ProjectivePoint, b: ProjectivePoint, choice: Choice) -> ProjectivePoint {
    ProjectivePoint {
      x: FieldElement::conditional_select(a.x, b.x, choice),
      y: FieldElement::conditional_select(a.y, b.y, choice),
      z: FieldElement::conditional_select(a.z, b.z, choice)
    }
  }
}

impl From<AffinePoint> for ProjectivePoint {
    fn from(p: AffinePoint) -> Self {
        let projective = ProjectivePoint {
            x: p.x,
            y: p.y,
            z: FieldElement::one(),
        };
        Self::conditional_select(Self::identity(), projective, p.is_identity())
    }

    fn into(self) -> AffinePoint {
      let zinv = self.z.invert();
      // TODO add default when zinv None is: AffinePoint::IDENTITY
      AffinePoint {
        x: self.x * zinv.unwrap(),
        y: self.y * zinv.unwrap(),
        infinity: 0
      }
    }
}