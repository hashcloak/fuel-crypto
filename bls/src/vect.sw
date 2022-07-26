library vect;

dep consts;

use std::{option::*, u128::*, vec::Vec};
use consts::*;

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

//TODO: remove these. Only for developing (as placeholder return values) and testing atm
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


/*
WIP

This is following the blst implementation.

It's unclear why the output that the blst gives would be the correct one.

For example: temp_fe_mont_mul implements montgomery mult following ncc impl does give the right "montgomery output",
which has conversions before and after to perform a complete multiplication. 
But this intermediate value doesn't correspond to what the blst impl outputs. 
*/
pub fn mul_mont_n(a: Vec<u64>, b: Vec<u64>, p: Vec<u64>, n0: u64, n: u64) -> Vec<u64> {
    let mut mx: U128 = ~U128::from(0, unpack_or_0(b.get(0)));
    let mut hi: U128 = ~U128::from(0, 0);
    let mut tmp: Vec<u64> = ~Vec::new::<u64>();
    let mut tmp2: Vec<u64> = ~Vec::new::<u64>();
    let mut tmp3: Vec<u64> = ~Vec::new::<u64>();
    let mut i = 0;

    while i < n {
        let ai: U128 = ~U128::from(0, unpack_or_0(a.get(i)));
        let limbx = mx * ai + hi;
        tmp.insert(i, limbx.lower);
        hi = ~U128::from(0, limbx.upper);
        i += 1;
    }
    tmp.insert(i, hi.lower);

    let mut mx_temp: u64 = (~U128::from(0, n0) * ~U128::from(0, unpack_or_0(tmp.get(0)))).lower;
    let mut mx: U128 = ~U128::from(0, mx_temp);
    let mut carry: u64 = 0;
    let mut j = 0;
    let mut limbx: U128 = ~U128::from(0, 0);
    while true {
        let p0: U128 = ~U128::from(0, unpack_or_0(p.get(0)));
        let tmp0: U128 = ~U128::from(0, unpack_or_0(tmp.get(0)));
        limbx = (mx * p0) + tmp0;
        hi = ~U128::from(0, limbx.upper);
        i = 1;

        //just to be sure copying this over
        let mut k = 0;
        while k < 12 {
            tmp2.push(unpack_or_0(tmp.get(k)));
            k += 1;
        }

        while i < n {
            let pi: U128 = ~U128::from(0, unpack_or_0(p.get(i)));
            let tmpi: U128 = ~U128::from(0, unpack_or_0(tmp.get(i)));
            limbx = (mx * pi + hi) + tmpi;
            tmp2.insert(i - 1, limbx.lower);
            hi = ~U128::from(0, limbx.upper);
            i += 1;
        }
        limbx = ~U128::from(0, unpack_or_0(tmp.get(i))) + (hi + ~U128::from(0, carry));
        tmp2.insert(i - 1, limbx.lower);

        carry = limbx.upper;
        j += 1;
        if j == n {
            break;
        }
        mx = ~U128::from(0, unpack_or_0(b.get(j)));
        hi = ~U128::from(0, 0);
        i = 0;

        //just to be sure copying this over
        k = 0;
        while k < 12 {
            tmp3.push(unpack_or_0(tmp2.get(k)));
            k += 1;
        }

        while i < n {
            let ai: U128 = ~U128::from(0, unpack_or_0(a.get(i)));
            let tmpi: U128 = ~U128::from(0, unpack_or_0(tmp2.get(i)));
            limbx = (mx * ai + hi) + tmpi;
            tmp3.insert(i, limbx.lower);
            hi = ~U128::from(0, limbx.upper);
            i += 1;
        }
        let mut mx_temp: u64 = (~U128::from(0, n0) * ~U128::from(0, unpack_or_0(tmp3.get(0)))).lower;
        let mut mx: U128 = ~U128::from(0, mx_temp);

        limbx = hi + ~U128::from(0, carry);
        tmp3.insert(i, limbx.lower);
        carry = limbx.upper;
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
            (~U128::max() - (pi_w_borrow - tmpi - ~U128::from(0, 1)), 1)
        };
        limbx = sub_res;
        ret.insert(i, limbx.lower);
        borrow = b_res & 0x1;
        i += 1;
    }

    /*ret:
9944055374826099202
9712768888634044113
300889636556430029
3653011359556993965
13577214253059692810
16572945456062011749
0..0
    */

    /*tmp3:
4899742317194411181
11922910400151252689
7736564210120511729
10892349319971706476
542573957820843489
0
0
4899742317194411181
11922910400151252689
7736564210120511729
10892349319971706476
542573957820843489
    */

    let mask: u64 = if carry >= borrow {
        carry - borrow
    } else {
        ~u64::max() - (borrow - carry - 1)
    };

    i = 0;
    let mut res: Vec<u64> = ~Vec::new::<u64>();
    while i < n {
        let value = (unpack_or_0(ret.get(i)) & not(mask)) | (unpack_or_0(tmp3.get(i)) & mask);
        res.insert(i, value);
        i += 1;
    }
    res
}

