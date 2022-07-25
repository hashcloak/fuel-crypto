library ge25519;

// #define ge25519 
// #define ge25519_unpack_vartime
// #define ge25519_pack 
// #define ge25519_add 
// #define ge25519_double
// #define ge25519_scalarmult
// #define ge25519_scalarmult_base

dep fe25519;

//todo remove and only use fe25519
dep field_element;
use field_element::*;

use fe25519::*;

/* 
 * Arithmetic on the twisted Edwards curve -x^2 + y^2 = 1 + dx^2y^2 
 * with d = -(121665/121666) = 37095705934669439343138083508754565189542113879843219016388785533085940283555
 * Base point: (15112221349535400772501151409588531511454012693041857206046113283949847762202,46316835694926478169428394003475163141307993866256225615783033603165251855960);
 */

/* d = 37095705934669439343138083508754565189542113879843219016388785533085940283555 */
pub const ge25519_ecd: Element = Element{ l0: 929955233495203, 
        l1: 466365720129213, 
        l2: 1662059464998953, 
        l3: 2033849074728123, 
        l4: 1442794654840575 }; 

/* 2*d = 16295367250680780974490674513165176452449235426866156013048779062215315747161 */
pub const ge25519_ec2d: Element = Element{ l0: 1859910466990425, 
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
        x: fe25519_mul(p.x, p.t),
        y: fe25519_mul(p.y, p.z),
        z: fe25519_mul(p.z, p.t)
    }
}

// TODO test
pub fn p1p1_to_p3(p: ge25519_p1p1) -> ge25519 {
    let p2 = p1p1_to_p2(p);
    ge25519 {
        x: p2.x,
        y: p2.y,
        z: p2.z,
        t: fe25519_mul(p2.x, p2.y)
    }
}

// TODO test
pub fn ge25519_mixadd2(q: ge25519_aff, r: ge25519) -> ge25519 {
    let qt = fe25519_mul(q.y, q.x);
    let mut a = fe25519_sub(r.y, r.x); /* A = (Y1-X1)*(Y2-X2) */
    let mut b = fe25519_add(r.y, r.x); /* B = (Y1+X1)*(Y2+X2) */
    let t1 = fe25519_sub(q.y, q.x);
    let t2 = fe25519_add(q.y, q.x);
    a = fe25519_mul(a, t1);
    b = fe25519_mul(b, t2);
    let e = fe25519_sub(b, a); /* E = B-A */
    let h = fe25519_add(b, a);  /* H = B+A */
    let mut c = fe25519_mul(r.t, qt); /* C = T1*k*T2 */
    c = fe25519_mul(c, ge25519_ec2d);
    let d = fe25519_add(r.z, r.z); /* D = Z1*2 */
    let f = fe25519_sub(d, c); /* F = D-C */
    let g = fe25519_add(d, c); /* G = D+C */

    ge25519 {
        x: fe25519_mul(e, f),
        y: fe25519_mul(h, g),
        z: fe25519_mul(g, f),
        t: fe25519_mul(e, h)
    } 

}

// pub fn add_p1p1(p: ge25519, q: ge25519) -> ge25519_p1p1 {
//     //TODO
// }

/*
http://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html#doubling-dbl-2008-hwcd
*/
// TODO TEST
pub fn dbl_p1p1(p: ge25519_p2) -> ge25519_p1p1 {
    let a = fe25519_square(p.x);
    let b = fe25519_square(p.y);
    let mut c = fe25519_square(p.z);
    c = fe25519_add(c, c);
    let d = fe25519_neg(a);

    let mut res_x = fe25519_add(p.x, p.y);
    res_x = fe25519_square(res_x);
    res_x = fe25519_sub(res_x, a);
    res_x = fe25519_sub(res_x, b);
    let res_z = fe25519_add(d, b);
    let res_t = fe25519_sub(res_z, c);
    let res_y = fe25519_sub(d, b);

    ge25519_p1p1 {
        x: res_x,
        y: res_y,
        z: res_z,
        t: res_t,
    }
}

//TODO continue....