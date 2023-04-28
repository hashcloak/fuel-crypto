library;

use ::field::FieldElement;
use utils::{choice::*};

// a = -3 mod p
pub const EQUATION_A: FieldElement = FieldElement {
  ls: [18446744073709551612, 4294967295, 0, 18446744069414584321],
}

// [6540974713487397863, 12964664127075681980, 7285987128567378166, 4309448131093880907]
// const EQUATION_B: FieldElement =
// FieldElement::from_hex("5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b");
pub const EQUATION_B = FieldElement {
  ls: [
      4309448131093880907,
      7285987128567378166,
      12964664127075681980,
      6540974713487397863,
  ],
};

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
      infinity: 1,
    }
  }

  // returns generator with coordinates in Montgomery form
  pub fn generator() -> Self {
    // generator for P-256  is (x, y) = (0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296, 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5)
    AffinePoint {
      x: FieldElement {
        ls: [
            17627433388654248598,
            8575836109218198432,
            17923454489921339634,
            7716867327612699207,
        ],
      }.fe_to_montgomery(),
      y: FieldElement {
        ls: [
            14678990851816772085,
            3156516839386865358,
            10297457778147434006,
            5756518291402817435,
        ],
      }.fe_to_montgomery(),
      infinity: 0,
    }
  }

  // returns true if it's the point at infinity
  pub fn is_identity(self) -> Choice {
    Choice::from(self.infinity)
  }

  pub fn neg(self) -> Self {
    AffinePoint {
      x: self.x,
      y: FieldElement::negate(self.y),
      infinity: self.infinity,
    }
  }
}