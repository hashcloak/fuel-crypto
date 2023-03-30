library field64;

use utils::{integer_utils::adc, integer_utils::sbb, integer_utils::mac}; 
use core::ops::{Add, Subtract, Multiply};

// Little endian
// ls[0] + ls[1] * 2^64 + ls[2] * 2^128 + ls[3] * 2^192
pub struct Fe { 
  ls: [u64; 4] 
}

// 115792089210356248762697446949407573530086143415290314195533631308867097853951
// 18446744073709551615 + 4294967295 * 2ˆ64 + 18446744069414584321 * 2ˆ192
const modulus: [u64; 4] = [18446744073709551615, 4294967295, 0, 18446744069414584321];

// R^2 = 2^512 mod p = 134799733323198995502561713907086292154532538166959272814710328655875
const R_2: [u64; 4] = [3, 18446744056529682431, 18446744073709551614, 21474836477];

fn sub_inner(l: [u64; 5], r: [u64; 5]) -> Fe {
    let (w0, borrow0) = sbb(l[0], r[0], 0);
    let (w1, borrow1) = sbb(l[1], r[1], borrow0);
    let (w2, borrow2) = sbb(l[2], r[2], borrow1);
    let (w3, borrow3) = sbb(l[3], r[3], borrow2);
    let (_, borrow4) = sbb(l[4], r[4], borrow3);

    // If underflow occurred on the final limb, borrow = 0xfff...fff, otherwise
    // borrow = 0x000...000. Thus, we use it as a mask to conditionally add the
    // modulus.
    let (w0, carry0) = adc(w0, modulus[0] & borrow4, 0);
    let (w1, carry1) = adc(w1, modulus[1] & borrow4, carry0);
    let (w2, carry2) = adc(w2, modulus[2] & borrow4, carry1);
    let (w3, _) = adc(w3, modulus[3] & borrow4, carry2);
  
    Fe { ls: [w0, w1, w2, w3] }
}

pub fn fe_add(a: Fe, b: Fe) -> Fe {
    let (w0, carry0) = adc(a.ls[0], b.ls[0], 0);
    let (w1, carry1) = adc(a.ls[1], b.ls[1], carry0);
    let (w2, carry2) = adc(a.ls[2], b.ls[2], carry1);
    let (w3, w4) = adc(a.ls[3], b.ls[3], carry2);
    
    // Attempt to subtract the modulus, to ensure the result is in the field.
    sub_inner(
        [w0, w1, w2, w3, w4],
        [modulus[0], modulus[1], modulus[2], modulus[3], 0],
    )
}

// Returns `a - b mod p`.
pub fn fe_sub(a: Fe, b: Fe) -> Fe {
    sub_inner([a.ls[0], a.ls[1], a.ls[2], a.ls[3], 0], [b.ls[0], b.ls[1], b.ls[2], b.ls[3], 0])
}

fn montgomery_reduce(r: [u64; 8]) -> Fe {

    let r0 = r[0];
    let r1 = r[1];
    let r2 = r[2];
    let r3 = r[3];
    let r4 = r[4];
    let r5 = r[5];
    let r6 = r[6];
    let r7 = r[7];

    let (r1, carry) = mac(r1, r0, modulus[1], r0);
    let (r2, carry) = adc(r2, 0, carry);
    let (r3, carry) = mac(r3, r0, modulus[3], carry);
    let (r4, carry2) = adc(r4, 0, carry);

    let (r2, carry) = mac(r2, r1, modulus[1], r1);
    let (r3, carry) = adc(r3, 0, carry);
    let (r4, carry) = mac(r4, r1, modulus[3], carry);
    let (r5, carry2) = adc(r5, carry2, carry);

    let (r3, carry) = mac(r3, r2, modulus[1], r2);
    let (r4, carry) = adc(r4, 0, carry);
    let (r5, carry) = mac(r5, r2, modulus[3], carry);
    let (r6, carry2) = adc(r6, carry2, carry);

    let (r4, carry) = mac(r4, r3, modulus[1], r3);
    let (r5, carry) = adc(r5, 0, carry);
    let (r6, carry) = mac(r6, r3, modulus[3], carry);
    let (r7, r8) = adc(r7, carry2, carry);

    // Result may be within MODULUS of the correct value
    sub_inner(
        [r4, r5, r6, r7, r8],
        [modulus[0], modulus[1], modulus[2], modulus[3], 0],
    )
}

