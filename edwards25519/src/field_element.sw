library field_element;

use std::u128::*;
//This wildcard import is needed because of importing ConstantTimeEq for u64 (since it's a trait for a primitive type)
use utils::choice::*; 
use utils::integer_utils::adc; 
use core::ops::{Eq, Add, Subtract, Multiply};

/*
Uses reference implementations
- NaCl impl 
https://cr.yp.to/ecdh.html#use
- Go impl 
https://cs.opensource.google/go/go/+/master:src/crypto/internal/edwards25519/field/fe.go
*/

// A field element of GF(2^255 - 19)
// Radix 51 representation of an integer:
// l0 + l1*2^51 + l2*2^102 + l3*2^153 + l4*2^204
pub struct Element {
    l0: u64,
    l1: u64,
    l2: u64,
    l3: u64,
    l4: u64,
}

// For `MASK_LOW_51_BITS` want to use the expression `(1 << 51) - 1`
// But using the above expression gives the error "Could not evaluate initializer to a const declaration."
// Therefore, we use the literal value for now
const MASK_LOW_51_BITS: u64 = 2251799813685247;

// zero element in GF(2^255-19)
pub const ZERO: Element = Element {
    l0: 0, l1: 0, l2: 0, l3: 0, l4: 0
};

// returns x*19 using a bitshift implementation
// from NaCl impl https://cr.yp.to/ecdh.html#use
fn times19(x: u64) -> u64 {
    (x << 4) + (x << 1) + x
}

impl Element {
    /* 
        returns an element of which all li have at most 52 bits

        Does 1 round of carrying. The result is at most
        (2^52 - 1) + 
        (2^52 - 1) * 2^51 + 
        (2^52 - 1) * 2^102 + 
        (2^52 - 1) * 2^153 +
        (2^52 - 1) * 2^204
    */
    fn carry_propagate(self) -> Element {
        // all ci have at most 13 bits; calculate the carry for each limb
        let c0 = self.l0 >> 51;
        let c1 = self.l1 >> 51;
        let c2 = self.l2 >> 51;
        let c3 = self.l3 >> 51;
        // c4 represents what carries over to the 2^255 element
        // since we're working 2^255 - 19, this will carry over to the first element,
        // multiplied by 19
        let c4 = self.l4 >> 51;

        // c4 is at most 64 - 51 = 13 bits, so c4*19 is at most 18 bits, and
        // the final l0 will be at most 52 bits. Similarly for the rest.

        // c4 * 19 is at most 13 + 5 = 18 bits => l0 is at most 52 bits
        let new_l0 = (self.l0 & MASK_LOW_51_BITS) + times19(c4);
        Element {
            l0: new_l0,
            l1: (self.l1 & MASK_LOW_51_BITS) + c0,
            l2: (self.l2 & MASK_LOW_51_BITS) + c1,
            l3: (self.l3 & MASK_LOW_51_BITS) + c2,
            l4: (self.l4 & MASK_LOW_51_BITS) + c3,
        }
    }

    //returns a carry element neq 0 if `self` represents a number larger than 2^255 -19
    fn get_carry(self) -> u32 {
        let mut carry = times19(self.l0) >> 51;
        carry = (self.l1 + carry) >> 51;
        carry = (self.l2 + carry) >> 51;
        carry = (self.l3 + carry) >> 51;
        carry = (self.l4 + carry) >> 51;
        carry
    }

    //returns self with all limbs multiplied by scalar x, reduced p
    fn scalar_mult(self, x: u32) -> Element {
        let scalar_u128: U128 = ~U128::from(0, x);

        // e is radix 51, so all limbs have max 51 bits. The scalar has max 32 bits.
        // Their multiplication has max 84 bits and is stored as (upper, lower) in U128
        let l0_temp: U128 = ~U128::from(0, self.l0) * scalar_u128;
        let l1_temp: U128 = ~U128::from(0, self.l1) * scalar_u128;
        let l2_temp: U128 = ~U128::from(0, self.l2) * scalar_u128;
        let l3_temp: U128 = ~U128::from(0, self.l3) * scalar_u128;
        let l4_temp: U128 = ~U128::from(0, self.l4) * scalar_u128;

        let (coeff0, carry0) = get_coeff_and_carry(l0_temp);
        let (coeff1, carry1) = get_coeff_and_carry(l1_temp);
        let (coeff2, carry2) = get_coeff_and_carry(l2_temp);
        let (coeff3, carry3) = get_coeff_and_carry(l3_temp);
        let (coeff4, carry4) = get_coeff_and_carry(l4_temp);

        let res0: u64 = coeff0 + times19(carry4);
        let res1: u64 = coeff1 + carry0;
        let res2: u64 = coeff2 + carry1;
        let res3: u64 = coeff3 + carry2;
        let res4: u64 = coeff4 + carry3;

        let res: Element = Element {
            l0: res0,
            l1: res1,
            l2: res2,
            l3: res3,
            l4: res4
        };

        res
    }
}

