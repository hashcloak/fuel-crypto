library vec384;

use std::u128::*;

// Stores field element with max 384 bits
// element in fp
pub struct vec384 {
    ls: [u64; 6],
}

// element in fp2
pub struct vec384x {
    r: vec384, //"real" part
    i: vec384 //"imaginary" part
}

pub const ZERO: vec384 = vec384 {ls: [0, 0, 0, 0, 0, 0]};

/*
    z = -0xd201000000010000
    (z-1)^2 * (z^4 - z^2 + 1)/3 + z
    4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787
    (381 bits)
*/
pub const BLS12_381_P: vec384 = vec384 {
    ls: [0xb9feffffffffaaab,
    0x1eabfffeb153ffff,
    0x6730d2a0f6b0f624,
    0x64774b84f38512bf,
    0x4b1ba7b6434bacd7,
    0x1a0111ea397fe69a]
};
/// INV = -(P^{-1} mod 2^64) mod 2^64
pub const INV: u64 = 0x89f3fffcfffcfffd;

// If x >= y: x-y, else max::U128 - (y-x)
pub fn subtract_wrap(x: U128, y: U128) -> U128 {
    if y > x {
        ~U128::max() - (y - x - U128 { lower: 1, upper: 0})
    } else {
        x - y
    }
}

// If x >= y: x-y, else max::U64 - (y-x)
pub fn subtract_wrap_64(x: u64, y: u64) -> u64 {
    if y > x {
        ~u64::max() - (y - x - 1)
    } else {
        x - y
    }
}

/// Compute a - (b + borrow), returning the result and the new borrow (0 or 1).
pub fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64) {
    let a_128: U128 = U128 { lower: a, upper: 0};
    let b_128: U128 = U128 { lower: b, upper: 0};
    let borrow_128: U128 = U128 { lower: borrow, upper: 0};

    let res: U128 = subtract_wrap(a_128, b_128 + borrow_128);
    (res.lower, res.upper >> 63) //(result, borrow)
}

pub fn not(input: u64) -> u64 {
    ~u64::max() - input
}

// from https://github.com/zkcrypto/bls12_381
// If a >= p, return a-p, else return a
pub fn subtract_p(a: vec384 , p: vec384) -> vec384 {
    let (r0, borrow) = sbb(a.ls[0], p.ls[0], 0);
    let (r1, borrow) = sbb(a.ls[1], p.ls[1], borrow);
    let (r2, borrow) = sbb(a.ls[2], p.ls[2], borrow);
    let (r3, borrow) = sbb(a.ls[3], p.ls[3], borrow);
    let (r4, borrow) = sbb(a.ls[4], p.ls[4], borrow);
    let (r5, borrow) = sbb(a.ls[5], p.ls[5], borrow);

    // If underflow occurred on the final limb, borrow = 1, otherwise
    // borrow = 0. We convert it into a mask.
    let mut mask = borrow * ~u64::max();
    let r0 = (a.ls[0] & mask) | (r0 & not(mask));
    let r1 = (a.ls[1] & mask) | (r1 & not(mask));
    let r2 = (a.ls[2] & mask) | (r2 & not(mask));
    let r3 = (a.ls[3] & mask) | (r3 & not(mask));
    let r4 = (a.ls[4] & mask) | (r4 & not(mask));
    let r5 = (a.ls[5] & mask) | (r5 & not(mask));

    vec384{ ls: [r0, r1, r2, r3, r4, r5]}
}
    
//TODO this function is also in edwards25519/src/field_element.sw (called add64). Where do we want to place these overlapping functions?
//returns sum with carry of a and b
pub fn adc(a: u64, b: u64, carry: u64) -> (u64, u64) {
    let a_128 :U128 = U128 { upper: 0, lower: a };
    let b_128 :U128 = U128 { upper: 0, lower: b };
    let c_128: U128 = U128 { upper: 0, lower: carry };

    let sum: u64 = (a_128 + b_128 + c_128).lower;
    let carry_res =  ((a & b) | ((a | b) & not(sum))) >> 63; 

    (sum, carry_res)
}

