library field_element;

use std::u128::*;
// Radix 51 representation of an integer:
// l0 + l1*2^51 + l2*2^102 + l3*2^153 + l4*2^204
pub struct Element {
    l0: u64,
    l1: u64,
    l2: u64,
    l3: u64,
    l4: u64,
}

// = (1 << 51) - 1
// But using the above expression gives the error "Could not evaluate initializer to a const declaration."
const mask_low_51_bits: u64 = 2251799813685247;
const zero: Element = Element{ l0: 0, l1: 0, l2: 0, l3: 0, l4: 0 };
const one: Element = Element{ l0: 1, l1: 0, l2: 0, l3: 0, l4: 0 };
/*Do 1 round of carrying
This return an element of which all li have at most 52 bits.
So the elm is at most:
    (2^52 - 1) + 
    (2^52 - 1) * 2^51 + 
    (2^52 - 1) * 2^102 + 
    (2^52 - 1) * 2^153 +
    (2^52 - 1) * 2^204
    */
pub fn carry_propagate(e: Element) -> Element {
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
    let new_l0 = (e.l0 & mask_low_51_bits) + c4 * 19;
    Element{ l0: new_l0, 
    l1: (e.l1 & mask_low_51_bits) + c0, 
    l2: (e.l2 & mask_low_51_bits) + c1, 
    l3: (e.l3 & mask_low_51_bits) + c2, 
    l4: (e.l4 & mask_low_51_bits) + c3 
    }
}

/*
returns a carry element neq 0 if the e represents a number larger than 2^255 -19
*/
fn get_carry(e: Element) -> u32 {
    let mut carry = (e.l0 + 19) >> 51;
    carry = (e.l1 + carry) >> 51;
    carry = (e.l2 + carry) >> 51;
    carry = (e.l3 + carry) >> 51;
    carry = (e.l4 + carry) >> 51;
    carry
}

/*
return reduced element mod 2^255-19
*/
pub fn mod_25519(e: Element) -> Element {
    let mut red: Element = carry_propagate(e);

    //Determine whether *red* is already completely reduced mod 2^255-19 or not
    // if v >= 2^255 - 19 => v + 19 >= 2^255
    // keep reducing as long as it's necessary
    let mut carry = get_carry(red);
    while carry != 0 {
        red = carry_propagate(red);
        carry = get_carry(red);
    }
    red
}

/*
return a + b mod 2^255 - 19
*/
pub fn add(a: Element, b: Element) -> Element {
    let temp = Element{ 
        l0: a.l0 + b.l0, 
        l1: a.l1 + b.l1, 
        l2: a.l2 + b.l2, 
        l3: a.l3 + b.l3, 
        l4: a.l4 + b.l4
    };

    mod_25519(temp)
}

//subtract fn returns a - b
pub fn subtract(a: Element, b: Element) -> Element {
    // we add 2*p to avoid any underflow and then subtract b
    let res: Element = Element {
        l0: (a.l0 + 0xFFFFFFFFFFFDA) - b.l0, 
        l1: (a.l1 + 0xFFFFFFFFFFFFE) - b.l1, 
        l2: (a.l2 + 0xFFFFFFFFFFFFE) - b.l2, 
        l3: (a.l3 + 0xFFFFFFFFFFFFE) - b.l3, 
        l4: (a.l4 +0xFFFFFFFFFFFFE ) - b.l4
    };

    carry_propagate(res)
}

//negate return negaive of an element(-a)
pub fn negate (a: Element) -> Element {
    subtract(zero,a)

}

//returns 128-bit product of a and b
pub fn multiply64 (a: u64, b: u64) -> U128 {
    let mask32 = (1<<32) - 1;
    let a0 = a & mask32;
    let a1 = a >> 32;
    let b0 = b & mask32;
    let b1 = b >> 32;

    let w0 = a0*b0;
    let t = a1*b0 + (w0 >> 32);
    let mut w1 = t & mask32;
    let w2 = t >> 32;

    w1 += a0*b1;

    U128 {
        upper: a1*b1 + w2 + (w1 >>32),
        lower: a*b
    }
}

//returns sum with carry of a and b
pub fn add64 (a: u64, b:u64, carry: u64) -> (u64, u64) {
    let sum = a + b + carry;
    // let carryOut =  ((a & b) | ((x | y) &^ sum)) >> 63; //dont know if NOT Operator is there otherwise needs to be defined manually 

    // (sum, carryOut)
    (0,0)
}

//returns res + a * b 
pub fn add_multiply64 (res: U128, a: u64, b: u64) -> U128 {
    let mut mul_res: U128 = multiply64(a, b);
    let add_res: (u64, u64) = add64(mul_res.lower, res.lower, 0);
    let add_res2: (u64, u64) = add64(mul_res.upper, res.upper, add_res.1);

    U128{
        upper: add_res.0,
        lower: add_res2.0
    } 
}

//right shift by 51
pub fn shiftRightBy51(a: U128) -> u64 {
    (a.upper <<(64-51)) | (a.lower >> 51)
}

//returns a*b
pub fn multiply (a: Element, b: Element) -> Element {

    //https://cs.opensource.google/go/go/+/master:src/crypto/internal/edwards25519/field/fe_generic.go;l=34;bpv=0?q=feMul&sq=&ss=go%2Fgo
    
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
    
	let a1_19 = a1 * 19;
	let a2_19 = a2 * 19;
	let a3_19 = a3 * 19;
	let a4_19 = a4 * 19;

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

    // r4 = a0×b4 + a1×b3 + a2×b2 + a3×b1 + a4×b0
	let mut r4: U128 = multiply64(a0, b4);
	r4 = add_multiply64(r4, a1, b3);
	r4 = add_multiply64(r4, a2, b2);
	r4 = add_multiply64(r4, a3, b1);
	r4 = add_multiply64(r4, a4, b0);

    let c0 = shiftRightBy51(r0);
	let c1 = shiftRightBy51(r1);
	let c2 = shiftRightBy51(r2);
	let c3 = shiftRightBy51(r3);
	let c4 = shiftRightBy51(r4);

	let rr0 = r0.lower & mask_low_51_bits + c4*19;
	let rr1 = r1.lower & mask_low_51_bits + c0;
	let rr2 = r2.lower & mask_low_51_bits + c1;
	let rr3 = r3.lower & mask_low_51_bits + c2;
	let rr4 = r4.lower & mask_low_51_bits + c3;

    let res: Element = Element {
        l0: rr0,
        l1: rr1,
        l2: rr2,
        l3: rr3,
        l4: rr4
    };

    carry_propagate(res)

}

//returns square of an Element
// pub fn square(a: Element) -> Element {
//     multiply(a,a)
// }