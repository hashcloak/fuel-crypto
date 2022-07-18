library vect;

dep consts;

use std::{option::*, u128::*, vec::Vec};
use consts::*;
use std::logging::log;
// Stores field element with max 384 bits
// element in fp
pub struct vec384 {
    ls: [u64;
    6],
}

pub struct vec768 {
    ls: [u64;
    12],
}

// element in fp2
pub struct vec384x {
    r: vec384, //"real" part
    i: vec384, //"imaginary" part
}



//TODO: remove these. Only for developing and testing atm
pub const ZERO: vec384 = vec384 {
    ls: [0, 0, 0, 0, 0, 0]
};
pub const ZERO_X: vec384x = vec384x {
    r: ZERO, i: ZERO
};

/*
    z = -0xd201000000010000
    (z-1)^2 * (z^4 - z^2 + 1)/3 + z
    4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787
    (381 bits)
*/
pub const BLS12_381_P: vec384 = vec384 {
    ls: [0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a]
};
/// INV = -(P^{-1} mod 2^64) mod 2^64
pub const INV: u64 = 0x89f3fffcfffcfffd;

// START FUNCTIONS

pub fn unpack_or_0(x: Option<u64>) -> u64 {
    match x {
        Option::Some(val) => val, Option::None => 0, 
    }
}

pub fn add_mod_n(a: Vec<u64>, b: Vec<u64>, p: Vec<u64>, n: u64) -> Vec<u64> {
    let mut limbx: u64 = 0;
    let mut carry: u64 = 0;
    let mut tmp = ~Vec::new::<u64>();

    let mut i = 0;
    while i < n {
        // sum with carry of a and b. Returns result and new carry
        let(limb, temp_carry): (u64, u64) = adc(unpack_or_0(a.get(i)), unpack_or_0(b.get(i)), carry);
        tmp.insert(i, limb);
        carry = temp_carry;
        i += 1;
    }

    let mut ret = ~Vec::new::<u64>();
    let mut borrow: u64 = 0;
    i = 0;
    while i < n {
        // sum with borrow of a and b. Returns result and new borrow
        let(limb, temp_borrow): (u64, u64) = sbb(unpack_or_0(tmp.get(i)), unpack_or_0(p.get(i)), borrow);
        ret.insert(i, limb);
        borrow = temp_borrow;
        i += 1;
    }

    let mask: u64 = borrow * ~u64::max();
    let mut res = ~Vec::new::<u64>();
    i = 0;
    while i < n {
        let value = (unpack_or_0(ret.get(i)) & not(mask)) | (unpack_or_0(tmp.get(i)) & mask);
        res.insert(i, value);
        i += 1;
    }
    res
}

