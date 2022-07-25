library fe25519;

//todo remove and only use definitions from this libr
dep field_element;
use field_element::*;

use std::u128::*;

// #define fe25519_neg          DONE
// #define fe25519_getparity
// #define fe25519_add          DONE
// #define fe25519_sub          DONE
// #define fe25519_mul          DONE
// #define fe25519_square       DONE
// #define fe25519_pow 
// #define fe25519_sqrt_vartime
// #define fe25519_invert 

// Some things are now commented out because of shadowing in field_element.sw

// Radix 51 representation of an integer:
// l0 + l1*2^51 + l2*2^102 + l3*2^153 + l4*2^204
// pub struct Element {
//     l0: u64,
//     l1: u64,
//     l2: u64,
//     l3: u64,
//     l4: u64,
// }
// = (1 << 51) - 1
// But using the above expression gives the error "Could not evaluate initializer to a const declaration."
const MASK_LOW_51_BITS: u64 = 2251799813685247;

// pub const ZERO: Element = Element {
//     l0: 0, l1: 0, l2: 0, l3: 0, l4: 0
// };

// from NaCl impl https://cr.yp.to/ecdh.html#use
fn times19(x: u64) -> u64 {
    (x << 4) + (x << 1) + x
}

//returns 128-bit product of a and b
// pub fn multiply64(a: u64, b: u64) -> U128 {
//     let a_128: U128 = ~U128::from(0, a);
//     let b_128: U128 = ~U128::from(0, b);
//     a_128 * b_128
// }

//returns res + a * b
// pub fn add_multiply64(res: U128, a: u64, b: u64) -> U128 {
//     let mul_res: U128 = multiply64(a, b);
//     let add_res: (u64, u64) = add64(mul_res.lower, res.lower, 0);
//     let add_res2: (u64, u64) = add64(mul_res.upper, res.upper, add_res.1);

//     ~U128::from(add_res2.0, add_res.0)
// }

//returns sum with carry of a and b
// pub fn add64(a: u64, b: u64, carry: u64) -> (u64, u64) {
//     let a_128: U128 =  ~U128::from(0, a);
//     let b_128: U128 = ~U128::from(0, b);
//     let carry_128: U128 =  ~U128::from(0, carry);

//     let sum: u64 = (a_128 + b_128 + carry_128).lower;
//     let notSum = ~u64::max() - sum;
//     let carryOut = ((a & b) | ((a | b) & notSum)) >> 63;

//     (sum, carryOut)
// }

//right shift by 51
// pub fn shift_right_by51(a: U128) -> u64 {
//     (a.upper <<(64 - 51)) | (a.lower >> 51)
// }

// reduce_mul and reduce_add_sub are 2 separate functions in NaCl but have the exact same code
// returns e mod p. Assumes the input at most needs 1 round of carrying
pub fn reduce_add_sub_mul(e: Element) -> Element {
    /*Do 1 round of carrying
    This returns an element of which all li have at most 52 bits.
    So the elm is at most:
    (2^52 - 1) + 
    (2^52 - 1) * 2^51 + 
    (2^52 - 1) * 2^102 + 
    (2^52 - 1) * 2^153 +
    (2^52 - 1) * 2^204

    In the Go impl, this functions is called carry_propagate
    */

    // all ci have at most 13 bits
    let c0 = e.l0 >> 51;
    let c1 = e.l1 >> 51;
    let c2 = e.l2 >> 51;
    let c3 = e.l3 >> 51;
    // c4 represents what carries over to the 2^255 element
    // since we're working 2^255 - 19, this will carry over to the first element,
    // multiplied by 19
    let c4 = e.l4 >> 51;

    // c4 is at most 64 - 51 = 13 bits, so c4*19 is at most 18 bits, and
    // the final l0 will be at most 52 bits. Similarly for the rest.

    // c4 * 19 is at most 13 + 5 = 18 bits => l0 is at most 52 bits
    let new_l0 = (e.l0 & MASK_LOW_51_BITS) + times19(c4);
    Element {
        l0: new_l0,
        l1: (e.l1 & MASK_LOW_51_BITS) + c0,
        l2: (e.l2 & MASK_LOW_51_BITS) + c1,
        l3: (e.l3 & MASK_LOW_51_BITS) + c2,
        l4: (e.l4 & MASK_LOW_51_BITS) + c3,
    }
}

