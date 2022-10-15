library ge25519;

// #define ge25519 
// #define ge25519_unpack_vartime
// #define ge25519_pack 
// #define ge25519_add 
// #define ge25519_double
// #define ge25519_scalarmult
// #define ge25519_scalarmult_base

dep field_element;
use field_element::*;

/* 
 * Arithmetic on the twisted Edwards curve -x^2 + y^2 = 1 + dx^2y^2 
 * with d = -(121665/121666) = 37095705934669439343138083508754565189542113879843219016388785533085940283555
 * Base point: (15112221349535400772501151409588531511454012693041857206046113283949847762202,46316835694926478169428394003475163141307993866256225615783033603165251855960);
 */

/* d = 37095705934669439343138083508754565189542113879843219016388785533085940283555 */
pub const GE25519_ECD: Element = Element{ l0: 929955233495203, 
        l1: 466365720129213, 
        l2: 1662059464998953, 
        l3: 2033849074728123, 
        l4: 1442794654840575 }; 

/* 2*d = 16295367250680780974490674513165176452449235426866156013048779062215315747161 */
pub const GE25519_EC2D: Element = Element{ l0: 1859910466990425, 
        l1: 932731440258426, 
        l2: 1072319116312658, 
        l3: 1815898335770999, 
        l4: 633789495995903 }; 

pub struct ge25519_aff {
    x: Element,
    y: Element
}

/* Point representation with extended coordinates, they satisfy:
  x=X/Z
  y=Y/Z
  x*y=T/Z
  See https://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html
*/
pub struct ge25519 {
    x: Element,
    y: Element,
    z: Element,
    t: Element,
}

// Completed point (https://doc-internal.dalek.rs/curve25519_dalek/backend/serial/curve_models/index.html)
pub struct ge25519_p1p1 {
    x: Element,
    y: Element,
    z: Element,
    t: Element,
}

/* Projective point. Satisfies:
  x=X/Z
  y=Y/Z
- https://www.hyperelliptic.org/EFD/g1p/auto-twisted-projective.html
- https://doc-internal.dalek.rs/curve25519_dalek/backend/serial/curve_models/index.html
*/
pub struct ge25519_p2 {
    x: Element,
    y: Element,
    z: Element,
}

// TODO test
pub fn p1p1_to_p2(p: ge25519_p1p1) -> ge25519_p2 {
    ge25519_p2 {
        x: p.x * p.t,
        y: p.y * p.z,
        z: p.z * p.t
    }
}

// TODO test
pub fn p1p1_to_p3(p: ge25519_p1p1) -> ge25519 {
    let p2 = p1p1_to_p2(p);
    ge25519 {
        x: p2.x,
        y: p2.y,
        z: p2.z,
        t: p2.x * p2.y
    }
}

// TODO test
pub fn ge25519_mixadd2(q: ge25519_aff, r: ge25519) -> ge25519 {
    let qt = q.y * q.x;
    let mut a = r.y - r.x; /* A = (Y1-X1)*(Y2-X2) */
    let mut b = r.y + r.x; /* B = (Y1+X1)*(Y2+X2) */
    let t1 = q.y - q.x;
    let t2 = q.y + q.x;
    a = a * t1;
    b = b * t2;
    let e = b - a; /* E = B-A */
    let h = b + a;  /* H = B+A */
    let mut c = r.t * qt; /* C = T1*k*T2 */
    c = c * GE25519_EC2D;
    let d = r.z + r.z; /* D = Z1*2 */
    let f = d - c; /* F = D-C */
    let g = d + c; /* G = D+C */

    ge25519 {
        x: e * f,
        y: h * g,
        z: g * f,
        t: e * h
    } 

}

/*
http://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html#doubling-dbl-2008-hwcd
*/
// Can't be tested because errors to Immediate18TooLarge

pub fn dbl_p1p1(p: ge25519_p2) -> ge25519_p1p1 {
    let a = p.x.square();
    let b = p.y.square();
    let mut c = p.z.square();
    c = c + c;
    let d = a.negate();

    let mut res_x = p.x + p.y;
    res_x = res_x.square();
    res_x = res_x - a;
    res_x = res_x - b;
    let res_z = d + b;
    let res_t = res_z - c;
    let res_y = d - b;

    ge25519_p1p1 {
        x: res_x,
        y: res_y,
        z: res_z,
        t: res_t,
    }
}