pub fn mul_mont_n(a: Vec<u64>, b: Vec<u64>, p: Vec<u64>, n0: u64, n: u64) -> Vec<u64> {
    let mut mx: U128 = ~U128::from(0, unpack_or_0(b.get(0)));
    let mut hi: U128 = ~U128::from(0, 0);
    let mut tmp: Vec<u64> = ~Vec::new::<u64>();
    let mut tmp2: Vec<u64> = ~Vec::new::<u64>();//new vector
    let mut tmp3: Vec<u64> = ~Vec::new::<u64>();//new vector
    let mut i = 0;
    while i < n {
        let ai: U128 = ~U128::from(0, unpack_or_0(a.get(i)));
        let limbx = mx * ai + hi;
        tmp.insert(i, limbx.lower);
        hi = ~U128::from(0, limbx.upper);
        i += 1;
    }

//0x89f3fffcfffcfffd * 1
    let mut mx_temp: u64 = (~U128::from(0, n0) * ~U128::from(0, unpack_or_0(tmp.get(0)))).lower;
    let mut mx: U128 = ~U128::from(0, mx_temp);
    //mx = ~U128::from(0, n0) * ~U128::from(0, unpack_or_0(tmp.get(0)));
    tmp.insert(i, hi.lower);
    let mut carry: u64 = 0;
    let mut j = 0;
    let mut limbx: U128 = ~U128::from(0, 0);
    while true {
        let p0: U128 = ~U128::from(0, unpack_or_0(p.get(0)));
        let tmp0: U128 = ~U128::from(0, unpack_or_0(tmp.get(0)));
        //log(mx);//000000000000000089f3fffcfffcfffd
        //2: 3947442df695f8f1286adb92d9d113e8
        //log(p0);//0000000000000000b9feffffffffaaab
        //2: 0000000000000000b9feffffffffaaab
        //log(tmp0);//00000000000000000000000000000001
        //2: 00000000000000006a4aaa14be07a408
        //1: 16^^643abe09d200a404ffffffffffffffff
        //2: 16^^299d8e4220faed31901f94fb2b3b54280000000000000000
        //this is 190 bits instead of fitting into 128
        limbx = (mx * p0) + tmp0;
        //log(limbx);//643abe09d200a4050000000000000000
        //2: f21393888e24ec0f0000000000000000
        hi = ~U128::from(0, limbx.upper);
        //log(hi);//0000000000000000643abe09d200a405
        //2: 0000000000000000f21393888e24ec0f
        i = 1;
        while i < n {
            let pi: U128 = ~U128::from(0, unpack_or_0(p.get(i)));
            let tmpi: U128 = ~U128::from(0, unpack_or_0(tmp.get(i)));
            //log(pi);//00000000000000001eabfffeb153ffff
            //log(tmpi);//00000000000000000000000000000000
            limbx = (mx * pi + hi) + tmpi;
            //log(limbx);//108747eeefa29c0f6a4aaa14be07a408
            tmp2.insert(i - 1, limbx.lower);
            hi = ~U128::from(0, limbx.upper);
            //log(hi);//0000000000000000108747eeefa29c0f
            i += 1;
        }
        limbx = ~U128::from(0, unpack_or_0(tmp.get(i))) + (hi + ~U128::from(0, carry));
        tmp2.insert(i - 1, limbx.lower);
        carry = limbx.lower;

        j += 1;
        if j == n {
            break;
        }
        mx = ~U128::from(0, unpack_or_0(b.get(j)));
        hi = ~U128::from(0, 0);
        //log(mx);//00000000000000006730d2a0f6b0f624
        //log(hi);//00000000000000000000000000000000
        i = 0;
        while i < n {
            let ai: U128 = ~U128::from(0, unpack_or_0(a.get(i)));
            let tmpi: U128 = ~U128::from(0, unpack_or_0(tmp2.get(i)));
            //log(ai);//379b7b3fafdc26ed5d4f098d2923b9a3
            //log(tmpi);//0000000000000000379b7b3fafdc26ed
            limbx = (mx * ai + hi) + tmpi;
            //log(limbx);//000000000000000064774b84f38512bf
            tmp3.insert(i, limbx.lower);
            hi = ~U128::from(0, limbx.upper);
            //log(hi);//00000000000000000000000000000000
            i += 1;
        }
        let mut mx_temp: u64 = (~U128::from(0, n0) * ~U128::from(0, unpack_or_0(tmp3.get(0)))).lower;
        let mut mx: U128 = ~U128::from(0, mx_temp);

        //mx = ~U128::from(0, n0) * ~U128::from(0, unpack_or_0(tmp.get(0)));
        //log(mx);//3623991cf3a341e8622385e49d0feeb0 (126 bits)
        limbx = hi + ~U128::from(0, carry);
        //log(limbx);//00000000000000003623991cf3a341e8
        tmp3.insert(i, limbx.lower);
        //log(tmp);//00000000000000004b1ba7b6434bacd7
        carry = limbx.upper;
        //log(carry);//00000000000000000000000000000000

        //Conclusion so far: mx will become really large and then overflow in next iteration
    }

    let mut borrow: u64 = 0;
    i = 0;
    let mut ret: Vec<u64> = ~Vec::new::<u64>();
    while i < n {
        let pi: U128 = ~U128::from(0, unpack_or_0(p.get(i)));
        let tmpi: U128 = ~U128::from(0, unpack_or_0(tmp3.get(i)));
        let pi_w_borrow = pi + ~U128::from(0, borrow);
        // Prevent underflow. When U256 arithmetic is available we can create sbb_256
        let(sub_res, b_res): (U128, u64) = if pi_w_borrow < tmpi {
            (tmpi - pi_w_borrow, 0)
        } else {
            (~U128::max() - (pi_w_borrow - tmpi - ~U128::from(0,1)), 1)
        };
        limbx = sub_res;
        //borrow = b_res;
        ret.insert(i, limbx.lower);
        borrow = limbx.upper & 0x1;
        i += 1;
    }
    //log(carry);
    //log(borrow);
    let mask: u64 = if carry >= borrow {
        carry-borrow
    } else {
        ~u64::max() - (borrow - carry - 1)
    };

//    mask = carry - borrow;
    // let mask: u64 = borrow * ~u64::max();

    i = 0;
    let mut res: Vec<u64> = ~Vec::new::<u64>();
    while i < n {
        let value = (unpack_or_0(ret.get(i)) & not(mask)) | (unpack_or_0(tmp3.get(i)) & mask);
        res.insert(i, value);
        i += 1;
    }
    res
}