// returns negative of an element(-a) mod 2^255 - 19
pub fn fe25519_neg(a: Element) -> Element {
    fe25519_sub(ZERO, a)
}

// returns a + b mod 2^255 - 19
pub fn fe25519_add(a: Element, b: Element) -> Element {
    let temp = Element {
        l0: a.l0 + b.l0,
        l1: a.l1 + b.l1,
        l2: a.l2 + b.l2,
        l3: a.l3 + b.l3,
        l4: a.l4 + b.l4,
    };

    reduce_add_sub_mul(temp)
}

// returns a - b mod 2^255 - 19
pub fn fe25519_sub(a: Element, b: Element) -> Element {
    // we add 2*p to avoid any underflow and then subtract b
    let res: Element = Element {
        l0: (a.l0 + 0xFFFFFFFFFFFDA) - b.l0,
        l1: (a.l1 + 0xFFFFFFFFFFFFE) - b.l1,
        l2: (a.l2 + 0xFFFFFFFFFFFFE) - b.l2,
        l3: (a.l3 + 0xFFFFFFFFFFFFE) - b.l3,
        l4: (a.l4 + 0xFFFFFFFFFFFFE) - b.l4,
    };

    reduce_add_sub_mul(res) //TODO test
}

// returns a*b mod p
pub fn fe25519_mul(a: Element, b: Element) -> Element {
    //ref impl https://cs.opensource.google/go/go/+/master:src/crypto/internal/edwards25519/field/fe_generic.go;l=34;bpv=0?q=feMul&sq=&ss=go%2Fgo

    let a0 = a.l0;
    let a1 = a.l1;
    let a2 = a.l2;
    let a3 = a.l3;
    let a4 = a.l4;

    let b0 = b.l0;
    let b1 = b.l1;
    let b2 = b.l2;
    let b3 = b.l3;
    let b4 = b.l4;

    let a1_19 = times19(a1);
    let a2_19 = times19(a2);
    let a3_19 = times19(a3);
    let a4_19 = times19(a4);

    // r0 = a0×b0 + 19×(a1×b4 + a2×b3 + a3×b2 + a4×b1)
    let mut r0: U128 = multiply64(a0, b0);
    r0 = add_multiply64(r0, a1_19, b4);
    r0 = add_multiply64(r0, a2_19, b3);
    r0 = add_multiply64(r0, a3_19, b2);
    r0 = add_multiply64(r0, a4_19, b1);

    // r1 = a0×b1 + a1×b0 + 19×(a2×b4 + a3×b3 + a4×b2)
    let mut r1: U128 = multiply64(a0, b1);
    r1 = add_multiply64(r1, a1, b0);
    r1 = add_multiply64(r1, a2_19, b4);
    r1 = add_multiply64(r1, a3_19, b3);
    r1 = add_multiply64(r1, a4_19, b2);

    // r2 = a0×b2 + a1×b1 + a2×b0 + 19×(a3×b4 + a4×b3)
    let mut r2: U128 = multiply64(a0, b2);
    r2 = add_multiply64(r2, a1, b1);
    r2 = add_multiply64(r2, a2, b0);
    r2 = add_multiply64(r2, a3_19, b4);
    r2 = add_multiply64(r2, a4_19, b3);

    // r3 = a0×b3 + a1×b2 + a2×b1 + a3×b0 + 19×a4×b4
    let mut r3: U128 = multiply64(a0, b3);
    r3 = add_multiply64(r3, a1, b2);
    r3 = add_multiply64(r3, a2, b1);
    r3 = add_multiply64(r3, a3, b0);
    r3 = add_multiply64(r3, a4_19, b4);

    //r4 = a0×b4 + a1×b3 + a2×b2 + a3×b1 + a4×b0
    let mut r4: U128 = multiply64(a0, b4);
    r4 = add_multiply64(r4, a1, b3);
    r4 = add_multiply64(r4, a2, b2);
    r4 = add_multiply64(r4, a3, b1);
    r4 = add_multiply64(r4, a4, b0);

    let c0 = shift_right_by51(r0);
	let c1 = shift_right_by51(r1);
	let c2 = shift_right_by51(r2);
	let c3 = shift_right_by51(r3);
	let c4 = shift_right_by51(r4);

	let rr0 = (r0.lower & MASK_LOW_51_BITS) + times19(c4);
	let rr1 = (r1.lower & MASK_LOW_51_BITS) + c0;
	let rr2 = (r2.lower & MASK_LOW_51_BITS) + c1;
	let rr3 = (r3.lower & MASK_LOW_51_BITS) + c2;
	let rr4 = (r4.lower & MASK_LOW_51_BITS) + c3;

    let res: Element = Element {
        l0: rr0,
        l1: rr1,
        l2: rr2,
        l3: rr3,
        l4: rr4
    };

    reduce_add_sub_mul(res)
}

