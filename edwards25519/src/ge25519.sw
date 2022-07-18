library ge25519;

use field_element::*;

/* Point representation with extended coordinates, they satisfy:
  x=X/Z
  y=Y/Z
  x*y=T/Z
  See https://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html
*/
pub struct Ge25519 {
    x: Element,
    y: Element,
    z: Element,
    t: Element,
}

// Completed point (https://doc-internal.dalek.rs/curve25519_dalek/backend/serial/curve_models/index.html)
pub struct Ge25519_p1p1 {
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
pub struct Ge25519_p2 {
    x: Element,
    y: Element,
    z: Element,
}

pub struct Ge25519_aff {
    x: Element,
    y: Element,
}

/*
http://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html#doubling-dbl-2008-hwcd
*/
pub fn double(p: Ge25519_p2) -> Ge25519_p1p1 {
    let a = square(p.x);
    let b = square(p.y);
    let mut c = square(p.z);
    c = add(c, c);
    let d = negate(a);

    let mut res_x = add(p.x, p.y);
    res_x = square(res_x);
    res_x = subtract(res_x, a);
    res_x = subtract(res_x, b);
    let res_z = add(d, b);
    let res_t = subtract(res_z, c);
    let res_y = subtract(d, b);

    Ge25519_p1p1 {
        x: res_x,
        y: res_y,
        z: res_Z,
        t: res_t,
    }
}
