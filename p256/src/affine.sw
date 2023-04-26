library;

use ::field::FieldElement;
use utils::{choice::*};

// Point on a Weierstrass curve in affine coordinates.
pub struct AffinePoint {
    x: FieldElement,
    y: FieldElement,
    // Is this point the point at infinity? 0 = no, 1 = yes
    infinity: u8,
}

impl AffinePoint {
    pub fn identity() -> Self {
      AffinePoint {
        x: FieldElement::zero(),
        y: FieldElement::zero(),
        infinity: 1u8,
      }
    }

    pub fn generator() -> Self {
      // generator for P-256  is (x, y) = (0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296, 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5)
      AffinePoint {
        x: FieldElement{ls: [17627433388654248598, 8575836109218198432, 17923454489921339634, 7716867327612699207]},
        y: FieldElement{ls: [14678990851816772085, 3156516839386865358, 10297457778147434006, 5756518291402817435]},
        infinity: 0u8,
      }

    }

    // returns true if it's the point at infinity
    pub fn is_identity(self) -> Choice {
        Choice::from(self.infinity)
    }

    pub fn neg(self) -> Self {
      AffinePoint{
        x: self.x,
        y: FieldElement::negate(self.y),
        infinity: self.infinity,
      }
    }
}
