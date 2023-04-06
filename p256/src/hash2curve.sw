library;

use ::field::FieldElement;
use ::projective::ProjectivePoint;

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
/*
commented out because don't know yet how to test this...

const PARAMS: OsswuMapParams<FieldElement> = OsswuMapParams {
    // See section 8.7 in
    // <https://datatracker.ietf.org/doc/draft-irtf-cfrg-hash-to-curve/>
    c1: [
        0xffff_ffff_bfff_ff0b,
        0xffff_ffff_ffff_ffff,
        0xffff_ffff_ffff_ffff,
        0x3fff_ffff_ffff_ffff,
    ],
    // 0x25e9711ae8c0dadc 0x46fdbcb72aadd8f4 0x250b65073012ec80 0xbc6ecb9c12973975
    c2: FieldElement::from_bytes_unchecked([
        0x25, 0xe9, 0x71, 0x1a, 0xe8, 0xc0, 0xda, 0xdc, 0x46, 0xfd, 0xbc, 0xb7, 0x2a, 0xad,
        0xd8, 0xf4, 0x25, 0x0b, 0x65, 0x07, 0x30, 0x12, 0xec, 0x80, 0xbc, 0x6e, 0xcb, 0x9c,
        0x12, 0x97, 0x39, 0x75,
    ]),
    // 0x3f8731abdd661adc 0xa08a5558f0f5d272 0xe953d363cb6f0e5d 0x405447c01a444533
    map_a: FieldElement::from_bytes_unchecked([
        0x3f, 0x87, 0x31, 0xab, 0xdd, 0x66, 0x1a, 0xdc, 0xa0, 0x8a, 0x55, 0x58, 0xf0, 0xf5,
        0xd2, 0x72, 0xe9, 0x53, 0xd3, 0x63, 0xcb, 0x6f, 0x0e, 0x5d, 0x40, 0x54, 0x47, 0xc0,
        0x1a, 0x44, 0x45, 0x33,
    ]),
    // 0x00000000000006eb
    map_b: FieldElement::from_bytes_unchecked([
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x06, 0xeb,
    ]),
    // 0xffffffffffffffff 0xffffffffffffffff 0xffffffffffffffff 0xfffffffefffffc24
    z: FieldElement::from_bytes_unchecked([
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe,
        0xff, 0xff, 0xfc, 0x24,
    ]),
};

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
    xd = conditional_select(tv, xd, xd.is_zero());

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
    x = x * xd.invert().unwrap();

    // if e2, y = y1, else y = y2
    let mut y = Self::conditional_select(y2, y1, e2);

    // reference: y.conditional_assign(&-y, self.sgn0() ^ y.sgn0());
    /*
    impl Sgn0 for FieldElement {
    fn sgn0(&self) -> Choice {
        self.normalize().is_odd()
    }
}
    */
    y = conditional_select(y.negate(), y, self.is_odd().bitwise_xor(y.is_odd()));
    (x, y)
  }
}

impl FieldElement {
  fn map_to_curve(self) -> ProjectivePoint {
      let (qx, qy) = self.osswu();

    // TODO what are a and b
      let alpha = qx * qx * qx + (EQUATION_A * qx) + EQUATION_B;
      let beta = alpha.sqrt();

      let y = conditional_select(beta.negate(), beta, beta.is_odd().ct_eq(qy.is_odd()));
            // TODO(tarcieri): assert that `qy` is correct? less circuitous conversion?
      ProjectivePoint { x, y, infinity: 0 }
  }
}
*/