// TEMP MONTGOMERY MULT FROM NCC impl
// Repo: https://github.com/nccgroup/pairing
// Blogpost: https://research.nccgroup.com/2021/06/09/optimizing-pairing-based-cryptography-montgomery-arithmetic-in-rust/ 
fn zero_vec() -> Vec<u64> {
    let mut temp: Vec<u64> = ~Vec::new::<u64>();
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp.push(0);
    temp
}

/*
The mul_mont_n is not working yet, so this would be a temporary solution but using montgomery mult. 
*/
//pub fn temp_mul_mont_n(a: Vec<u64>, b: Vec<u64>) -> Vec<u64> {
pub fn temp_mul_mont_n(a_vec: vec384, b_vec: vec384) -> vec384 {
    let mut a: Vec<u64> = ~Vec::new::<u64>();
    a.push(a_vec.ls[0]);
    a.push(a_vec.ls[1]);
    a.push(a_vec.ls[2]);
    a.push(a_vec.ls[3]);
    a.push(a_vec.ls[4]);
    a.push(a_vec.ls[5]);

    let mut b: Vec<u64> = ~Vec::new::<u64>();
    b.push(b_vec.ls[0]);
    b.push(b_vec.ls[1]);
    b.push(b_vec.ls[2]);
    b.push(b_vec.ls[3]);
    b.push(b_vec.ls[4]);
    b.push(b_vec.ls[5]);
    

    // To mont form
    let a_mont = fe_to_mont(a);
    let b_mont = fe_to_mont(b);
    // Mult
    let res = temp_fe_mont_mul(a_mont, b_mont);
    // Transform back
    let res = fe_to_norm(res);
    let res_vec = vec384{
        ls: [unpack_or_0(res.get(0)),unpack_or_0(res.get(1)),unpack_or_0(res.get(2)),unpack_or_0(res.get(3)),unpack_or_0(res.get(4)),unpack_or_0(res.get(5))]
    };

    res_vec
}

// Effectively a_mont = (a_norm * R) mod N
pub fn fe_to_mont(a: Vec<u64>) -> Vec<u64> {
    let mut BLS12_381_RR: Vec<u64> = ~Vec::new::<u64>();
    BLS12_381_RR.push(0xf4df1f341c341746);
    BLS12_381_RR.push(0x0a76e6a609d104f1);
    BLS12_381_RR.push(0x8de5476c4c95b6d5);
    BLS12_381_RR.push(0x67eb88a9939d83c0);
    BLS12_381_RR.push(0x9a793e85b519952d);
    BLS12_381_RR.push(0x11988fe592cae3aa);
    temp_fe_mont_mul(a, BLS12_381_RR)
}

// Effectively a_norm = (a_mont * R^{-1}) mod N
pub fn fe_to_norm(a: Vec<u64>) -> Vec<u64> {
    let mut ONE: Vec<u64> = ~Vec::new::<u64>();
    ONE.push(0x1);
    ONE.push(0);
    ONE.push(0);
    ONE.push(0);
    ONE.push(0);
    ONE.push(0);
    temp_fe_mont_mul(a, ONE)
}