impl Element {
    // This goes in a separate impl, because if we use previously defined functions in Fp impl, 
    // Sway will not recognize them from inside the same impl
    
    //returns self mod 2^255-19
    fn reduce(self) -> Element {
        let mut red: Element = self.carry_propagate();

        //Determine whether *red* is already completely reduced mod 2^255-19 or not
        // if v >= 2^255 - 19 => v + 19 >= 2^255
        let mut carry = (red.l0 + 19) >> 51;
        carry = (red.l1 + carry) >> 51;
        carry = (red.l2 + carry) >> 51;
        carry = (red.l3 + carry) >> 51;
        carry = (red.l4 + carry) >> 51;

        let mut v0 = red.l0 + times19(carry);
        let mut v1 = red.l1 + (v0 >> 51);
        v0 = v0 & MASK_LOW_51_BITS;
        let mut v2 = red.l2 + (v1 >> 51);
        v1 = v1 & MASK_LOW_51_BITS;
        let mut v3 = red.l3 + (v2 >> 51);
        v2 = v2 & MASK_LOW_51_BITS;
        let mut v4 = (red.l4 + (v3 >> 51)) & MASK_LOW_51_BITS;
        v3 = v3 & MASK_LOW_51_BITS;

        Element {
            l0: v0,
            l1: v1,
            l2: v2,
            l3: v3,
            l4: v4,
        }
    }

    //returns self+rhs mod 2^255 - 19
    fn add(self, rhs: Element) -> Element {
        let temp = Element {
            l0: self.l0 + rhs.l0,
            l1: self.l1 + rhs.l1,
            l2: self.l2 + rhs.l2,
            l3: self.l3 + rhs.l3,
            l4: self.l4 + rhs.l4,
        };

        temp.carry_propagate()
    }

    //returns self*rhs mod 2^255 - 19
    fn multiply(self, rhs: Element) -> Element {
        //https://cs.opensource.google/go/go/+/master:src/crypto/internal/edwards25519/field/fe_generic.go;l=34;bpv=0?q=feMul&sq=&ss=go%2Fgo

        let a0 = self.l0;
        let a1 = self.l1;
        let a2 = self.l2;
        let a3 = self.l3;
        let a4 = self.l4;

        let b0 = rhs.l0;
        let b1 = rhs.l1;
        let b2 = rhs.l2;
        let b3 = rhs.l3;
        let b4 = rhs.l4;

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

        res.carry_propagate()
    }
}

impl Element {
    // This goes in a separate impl, because if we use previously defined functions in Fp impl, 
    // Sway will not recognize them from inside the same impl

    //returns self-rhs mod 2^255 - 19
    fn subtract(self, rhs: Element) -> Element {
        // we add 2*p to avoid any underflow and then subtract b
        let res: Element = Element {
            l0: (self.l0 + 0xFFFFFFFFFFFDA) - rhs.l0,
            l1: (self.l1 + 0xFFFFFFFFFFFFE) - rhs.l1,
            l2: (self.l2 + 0xFFFFFFFFFFFFE) - rhs.l2,
            l3: (self.l3 + 0xFFFFFFFFFFFFE) - rhs.l3,
            l4: (self.l4 + 0xFFFFFFFFFFFFE) - rhs.l4,
        };

        res.reduce()
    }

    //returns self^2 mod 2^255 - 19
    fn square(self) -> Element {
        self.multiply(self)
    }
}

impl Element {
    // This goes in a separate impl, because if we use previously defined functions in Fp impl, 
    // Sway will not recognize them from inside the same impl

    //returns (-self) mod 2^255 - 19
    fn negate(self) -> Element {
        ZERO.subtract(self)
    }

