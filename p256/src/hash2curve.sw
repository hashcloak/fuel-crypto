library;

use ::field::FieldElement;
use ::projective::ProjectivePoint;
use utils::choice::Choice;
use ::affine::AffinePoint;
// a = -3 mod p
pub const EQUATION_A: FieldElement = FieldElement{ ls:[
  18446744073709551612,
  4294967295,
  0,
  18446744069414584321
]}

// [6540974713487397863, 12964664127075681980, 7285987128567378166, 4309448131093880907]
// const EQUATION_B: FieldElement =
    // FieldElement::from_hex("5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b");
pub const EQUATION_B = FieldElement { ls: [
  4309448131093880907,
  7285987128567378166,
  12964664127075681980,
  6540974713487397863
]};

pub struct OsswuMapParams<F> {
    c1: [u64;4],
    c2: F,
    map_a: F,
    map_b: F,
    z: F,
}


const PARAMS: OsswuMapParams<FieldElement> = OsswuMapParams {
    // See section 8.7 in
    // <https://datatracker.ietf.org/doc/draft-irtf-cfrg-hash-to-curve/>
    c1: [
        0xffffffffffffffff,
        0x000000003fffffff,
        0x4000000000000000,
        0x3fffffffc0000000,
    ],
    // a3323851ba997e271ac5d59c3298bf50b2806c63966a1a6653e43951f64fdbe7, 2^64)
    c2: FieldElement{ls:[
        6045019624025611239, 
        12862399710751234662, 
        1929182882238611280, 
        11759523500691914279
      ]},
    // fffffffc00000004000000000000000000000003fffffffffffffffffffffffc
    map_a: FieldElement{ls: [
        18446744073709551612, 
        17179869183, 
        0, 
        18446744056529682436,
    ]},
    // dc30061d04874834e5a220abf7212ed6acf005cd78843090d89cdf6229c4bddf
    map_b: FieldElement{ls: [
        15608596021259845087, 
        12461466548982526096,
        16546823903870267094, 
        15866188208926050356,
    ]},
    // fffffff50000000b00000000000000000000000afffffffffffffffffffffff5
    z: FieldElement{ls: [
        18446744073709551605, 
        47244640255, 
        0,
        18446744026464911371,
    ]},
};

// TODO: Testing not done
impl FieldElement {
  pub fn osswu(self) -> (Self, Self) {
    // took out all "normalize" references. Should check if that's ok
    let tv1 = self.square(); // u^2
    let tv3 = Self::PARAMS.z * tv1; // Z * u^2
    let mut tv2 = tv3.square(); // tv3^2
    let mut xd = tv2 + tv3; // tv3^2 + tv3
    let x1n = Self::PARAMS.map_b * (xd + Self::one()); // B * (xd + 1)
    xd = (xd * Self::PARAMS.map_a.negate()); // .normalize(); not sure if this is needed // -A * xd

    let tv = Self::PARAMS.z * Self::PARAMS.map_a;
    // reference impl: xd.conditional_assign(&tv, xd.is_zero());
    xd = Self::conditional_select(tv, xd, xd.is_zero());

    tv2 = xd.square(); //xd^2
    let gxd = tv2 * xd; // xd^3
    tv2 = tv2 * Self::PARAMS.map_a; // A * tv2

    let mut gx1 = x1n * (tv2 + x1n.square()); //x1n *(tv2 + x1n^2)
    tv2 = gxd * Self::PARAMS.map_b; // B * gxd
    gx1 = gx1 + tv2; // gx1 + tv2

    let mut tv4 = gxd.square(); // gxd^2
    tv2 = gx1 * gxd; // gx1 * gxd
    tv4 = tv4 * tv2;

    let y1 = tv4.pow_vartime(Self::PARAMS.c1) * tv2; // tv4^C1 * tv2
    let x2n = tv3 * x1n; // tv3 * x1n

    let y2 = y1 * Self::PARAMS.c2 * tv1 * self; // y1 * c2 * tv1 * u

    tv2 = y1.square() * gxd; //y1^2 * gxd

    let e2 = tv2.ct_eq(gx1);

    // if e2 , x = x1, else x = x2
    let mut x = Self::conditional_select(x2n, x1n, e2);
    // xn / xd
    x = x * xd.invert().value;

    // if e2, y = y1, else y = y2
    let mut y = Self::conditional_select(y2, y1, e2);

    // reference: y.conditional_assign(&-y, self.sgn0() ^ y.sgn0());
    
    y = Self::conditional_select(y.negate(), y, self.is_odd() ^ (y.is_odd()));
    (x, y)
  }
}

// TODO: Testing not done
impl FieldElement {
  fn map_to_curve(self) -> ProjectivePoint {
      let (qx, qy) = self.osswu();

    // TODO(tarcieri): assert that `qy` is correct? less circuitous conversion?
        ProjectivePoint::from(AffinePoint::decompress(qx, qy.is_odd()).value)
  }
}

impl  FieldElement {
    fn sgn0(self) -> Choice {
        FieldElement::is_odd(self)
    }
}