// temporary mont mult impl from https://research.nccgroup.com/2021/06/09/optimizing-pairing-based-cryptography-montgomery-arithmetic-in-rust/
// with repo https://github.com/nccgroup/pairing
pub fn temp_fe_mont_mul(a: Vec<u64>, b: Vec<u64>) -> Vec<u64> {
    let mut temp: Vec<u64> = zero_vec();
    let mut i = 0;
    let mut j = 0;
    let mut carry = 0u64;
    while i < 6 {
        carry = 0;
        j = 0;
        while j < 6 {
            let aj: U128 = ~U128::from(0, unpack_or_0(a.get(j)));
            let bi: U128 = ~U128::from(0, unpack_or_0(b.get(i)));
            let temp_ij = ~U128::from(0, unpack_or_0(temp.get(i + j)));
            let carry_128 = ~U128::from(0, carry);
            let hilo: U128 = aj * bi + temp_ij + carry_128;
            temp.remove(i + j);
            temp.insert(i + j, hilo.lower);
            carry = hilo.upper;
            j += 1;
        }
        let mut t = unpack_or_0(temp.get(i + 6));
        temp.remove(i + 6);
        temp.insert(i + 6, t + carry);

        let m: u64 = multiply_wrap(unpack_or_0(temp.get(i)), P0);
        let m_128 = ~U128::from(0, m);

        carry = 0;
        j = 0;
        while j < 6 {
            let nj: U128 = ~U128::from(0, BLS12_381_P.ls[j]);
            let temp_ij = ~U128::from(0, unpack_or_0(temp.get(i + j)));
            let carry_128 = ~U128::from(0, carry);
            let hilo: U128 = m_128 * nj + temp_ij + carry_128;
            temp.remove(i + j);
            temp.insert(i + j, hilo.lower);
            carry = hilo.upper;
            j += 1;
        }
        t = unpack_or_0(temp.get(i + 6));
        temp.remove(i + 6);
        temp.insert(i + 6, t + carry);
        i += 1;
    }

    let mut dec: Vec<u64> = zero_vec();
    let mut borrow = 0u64;
    j = 0;
    while j < 6 {
        let(diff, borrow_t0) = sbb(unpack_or_0(temp.get(j + 6)), BLS12_381_P.ls[j], borrow);
        dec.insert(j, diff);
        borrow = borrow_t0;
        j += 1;
    }

    /*temp:
0..0
16494539950903960225
6909894500484332639
10854278113294925999
10279541547892741855
12499445441687670930
440910865060157199
        */

    /*dec:
3092108934826096630
4699752988967124064
3418603539730844299
3040203587478029344
7087341663216968635
17013856321122168949
0..0
        */

    let mask: u64 = if borrow == 1 {
        ~u64::max()
    } else {
        0
    };
    let mut result: Vec<u64> = zero_vec();
    j = 0;
    while j < 6 {
        let entry = (unpack_or_0(temp.get(j + 6)) & mask) | (not(mask) & unpack_or_0(dec.get(j)));
        result.insert(j, entry);
        j += 1;
    }
    result
}

// from https://github.com/zkcrypto/bls12_381
pub fn montgomery_reduction(t: [u64;
12]) -> vec384 {
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

    subtract_p(vec384 {
        ls: [r6.0, r7.0, r8.0, r9.0, r10.0, r11_12.0]
    },
    BLS12_381_P)
}