/// Returns `a * b mod p`.
pub fn fe_mul(a: Fe, b: Fe) -> Fe {
    let (w0, carry) = mac(0, a.ls[0], b.ls[0], 0);
    let (w1, carry) = mac(0, a.ls[0], b.ls[1], carry);
    let (w2, carry) = mac(0, a.ls[0], b.ls[2], carry);
    let (w3, w4) = mac(0, a.ls[0], b.ls[3], carry);

    let (w1, carry) = mac(w1, a.ls[1], b.ls[0], 0);
    let (w2, carry) = mac(w2, a.ls[1], b.ls[1], carry);
    let (w3, carry) = mac(w3, a.ls[1], b.ls[2], carry);
    let (w4, w5) = mac(w4, a.ls[1], b.ls[3], carry);

    let (w2, carry) = mac(w2, a.ls[2], b.ls[0], 0);
    let (w3, carry) = mac(w3, a.ls[2], b.ls[1], carry);
    let (w4, carry) = mac(w4, a.ls[2], b.ls[2], carry);
    let (w5, w6) = mac(w5, a.ls[2], b.ls[3], carry);

    let (w3, carry) = mac(w3, a.ls[3], b.ls[0], 0);
    let (w4, carry) = mac(w4, a.ls[3], b.ls[1], carry);
    let (w5, carry) = mac(w5, a.ls[3], b.ls[2], carry);
    let (w6, w7) = mac(w6, a.ls[3], b.ls[3], carry);

    montgomery_reduce([w0, w1, w2, w3, w4, w5, w6, w7])
}

// Translate a field element out of the Montgomery domain.
pub fn fe_from_montgomery(w: Fe) -> Fe {
    montgomery_reduce([w.ls[0], w.ls[1], w.ls[2], w.ls[3], 0, 0, 0, 0])
}

// Translate a field element into the Montgomery domain.
pub fn fe_to_montgomery(w: Fe) -> Fe {
    fe_mul(w, Fe{ls: R_2})
}

// Returns `-w mod p`
pub fn fe_neg(w: Fe) -> Fe {
    fe_sub(Fe{ls: [0,0,0,0]}, w)
}

pub fn fe_square(w: Fe) -> Fe {
    fe_mul(w, w)
}

// p = 2^256 - 2^224 + 2^192 + 2^96 - 1 
// Returns b such that b * a ≡ 1 mod p
// from fermat's theorem, b ≡ a^(p-2) mod p
// pub fn fe_inverse(w: Fe) -> Fe {    

//     let t_2 = fe_square(w); // 2
//     let t_3 = fe_mul(t_2, w) // 3
//     let t_6 = fe_square(t_3); // 6
//     let t_7 = fe_mul(t_6, w); // 7
//     let t_56 = t_7;
//     let mut i = 0;
//     while i < 3 {
//         t_57 = fe_square(t_56); // 7*8 = 56
//         i = i+1;
//     }

//     let t_63 = fe_mul(t_57, t_7); // 63 = 2^6 - 1

//     let t_12_6 = t_63;
//     i = 0;
//     while i < 6 {
//         t_12_6 = fe_square(t_12_6); // (2^6 - 1) * 2^6 = 2^12 - 2^6
//         i = i + 1;
//     }

//     let t_18_13_6 = fe_mul(t_12_6, t_63); // 2^18 - 2^13 + 2^6

//     let t_21_16_9 = t_18_13_6;
//     i = 0;
//     while i < 3 {
//         t_21_16_9 = fe_square(t_); // 2^21 - 2^16 + 2^9
//         i = i+1;
//     }
//     let t_24_18_1 = fe_mul(t_21_16_9, t_7); // 2^24 - 2^18 - 1

//     let t_27_21_3 = t_24_18_1;
//     i = 0;
//     while i < 3 {
//         t_27_21_3 = fe_square(t_27_21_3); // 2^27 - 2^21 - 2^3
//     }

//     let t_27_21_0 = fe_mul(t_27_21_3, t7); //2^27 - 2^21 - 1
// }

impl Add for Fe {
    fn add(self, other: Self) -> Self {
        fe_add(self, other)
    }
}

impl Subtract for Fe {
    fn subtract(self, other: Self) -> Self {
        fe_sub(self, other)
    }
}

impl Multiply for Fe {
    fn multiply(self, other: Self) -> Self {
        fe_mul(self, other)
    }
}