pub fn sub_mod_n(a: Vec<u64>, b: Vec<u64>, p: Vec<u64>, n: u64) -> Vec<u64> {
    let mut limbx: u64 = 0;
    let mut borrow: u64 = 0;
    let mut i = 0;
    let mut ret = ~Vec::new::<u64>();

    while i < n {
        let(limb, temp_borrow): (u64, u64) = sbb(unpack_or_0(a.get(i)), unpack_or_0(b.get(i)), borrow);
        ret.insert(i, limb);
        borrow = temp_borrow;
        i += 1;
    }

    let mask: u64 = borrow * ~u64::max();
    let mut res = ~Vec::new::<u64>();
    let mut carry: u64 = 0;
    while i < n {
        let(limb, temp_carry): (u64, u64) = adc(unpack_or_0(ret.get(i)), unpack_or_0(p.get(i)) & mask, carry);
        res.insert(i, limb);
        carry = temp_carry;
        i += 1;
    }
    res
}

// TODO
pub fn mul_mont_384(a: vec384, b: vec384, p: vec384, n0: u64) -> vec384 {
    ZERO
}

pub fn sqr_mont_384(a: vec384, b: vec384, p: vec384, n0: u64) -> vec384 {
    //TODO
    ZERO
}


pub fn redc_mont_n(a: Vec<u64>, p: Vec<u64>, n0: u64, n: u64) -> Vec<u64> {
    let mut j = 0;
    let mut i = 1;
    let mut b: Vec<u64> = a;
    //let mut limbx: U128 = ~U128::from(0,0);
    let mut tmp: Vec<u64> = ~Vec::new::<u64>();
    while j < n {
        let mx_temp: u64 = (~U128::from(0, n0) * ~U128::from(0, unpack_or_0(b.get(0)))).lower;
        let mx: U128 = ~U128::from(0, mx_temp) ;
        let mut limbx = mx * ~U128::from(0, unpack_or_0(p.get(0))) + ~U128::from(0, unpack_or_0(b.get(0)));
        let mut hi: U128 = ~U128::from(0, limbx.upper);
        i = 1;
        while i < n {
            let pi: U128 = ~U128::from(0, unpack_or_0(p.get(i)));
            let bi: U128 = ~U128::from(0, unpack_or_0(b.get(i)));
            limbx = (mx * pi + hi) + bi;
            tmp.insert(i-1, limbx.lower);
            hi = ~U128::from(0, limbx.upper);
            i += 1;
        }
        tmp.insert(i-1, hi.lower);
        b = tmp;
        j += 1;
    }

    let mut tmp2: Vec<u64> = ~Vec::new::<u64>();
    let mut carry = 0;
    i = 0;
    while i < n {
        let ani: U128 = ~U128::from(0, unpack_or_0(a.get(n+i)));
        let tmpi: U128 = ~U128::from(0, unpack_or_0(tmp.get(i)));
        let carryi: U128 = ~U128::from(0, carry);
        let limbx = ani + (tmpi + carryi);
        tmp2.insert(i, limbx.lower);
        carry = limbx.upper;
        i += 1;
    }

    let mut borrow = 0;
    let mut res: Vec<u64> = ~Vec::new::<u64>();
    i = 0;
    while i < n {
        let tmp2i: U128 = ~U128::from(0, unpack_or_0(tmp2.get(i)));
        let pi: U128 = ~U128::from(0, unpack_or_0(p.get(i)));
        let borrow_i: U128 = ~U128::from(0, borrow);
        let pi_w_borrow = pi + borrow_i;
        // Prevent underflow. When U256 arithmetic is available we can create sbb_256
        let(sub_res, b_res): (U128, u64) = if pi_w_borrow < tmp2i {
            (tmp2i - pi_w_borrow, 0)
        } else {
            (~U128::max() - (pi_w_borrow - tmp2i - ~U128::from(0,1)), 1)
        };
        let mut limbx = sub_res;
        //borrow = b_res;
        borrow = limbx.upper & 0x1;
        res.insert(i, limbx.lower);
        i += 1;
    }
    //arithmetic overflow is happning
    //let mut mask = carry - borrow;
    //let mask: u64 = borrow * ~u64::max();
    let mut mask = if carry >= borrow {
            carry - borrow
        } else {
            ~u64::max() - (borrow - carry - 1)
        };
    let mut result: Vec<u64> = ~Vec::new::<u64>();
    i = 0;
    while i < n {
        let result_i = (unpack_or_0(res.get(i)) & not(mask)) | (unpack_or_0(tmp2.get(i)) & mask);
        result.insert(i, result_i);
        i += 1;
    }

    result
}