// from https://github.com/zkcrypto/bls12_381
pub fn add_mod_384(a: vec384, b: vec384, p: vec384) -> vec384 {
    let (d0, carry) = adc(a.ls[0], b.ls[0], 0);
    let (d1, carry) = adc(a.ls[1], b.ls[1], carry);
    let (d2, carry) = adc(a.ls[2], b.ls[2], carry);
    let (d3, carry) = adc(a.ls[3], b.ls[3], carry);
    let (d4, carry) = adc(a.ls[4], b.ls[4], carry);
    let (d5, _) = adc(a.ls[5], b.ls[5], carry);

    //subtract p if needed
    subtract_p(vec384{ ls: [d0, d1, d2, d3, d4, d5] }, p)
}

// from https://github.com/zkcrypto/bls12_381
pub fn neg(a: vec384, p: vec384) -> vec384 {
    let (d0, borrow) = sbb(p.ls[0], a.ls[0], 0);
    let (d1, borrow) = sbb(p.ls[1], a.ls[1], borrow);
    let (d2, borrow) = sbb(p.ls[2], a.ls[2], borrow);
    let (d3, borrow) = sbb(p.ls[3], a.ls[3], borrow);
    let (d4, borrow) = sbb(p.ls[4], a.ls[4], borrow);
    let (d5, _) = sbb(p.ls[5], a.ls[5], borrow);

    // We need a mask that's 0 when a==p and 2^65-1 otherwise
    // TODO improve this
    let mut a_is_p = 0;
    if (a.ls[0] | a.ls[1] | a.ls[2] | a.ls[3] | a.ls[4] | a.ls[5]) == 0 {
        a_is_p = 1; //don't know is there's a native conversion
    } else {
        a_is_p = 0;
    }

    let mask = subtract_wrap_64(a_is_p, 1);

    vec384{ ls: [
        d0 & mask,
        d1 & mask,
        d2 & mask,
        d3 & mask,
        d4 & mask,
        d5 & mask,
    ]}
}

pub fn sub_mod_384(a: vec384, b: vec384, p: vec384) -> vec384 {
    add_mod_384(a, neg(b, p), p)
}

//returns the result and new carry of a + b*c + carry
pub fn mac (a: u64, b: u64, c: u64, carry: u64) -> (u64, u64) {
    let A: U128 = U128 {upper: 0, lower: a};
    let B: U128 = U128 {upper: 0, lower: b};
    let C: U128 = U128 {upper: 0, lower: c};
    let CARRY: U128 = U128 {upper: 0, lower: carry};
    let res: U128 = A + (B * C) + CARRY;
    (res.lower, res.upper)
}

//returns a*b mod(2^64) 
pub fn multiply_wrap(a: u64, b:u64) -> u64 {
    let A: U128 = U128{upper: 0, lower: a};
    let B: U128 = U128{upper: 0, lower: b};

    (A*B).lower
}