// returns a^2 mod p
pub fn fe25519_square(a: Element) -> Element {
    fe25519_mul(a, a)
}

// fe25519_pow TODO

// fe25519_sqrt_vartime TODO
// for when p eq 5 mod 8
// alg ref https://cacr.uwaterloo.ca/hac/about/chap3.pdf#page=17

/*
// TODO Testing not done
// return a^-1 mod p
pub fn fe25519_invert(a: Element) -> Element {
    //a^(-1) mod p = a^(p-2) mod p by  Fermat's theorem, Hence we  calculate a^(p-2) mod p
    let mut i = 0;
    let z2 = square(a);                 //2
    let mut t = square(z2);             //4
    t = square(t);                      //8

// When running these few steps of inverse (it should run the complete function) it gives error: 
// thread 'main' panicked at 'called `Result::unwrap()` on an `Err` value: Immediate18TooLarge { val: 262221, span: Span { src (ptr): 0x60000f0ad670, path: None, start: 0, end: 0, as_str(): "" } }', sway-core/src/asm_lang/virtual_ops.rs:866:18


    // let z9 = multiply(t,a);             //9
    // let z11 = multiply(z9, z2);         //11
    // t = square(z11);                    //22

    // let z2_5_0 = multiply(t, z9);       //31
    // t = square(z2_5_0);                 // 62 = 2^6 - 2^1
    // while i < 4 {
    //     t = square(t);                  // 2^10 - 2^5
    //     i+=1;                            
    // }

    // let z2_10_0 = multiply(t, z2_5_0);  // 2^10 - 2^0

    // t = square(z2_10_0);                //2^11 - 2^1
    // i = 0;
    // while i < 9 {
    //     t = square(t);                  //2^20 - 2^10
    //     i += 1;
    // }

    // let z2_20_0 = multiply(t, z2_10_0); //2^20 - 2^0

    // t = square(z2_20_0);                //2^21 - 2^1
    // i = 0;
    // while i < 19 {
    //     t = square(t);                  //2^40 - 2^20
    //     i += 1;
    // }

    // t = multiply(t, z2_20_0);           //2^40 - 2^0

    // t = square(t); // 2^41 - 2^1
    
    // i = 0;
    // while i < 10 {
    //     t = square(t);                  //2^50 - 2^10
    // }

    // let z2_50_0 = multiply(t, z2_10_0); //2^50 - 2^0

    // t = square(z2_50_0);                //2^51 - 2^1

    // i = 0;
    // while i < 49 {
    //     t = square(t);                  //2^100 - 2^50
    //     i += 1;
    // }
    
    // let z2_100_0 = multiply(t, z2_50_0);//2^100 - 2^0

    // t = square(z2_100_0);               //2^101 - 2^1

    // i = 0;
    // while i < 99 {
    //     t = square(t);                  //2^200 - 2^100
    //     i += 1;
    // }

    // t = multiply(t, z2_100_0);          //2^200 - 2^0

    // t = square(t);                      //2^201 - 2^1

    // i = 0;
    // while i < 49 {
    //     t = square(t);                  //2^250 - 2^50
    //     i += 1;
    // }

    // t = multiply(t, z2_50_0);           //2^250 - 2^0

    // i = 0;
    // while i < 5 {
    //     t = square(t);                  //2^255 - 2^5
    //     i += 1;
    // }

    // t = multiply(t, z11);               //2^255 - 21 = p - 2

    return t;
}
*/