pub fn redc_mont_384(a: vec768, p: vec384, n0: u64) -> vec384 {
    //TODO
    ZERO
}

pub fn from_mont_384(a: vec384, p: vec384, n0: u64) -> vec384 {
    //TODO
    ZERO
}

// Original impl:
// static inline bool_t is_zero(limb_t l)
// {   return (~l & (l - 1)) >> (LIMB_T_BITS - 1);   }
//TODO
pub fn is_zero(l: u64) -> u64 {
    // (~l & (l-1)) >> 63
    0
}

pub fn vec_is_zero(a: Vec<u64>, num: u64) -> u64 {
    //TODO
    0
}

// TODO rewrite without if branch
// If x >= y: x-y, else max::U128 - (y-x)
pub fn subtract_wrap(x: U128, y: U128) -> U128 {
    if y > x {
        ~U128::max() - (y - x - U128 {
            lower: 1, upper: 0
        })
    } else {
        x - y
    }
}

// TODO rewrite without if branch
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
    let a_128: U128 = U128 {
        lower: a,
        upper: 0,
    };
    let b_128: U128 = U128 {
        lower: b,
        upper: 0,
    };
    let borrow_128: U128 = U128 {
        lower: borrow,
        upper: 0,
    };

    let res: U128 = subtract_wrap(a_128, b_128 + borrow_128);
    (res.lower, res.upper >> 63) //(result, borrow)
}

pub fn not(input: u64) -> u64 {
    ~u64::max() - input
}

// from https://github.com/zkcrypto/bls12_381
// If a >= p, return a-p, else return a
pub fn subtract_p(a: vec384, p: vec384) -> vec384 {
    let(r0, borrow) = sbb(a.ls[0], p.ls[0], 0);
    let(r1, borrow) = sbb(a.ls[1], p.ls[1], borrow);
    let(r2, borrow) = sbb(a.ls[2], p.ls[2], borrow);
    let(r3, borrow) = sbb(a.ls[3], p.ls[3], borrow);
    let(r4, borrow) = sbb(a.ls[4], p.ls[4], borrow);
    let(r5, borrow) = sbb(a.ls[5], p.ls[5], borrow);

    // If underflow occurred on the final limb, borrow = 1, otherwise
    // borrow = 0. We convert it into a mask.
    let mut mask = borrow * ~u64::max();
    let r0 = (a.ls[0] & mask) | (r0 & not(mask));
    let r1 = (a.ls[1] & mask) | (r1 & not(mask));
    let r2 = (a.ls[2] & mask) | (r2 & not(mask));
    let r3 = (a.ls[3] & mask) | (r3 & not(mask));
    let r4 = (a.ls[4] & mask) | (r4 & not(mask));
    let r5 = (a.ls[5] & mask) | (r5 & not(mask));

    vec384 {
        ls: [r0,
        r1, r2, r3, r4, r5]
    }
}

//TODO this function is also in edwards25519/src/field_element.sw (called add64). Where do we want to place these overlapping functions?
//returns sum with carry of a and b
pub fn adc(a: u64, b: u64, carry: u64) -> (u64, u64) {
    let a_128: U128 = U128 {
        upper: 0,
        lower: a,
    };
    let b_128: U128 = U128 {
        upper: 0,
        lower: b,
    };
    let c_128: U128 = U128 {
        upper: 0,
        lower: carry,
    };

    let sum: u64 = (a_128 + b_128 + c_128).lower;
    let carry_res = ((a & b) | ((a | b) & not(sum))) >> 63;

    (sum, carry_res)
}

// from https://github.com/zkcrypto/bls12_381
pub fn add_mod_384(a: vec384, b: vec384, p: vec384) -> vec384 {
    let(d0, carry) = adc(a.ls[0], b.ls[0], 0);
    let(d1, carry) = adc(a.ls[1], b.ls[1], carry);
    let(d2, carry) = adc(a.ls[2], b.ls[2], carry);
    let(d3, carry) = adc(a.ls[3], b.ls[3], carry);
    let(d4, carry) = adc(a.ls[4], b.ls[4], carry);
    let(d5, _) = adc(a.ls[5], b.ls[5], carry);

    //subtract p if needed
    subtract_p(vec384 {
        ls: [d0, d1, d2, d3, d4, d5]
    },
    p)
}