    //Testing not done because of error Immediate18TooLarge
    // returns self^-1 mod p
    //self^(-1) mod p = self^(p-2) mod p by  Fermat's theorem, hence we calculate self^(p-2) mod p
    fn inverse(self) -> Element {
        let mut i = 0;
        let z2 = self.square();                 //2
        // let mut t = z2.square();             //4
        // t = t.square();                      //8

        // let z9 = t*self;             //9
        // let z11 = z9*z2;         //11
        // t = z11.square();                    //22

        // let z2_5_0 = t*z9;       //31
        // t = z2_5_0.square();                 // 62 = 2^6 - 2^1
        // while i < 4 {
        //     t = t.square();                  // 2^10 - 2^5
        //     i+=1;                            
        // }

        // let z2_10_0 = t * z2_5_0;  // 2^10 - 2^0

        // t = square(z2_10_0);                //2^11 - 2^1
        // i = 0;
        // while i < 9 {
        //     t = square(t);                  //2^20 - 2^10
        //     i += 1;
        // }

        // let z2_20_0 = t * z2_10_0; //2^20 - 2^0

        // t = z2_20_0.square();                //2^21 - 2^1
        // i = 0;
        // while i < 19 {
        //     t = t.square();                  //2^40 - 2^20
        //     i += 1;
        // }

        // t = t * z2_20_0;           //2^40 - 2^0

        // t = t.square(); // 2^41 - 2^1
        
        // i = 0;
        // while i < 10 {
        //     t = t.square();                  //2^50 - 2^10
        // }

        // let z2_50_0 = t * z2_10_0; //2^50 - 2^0

        // t = z2_50_0.square();                //2^51 - 2^1

        // i = 0;
        // while i < 49 {
        //     t = t.square();                  //2^100 - 2^50
        //     i += 1;
        // }
        
        // let z2_100_0 = t * z2_50_0;//2^100 - 2^0

        // t = z2_100_0.square();               //2^101 - 2^1

        // i = 0;
        // while i < 99 {
        //     t = t.square();                  //2^200 - 2^100
        //     i += 1;
        // }

        // t = t * z2_100_0;          //2^200 - 2^0

        // t = t.square();                      //2^201 - 2^1

        // i = 0;
        // while i < 49 {
        //     t = t.square();                  //2^250 - 2^50
        //     i += 1;
        // }

        // t = t * z2_50_0;           //2^250 - 2^0

        // i = 0;
        // while i < 5 {
        //     t = t.square();                  //2^255 - 2^5
        //     i += 1;
        // }

        // t = t * z11;               //2^255 - 21 = p - 2

        // return t;
        self
    }

}

//returns a*b as u128
pub fn multiply64(a: u64, b: u64) -> U128 {
    let a_128: U128 = ~U128::from(0, a);
    let b_128: U128 = ~U128::from(0, b);
    a_128 * b_128
}

//returns res + a * b
pub fn add_multiply64(res: U128, a: u64, b: u64) -> U128 {
    let mul_res: U128 = multiply64(a, b);
    let add_res: (u64, u64) = adc(mul_res.lower, res.lower, 0);
    let add_res2: (u64, u64) = adc(mul_res.upper, res.upper, add_res.1);

    ~U128::from(add_res2.0, add_res.0)
}

//returns a>>51 as u64
pub fn shift_right_by51(a: U128) -> u64 {
    (a.upper <<(64 - 51)) | (a.lower >> 51)
}

// For a bignumber <= 102 bits stored in U128,
// return the 51 bit coefficient and 51 bit carry
pub fn get_coeff_and_carry(y: U128) -> (u64, u64) {
    let coeff: u64 = y.lower & MASK_LOW_51_BITS;
    let carry: u64 = (y.upper << 13 & MASK_LOW_51_BITS) | y.lower >> 51;
    (coeff, carry)
}

impl ConstantTimeEq for Element {
    // returns (self == other), as a choice
    fn ct_eq(self, other: Element) -> Choice {
        ~u64::ct_eq(self.l0, other.l0)
        & ~u64::ct_eq(self.l1, other.l1)
        & ~u64::ct_eq(self.l2, other.l2)
        & ~u64::ct_eq(self.l3, other.l3)
        & ~u64::ct_eq(self.l4, other.l4)
    }
}

// Implement interfaces for symbol usage (==, +, -, *)

// Eq in Sway requires bool return type
impl Eq for Element {
    fn eq(self, other: Self) -> bool {
        self.ct_eq(other).unwrap_as_bool()
    }
}

impl Add for Element {
    fn add(self, other: Self) -> Self {
        self.add(other)
    }
}

impl Subtract for Element {
    fn subtract(self, other: Self) -> Self {
        self.subtract(other)
    }
}

impl Multiply for Element {
    fn multiply(self, other: Self) -> Self {
        self.multiply(other)
    }
}