// TEMP NAIVE MULT IMPL
// Naive multiplication implementation following zkcrypto.
// Can be used as stand-in until we figure our how to make mul_mont_n work or the NCC mult with conversions before and after is feasible
pub fn mul_temp(a: Vec<u64>, b: Vec<u64>, p: Vec<u64>, n: u64) -> vec384 {
    let a0 = unpack_or_0(a.get(0));
    let a1 = unpack_or_0(a.get(1));
    let a2 = unpack_or_0(a.get(2));
    let a3 = unpack_or_0(a.get(3));
    let a4 = unpack_or_0(a.get(4));
    let a5 = unpack_or_0(a.get(5));

    let b0 = unpack_or_0(b.get(0));
    let b1 = unpack_or_0(b.get(1));
    let b2 = unpack_or_0(b.get(2));
    let b3 = unpack_or_0(b.get(3));
    let b4 = unpack_or_0(b.get(4));
    let b5 = unpack_or_0(b.get(5));

    let(t0, carry) = mac(0, a0, b0, 0);
    let(t1, carry) = mac(0, a0, b1, carry);
    let(t2, carry) = mac(0, a0, b2, carry);
    let(t3, carry) = mac(0, a0, b3, carry);
    let(t4, carry) = mac(0, a0, b4, carry);
    let(t5, t6) = mac(0, a0, b5, carry);

    let(t1, carry) = mac(t1, a1, b0, 0);
    let(t2, carry) = mac(t2, a1, b1, carry);
    let(t3, carry) = mac(t3, a1, b2, carry);
    let(t4, carry) = mac(t4, a1, b3, carry);
    let(t5, carry) = mac(t5, a1, b4, carry);
    let(t6, t7) = mac(t6, a1, b5, carry);

    let(t2, carry) = mac(t2, a2, b0, 0);
    let(t3, carry) = mac(t3, a2, b1, carry);
    let(t4, carry) = mac(t4, a2, b2, carry);
    let(t5, carry) = mac(t5, a2, b3, carry);
    let(t6, carry) = mac(t6, a2, b4, carry);
    let(t7, t8) = mac(t7, a2, b5, carry);

    let(t3, carry) = mac(t3, a3, b0, 0);
    let(t4, carry) = mac(t4, a3, b1, carry);
    let(t5, carry) = mac(t5, a3, b2, carry);
    let(t6, carry) = mac(t6, a3, b3, carry);
    let(t7, carry) = mac(t7, a3, b4, carry);
    let(t8, t9) = mac(t8, a3, b5, carry);

    let(t4, carry) = mac(t4, a4, b0, 0);
    let(t5, carry) = mac(t5, a4, b1, carry);
    let(t6, carry) = mac(t6, a4, b2, carry);
    let(t7, carry) = mac(t7, a4, b3, carry);
    let(t8, carry) = mac(t8, a4, b4, carry);
    let(t9, t10) = mac(t9, a4, b5, carry);

    let(t5, carry) = mac(t5, a5, b0, 0);
    let(t6, carry) = mac(t6, a5, b1, carry);
    let(t7, carry) = mac(t7, a5, b2, carry);
    let(t8, carry) = mac(t8, a5, b3, carry);
    let(t9, carry) = mac(t9, a5, b4, carry);
    let(t10, t11) = mac(t10, a5, b5, carry);

    let res: [u64;
    12] = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11];
    montgomery_reduction(res)
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

pub fn sqr_mont_384(a: vec384, p: vec384, n0: u64) -> vec384 {
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
        let mx: U128 = ~U128::from(0, mx_temp);
        let mut limbx = mx * ~U128::from(0, unpack_or_0(p.get(0))) + ~U128::from(0, unpack_or_0(b.get(0)));
        let mut hi: U128 = ~U128::from(0, limbx.upper);
        i = 1;
        while i < n {
            let pi: U128 = ~U128::from(0, unpack_or_0(p.get(i)));
            let bi: U128 = ~U128::from(0, unpack_or_0(b.get(i)));
            limbx = (mx * pi + hi) + bi;
            tmp.insert(i - 1, limbx.lower);
            hi = ~U128::from(0, limbx.upper);
            i += 1;
        }
        tmp.insert(i - 1, hi.lower);
        b = tmp;
        j += 1;
    }

    let mut tmp2: Vec<u64> = ~Vec::new::<u64>();
    let mut carry = 0;
    i = 0;
    while i < n {
        let ani: U128 = ~U128::from(0, unpack_or_0(a.get(n + i)));
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
            (~U128::max() - (pi_w_borrow - tmp2i - ~U128::from(0, 1)), 1)
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
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let borrow_128: U128 = ~U128::from(0, borrow);

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
    let a_128: U128 =  ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let carry_128: U128 =  ~U128::from(0, carry);

    let sum: u64 = (a_128 + b_128 + carry_128).lower;
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
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    let c_128: U128 = ~U128::from(0, c);
    let carry_128: U128 = ~U128::from(0, carry);

    let res: U128 = a_128 + (b_128 * c_128) + carry_128;
    (res.lower, res.upper)
}

//returns a*b mod(2^64)
pub fn multiply_wrap(a: u64, b: u64) -> u64 {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);

    (a_128 * b_128).lower
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

// TODO
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
