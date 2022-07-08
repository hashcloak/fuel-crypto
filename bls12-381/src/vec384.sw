library vec384;

use std::u128::*;

// Stores field element with max 384 bits
pub struct vec384 {
    ls: [u64; 6],
}

const ZERO: vec384 = vec384 {ls: [0, 0, 0, 0, 0, 0]};

/*
    z = -0xd201000000010000
    (z-1)^2 * (z^4 - z^2 + 1)/3 + z
    4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787
    (381 bits)
*/
const BLS12_381_P: vec384 = vec384 {
    ls: [0xb9feffffffffaaab,
    0x1eabfffeb153ffff,
    0x6730d2a0f6b0f624,
    0x64774b84f38512bf,
    0x4b1ba7b6434bacd7,
    0x1a0111ea397fe69a]
};

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