library field64;

use utils::{integer_utils::adc, integer_utils::sbb, integer_utils::mac}; 

// Little endian
// ls[0] + ls[1] * 2^64 + ls[2] * 2^128 + ls[3] * 2^192
pub struct Fe { 
  ls: [u64; 4] 
}

// 115792089210356248762697446949407573530086143415290314195533631308867097853951
// 18446744073709551615 + 4294967295 * 2ˆ64 + 18446744069414584321 * 2ˆ192
const modulus: [u64; 4] = [18446744073709551615, 4294967295, 0, 18446744069414584321];

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
    //r0=r1=r2=r3=1 and r4=r5=r6=r7=0
    let r0 = r[0];
    let r1 = r[1];
    let r2 = r[2];
    let r3 = r[3];
    let r4 = r[4];
    let r5 = r[5];
    let r6 = r[6];
    let r7 = r[7];

    let (r1, carry) = mac(r1, r0, modulus[1], r0);
    // log(r1);//2
    // log(carry);//0

    let (r2, carry) = adc(r2, 0, carry);
    // log(r2);//1
    // log(carry);//0
    let (r3, carry) = mac(r3, r0, modulus[3], carry);
    // log(modulus[3]);
    // log(r0);
    // log(r3);//0
    // log(carry);//1
    let (r4, carry2) = adc(r4, 0, carry);
    // log(r4);//1
    // log(carry2);//0
    let (r2, carry) = mac(r2, r1, modulus[1], r1);
    // log(r2);//3
    // log(carry);//0
    let (r3, carry) = adc(r3, 0, carry);
    // log(r3);//0
    // log(carry);//0
    let (r4, carry) = mac(r4, r1, modulus[3], carry);
    // log(r4);//18446744073709551615
    // log(carry);//1
    let (r5, carry2) = adc(r5, carry2, carry);
    // log(r5);//1
    // log(carry2);//0

    let (r3, carry) = mac(r3, r2, modulus[1], r2);
    // log(r3);//3
    // log(carry);//0
    let (r4, carry) = adc(r4, 0, carry);
    // log(r4);//18446744073709551615
    // log(carry);//0
    let (r5, carry) = mac(r5, r2, modulus[3], carry);
    // log(r5);//18446744073709551614
    // log(carry);//2
    let (r6, carry2) = adc(r6, carry2, carry);
    // log(r6);//2
    // log(carry2);//0
    let (r4, carry) = mac(r4, r3, modulus[1], r3);
    // log(r4);//2
    // log(carry);//1
    let (r5, carry) = adc(r5, 0, carry);
    // log(r5);//18446744073709551615
    // log(carry);//0
    let (r6, carry) = mac(r6, r3, modulus[3], carry);
    // log(r6);//18446744073709551615
    // log(carry);//2
    let (r7, r8) = adc(r7, carry2, carry);
    // log(r7);//2
    // log(r8);//0

    // Result may be within MODULUS of the correct value
    sub_inner(
        [r4, r5, r6, r7, r8],
        [modulus[0], modulus[1], modulus[2], modulus[3], 0],
    )
}

/// Returns `a * b mod p`.
pub fn fe_mul(a: Fe, b: Fe) -> Fe {
    let (w0, carry) = mac(0, a.ls[0], b.ls[0], 0);
    // log(w0);
    // log(carry);

    let (w1, carry) = mac(0, a.ls[0], b.ls[1], carry);
    // log(w1);
    // log(carry);
    let (w2, carry) = mac(0, a.ls[0], b.ls[2], carry);
    // log(w2);
    // log(carry);
    let (w3, w4) = mac(0, a.ls[0], b.ls[3], carry);
    // log(w3);
    // log(carry);

    let (w1, carry) = mac(w1, a.ls[1], b.ls[0], 0);
    // log(w1);
    // log(carry);
    let (w2, carry) = mac(w2, a.ls[1], b.ls[1], carry);
    // log(w2);
    // log(carry);
    let (w3, carry) = mac(w3, a.ls[1], b.ls[2], carry);
    // log(w3);
    // log(carry);
    let (w4, w5) = mac(w4, a.ls[1], b.ls[3], carry);
    // log(w4);
    // log(carry);


    let (w2, carry) = mac(w2, a.ls[2], b.ls[0], 0);
    // log(w2);
    // log(carry);
    let (w3, carry) = mac(w3, a.ls[2], b.ls[1], carry);
    // log(w3);
    // log(carry);
    let (w4, carry) = mac(w4, a.ls[2], b.ls[2], carry);
    // log(w4);
    // log(carry);
    let (w5, w6) = mac(w5, a.ls[2], b.ls[3], carry);
    // log(w5);
    // log(carry); 


    let (w3, carry) = mac(w3, a.ls[3], b.ls[0], 0);
    // log(w3);
    // log(carry);
    let (w4, carry) = mac(w4, a.ls[3], b.ls[1], carry);
    // log(w4);
    // log(carry);
    let (w5, carry) = mac(w5, a.ls[3], b.ls[2], carry);
    // log(w5);
    // log(carry);
    let (w6, w7) = mac(w6, a.ls[3], b.ls[3], carry);
    // log(w6);
    // log(carry);

    montgomery_reduce([w0, w1, w2, w3, w4, w5, w6, w7])
}