// from https://github.com/zkcrypto/bls12_381
pub fn neg(a: vec384, p: vec384) -> vec384 {
    let(d0, borrow) = sbb(p.ls[0], a.ls[0], 0);
    let(d1, borrow) = sbb(p.ls[1], a.ls[1], borrow);
    let(d2, borrow) = sbb(p.ls[2], a.ls[2], borrow);
    let(d3, borrow) = sbb(p.ls[3], a.ls[3], borrow);
    let(d4, borrow) = sbb(p.ls[4], a.ls[4], borrow);
    let(d5, _) = sbb(p.ls[5], a.ls[5], borrow);

    // We need a mask that's 0 when a==p and 2^65-1 otherwise
    // TODO improve this
    let mut a_is_p = 0;
    if (a.ls[0] | a.ls[1] | a.ls[2] | a.ls[3] | a.ls[4] | a.ls[5]) == 0 {
        a_is_p = 1; //don't know is there's a native conversion
    } else {
        a_is_p = 0;
    }

    let mask = subtract_wrap_64(a_is_p, 1);

    vec384 {
        ls: [d0 & mask,
        d1 & mask, d2 & mask, d3 & mask, d4 & mask, d5 & mask, ]
    }
}

pub fn sub_mod_384(a: vec384, b: vec384, p: vec384) -> vec384 {
    add_mod_384(a, neg(b, p), p)
}

//returns the result and new carry of a + b*c + carry
pub fn mac(a: u64, b: u64, c: u64, carry: u64) -> (u64, u64) {
    let A: U128 = U128 {
        upper: 0,
        lower: a,
    };
    let B: U128 = U128 {
        upper: 0,
        lower: b,
    };
    let C: U128 = U128 {
        upper: 0,
        lower: c,
    };
    let CARRY: U128 = U128 {
        upper: 0,
        lower: carry,
    };
    let res: U128 = A + (B * C) + CARRY;
    (res.lower, res.upper)
}

//returns a*b mod(2^64)
pub fn multiply_wrap(a: u64, b: u64) -> u64 {
    let A: U128 = U128 {
        upper: 0,
        lower: a,
    };
    let B: U128 = U128 {
        upper: 0,
        lower: b,
    };

    (A * B).lower
}

pub fn mul_by_8_mod_384(a: vec384, p: vec384) -> vec384 {
    lshift_mod_384(a, 3, p)
}

pub fn mul_by_3_mod_384(a: vec384, p: vec384) -> vec384 {
    let temp = add_mod_384(a, a, p);
    add_mod_384(temp, a, p)
}

pub fn cneg_mod_384(a: vec384, flag: u64, p: vec384) -> vec384 {
    //TODO
    ZERO
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

pub fn rshift_mod_384(a: vec384, n: u64, p: vec384) -> vec384 {
    //TODO
    ZERO
}

pub fn div_by_2_mod_384(a: vec384, p: vec384) -> vec384 {
    //TODO
    ZERO
}

pub fn mul_by_8_mod_384x(a: vec384x, p: vec384) -> vec384x {
    //TODO
    ZERO_X
}

pub fn mul_by_3_mod_384x(a: vec384x, p: vec384) -> vec384x {
    //TODO
    ZERO_X
}

fn to_vec(v: vec384) -> Vec<u64> {
    let mut res = ~Vec::new::<u64>();
    let mut i = 0;
    while i < 6 {
        res.push(v.ls[i]);
        i += 1;
    }
    res
}

pub fn mul_mont_384x(a: vec384x, b: vec384x, p: vec384, n0: u64) -> vec384x {
    let a0_vec = to_vec(a.r);
    let a1_vec = to_vec(a.i);
    let b0_vec = to_vec(b.r);
    let b1_vec = to_vec(b.i);
    let p_vec = to_vec(p);

    let mut aa = add_mod_n(a0_vec, a1_vec, p_vec, NLIMBS_384);
    let mut bb = add_mod_n(b0_vec, b1_vec, p_vec, NLIMBS_384);
    // let bb_temp = mul_mont_n(bb, aa, p_vec, n0, NLIMBS_384);
    // aa = mul_mont_n(a0_vec, b0_vec, p_vec, n0, NLIMBS_384);

    ZERO_X
}

pub fn sqr_mont_384x(a: vec384x, p: vec384, n0: u64) -> vec384x {
    //TODO. Has a non-assembly impl in blst in src/vect.c
    ZERO_X
}