// from https://github.com/zkcrypto/bls12_381
pub fn montgomery_reduction(t: [u64;12]) -> vec384 {
    let k = multiply_wrap(t[0], INV);
    
    let r0: (u64, u64) = mac(t[0], k, BLS12_381_P.ls[0], 0);
    let r1: (u64, u64) = mac(t[1], k, BLS12_381_P.ls[1], r0.1);
    let r2: (u64, u64) = mac(t[2], k, BLS12_381_P.ls[2], r1.1);
    let r3: (u64, u64) = mac(t[3], k, BLS12_381_P.ls[3], r2.1);
    let r4: (u64, u64) = mac(t[4], k, BLS12_381_P.ls[4], r3.1);
    let r5: (u64, u64) = mac(t[5], k, BLS12_381_P.ls[5], r4.1);
    let r6_7: (u64, u64) = adc(t[6], 0, r5.1);

    let k = multiply_wrap(r1.0, INV);
    let r0: (u64, u64) = mac(r1.0, k, BLS12_381_P.ls[0], 0);
    let r2: (u64, u64) = mac(r2.0, k, BLS12_381_P.ls[1], r0.1);
    let r3: (u64, u64) = mac(r3.0, k, BLS12_381_P.ls[2], r2.1);
    let r4: (u64, u64) = mac(r4.0, k, BLS12_381_P.ls[3], r3.1);
    let r5: (u64, u64) = mac(r5.0, k, BLS12_381_P.ls[4], r4.1);
    let r6: (u64, u64) = mac(r6_7.0, k, BLS12_381_P.ls[5], r5.1);
    let r7_8: (u64, u64) = adc(t[7], r6_7.1, r6.1);

    let k = multiply_wrap(r2.0, INV);
    let r0: (u64, u64) = mac(r2.0, k, BLS12_381_P.ls[0], 0);
    let r3: (u64, u64) = mac(r3.0, k, BLS12_381_P.ls[1], r0.1);
    let r4: (u64, u64) = mac(r4.0, k, BLS12_381_P.ls[2], r3.1);
    let r5: (u64, u64) = mac(r5.0, k, BLS12_381_P.ls[3], r4.1);
    let r6: (u64, u64) = mac(r6.0, k, BLS12_381_P.ls[4], r5.1);
    let r7: (u64, u64) = mac(r7_8.0, k, BLS12_381_P.ls[5], r6.1);
    let r8_9: (u64, u64) = adc(t[8], r7_8.1, r7.1);

    let k = multiply_wrap(r3.0, INV);
    let r0: (u64, u64) = mac(r3.0, k, BLS12_381_P.ls[0], 0);
    let r4: (u64, u64) = mac(r4.0, k, BLS12_381_P.ls[1], r0.1);
    let r5: (u64, u64) = mac(r5.0, k, BLS12_381_P.ls[2], r4.1);
    let r6: (u64, u64) = mac(r6.0, k, BLS12_381_P.ls[3], r5.1);
    let r7: (u64, u64) = mac(r7.0, k, BLS12_381_P.ls[4], r6.1);
    let r8: (u64, u64) = mac(r8_9.0, k, BLS12_381_P.ls[5], r7.1);
    let r9_10: (u64, u64) = adc(t[9], r8_9.1, r8.1);

    let k = multiply_wrap(r4.0, INV);
    let r0: (u64, u64) = mac(r4.0, k, BLS12_381_P.ls[0], 0);
    let r5: (u64, u64) = mac(r5.0, k, BLS12_381_P.ls[1], r0.1);
    let r6: (u64, u64) = mac(r6.0, k, BLS12_381_P.ls[2], r5.1);
    let r7: (u64, u64) = mac(r7.0, k, BLS12_381_P.ls[3], r6.1);
    let r8: (u64, u64) = mac(r8.0, k, BLS12_381_P.ls[4], r7.1);
    let r9: (u64, u64) = mac(r9_10.0, k, BLS12_381_P.ls[5], r8.1);
    let r10_11: (u64, u64) = adc(t[10], r9_10.1, r9.1);

    let k = multiply_wrap(r5.0, INV);
    let r0: (u64, u64) = mac(r5.0, k, BLS12_381_P.ls[0], 0);
    let r6: (u64, u64) = mac(r6.0, k, BLS12_381_P.ls[1], r0.1);
    let r7: (u64, u64) = mac(r7.0, k, BLS12_381_P.ls[2], r6.1);
    let r8: (u64, u64) = mac(r8.0, k, BLS12_381_P.ls[3], r7.1);
    let r9: (u64, u64) = mac(r9.0, k, BLS12_381_P.ls[4], r8.1);
    let r10: (u64, u64) = mac(r10_11.0, k, BLS12_381_P.ls[5], r9.1);
    let r11_12 = adc(t[11], r10_11.1, r10.1);

    subtract_p(vec384{ls: [r6.0, r7.0, r8.0, r9.0, r10.0, r11_12.0]}, BLS12_381_P)

}

pub fn mul_by_3_mod_384(a: vec384, p: vec384) -> vec384 {
    let temp = add_mod_384(a, a, p);
    add_mod_384(temp, a, p)
}

pub fn lshift_mod_384(a: vec384, n: u64, p: vec384) -> vec384 {
    let mut i = 0;
    let mut a_temp: vec384 = a;
    while i < n {
        a_temp = add_mod_384(a_temp, a_temp, p);
        i += 1;
    }
    a_temp
}

pub fn mul_by_8_mod_384(a: vec384, p: vec384) -> vec384 {
    lshift_mod_384(a, 3, p)
}