library big_uint;

dep helpers;
use helpers::*;

use std::{assert::assert, option::*, vec::Vec};
use std::logging::log;
use core::num::*;

/*
Representation of a big unsigned number of arbitrary length

Note: The largest primitive type in Sway is u64, therefore the BigUint consists of a vector with u32 entries.
When 2 BigUints are added, the result might require more than 32 bits and this will fit into a u64. 
*/
pub struct BigUint {
    data: Vec<u32>,
}

impl Zero for BigUint {
    fn is_zero(self) -> bool {
        return self.data.len() == 0;
    }
}

fn max(left: u64, right: u64) -> u64 {
    if(left >= right) { left } else { right }
}

/*
returns the result of the 3 numbers added together
*/
fn add_limb(a_i: u32, b_i: u32, carry_i: u32) -> u64 {
    let A_i: u64 = a_i;
    let B_i: u64 = b_i;

    A_i + B_i + carry_i
}

/*
returns the 2 bigUints added together. 

Note: This result might be 1 longer than the longest entry. 
*/
pub fn add(a: BigUint, b: BigUint) -> BigUint {
    let a_vec: Vec<u32> = a.data;
    let b_vec: Vec<u32> = b.data;
    let len_a :u32 = a_vec.len();
    let len_b :u32 = b_vec.len();
    let max_len: u32 = max(len_a, len_b);

    let mut res: Vec<u32> = ~Vec::new::<u32>();
    let mut i = 0;
    let mut carry_i: u32 = 0;
    let mut z: u64 = 0;

    while i < max_len {
        z = add_limb(unpack_or_0(a_vec.get(i)), unpack_or_0(b_vec.get(i)), carry_i);

        res.push(z & 0xffffffff);
        carry_i = ((z>>32) & 0xffffffff);
        i = i + 1;
    }

    if carry_i != 0 {
        res.push(carry_i);
    }

    BigUint{data: res}
}


/*
returns whether the value that a represents is larger than b
*/
fn is_bigger_or_equal(a: BigUint, b: BigUint) -> bool {
    if a.data.len() > b.data.len() {
        return true;
    } else if a.data.len() == b.data.len() {
        if a.data.len() == 0 {
            return true;
        }
        let mut i = a.data.len() - 1;
        let mut a_is_bigger_or_equal = true;
        let mut looping = true;
        while i >= 0 && looping {
            let a_val = unpack_or_0(a.data.get(i));
            let b_val = unpack_or_0(b.data.get(i));
            if  a_val > b_val {
                looping = false; // we know a is bigger
            } else if a_val < b_val {
                a_is_bigger_or_equal = false;
                looping = false; // we know b is bigger
            } else if a_val == b_val && i == 0 {
                looping = false; // we have seen all elements and a & b are equal
            } else {
                // If we're not sure yet and the index is not yet 0; keep looping
                i = i - 1;
            }
        }
        return a_is_bigger_or_equal;
    } else {
        return false;
    }
}

/*
returns (res_i, borrow_i); the result and the possible borrow of a_i - b_i - borrow_i
*/
fn sub_limb(a_i: u32, b_i: u32, borrow_i: u32) -> (u32, u32) {
    if (b_i + borrow_i) > a_i {
        (~u32::max() - ((b_i + borrow_i) - a_i), 1)
    } else {
        (a_i - b_i - borrow_i, 0u32)
    }
}

/*
return Some(BigUint) if a >= b, otherwise None
*/
pub fn sub(a: BigUint, b: BigUint) -> Option<BigUint> {
    // Special case 0 - 0 = 0
    if(a.data.len() == 0 && b.data.len() == 0) {
        return Option::Some(BigUint{data: ~Vec::new::<u32>()});
    }

    if is_bigger_or_equal(a, b) {
        let a_vec: Vec<u32> = a.data;
        let b_vec: Vec<u32> = b.data;
        let len_a: u32 = a_vec.len();

        let mut res: Vec<u32> = ~Vec::new::<u32>();
        let mut i = 0;
        let mut borrow_i: u32 = 0;
        let mut x: u32 = 0;

        while i < len_a {
            let sub_limb_res = sub_limb(unpack_or_0(a_vec.get(i)), unpack_or_0(b_vec.get(i)), borrow_i);
            x = sub_limb_res.0;
            borrow_i = sub_limb_res.1;
            res.push(x);
            i = i + 1;
        }

        // Return the result without trailing zeroes
        // Vectors are not yet mutable, so we create a new one and fill it up until possible trailing zeroes
        let mut most_significant_bit_index = len_a - 1;
        let mut index_found = false;
        while !index_found && most_significant_bit_index > 0 {
            if (unpack_or_0(res.get(most_significant_bit_index)) != 0) {
                index_found = true;
            } else {
                most_significant_bit_index = most_significant_bit_index - 1;
            }
        }

        let mut normalized_res: Vec<u32> = ~Vec::new::<u32>();
        let res_is_zero = most_significant_bit_index == 0 && unpack_or_0(res.get(0)) == 0;
        if(!res_is_zero) {
            let mut j = 0;
            while j <= most_significant_bit_index {
                normalized_res.push(unpack_or_0(res.get(j)));    
                j = j + 1;
            }

        }
        
        return Option::Some(BigUint{data: normalized_res});
    } else {
        return Option::None::<BigUint>();
    }
}

/*
Not optimized
*/
pub fn schoolbook_mult(a: BigUint, b: BigUint) -> BigUint {
    let a_vec: Vec<u32> = a.data;
    let b_vec: Vec<u32> = b.data;
    let a_len = a_vec.len();
    let b_len = b_vec.len();

    let mut res_vec: Vec<u32> = ~Vec::new::<u32>();

    let mut i = 0;
    let mut k = 0;
    let mut prod_coeff: u64 = 0;
    let mut prod_carry: u64 = 0;
    let mut temp: u64 = 0; 
    let base: u64 = 0x100000000;
    let mut temp = 0u64; 
    
    while k <= (b_len + a_len) {
        prod_coeff = prod_carry;
        prod_carry = 0;
        while i <= k {
            temp = unpack_or_0(a_vec.get(i)) * unpack_or_0(b_vec.get(k-i));
            if temp >= base {
                prod_carry +=  ((temp >> 32) & 0xffffffff);
                temp =  (temp & 0xffffffff);
            }
            prod_coeff = prod_coeff + temp;
            if prod_coeff >= base {
                prod_carry +=  ((prod_coeff >> 32) & 0xffffffff);
                prod_coeff =  (prod_coeff & 0xffffffff);
            }
            i += 1;
        }
        res_vec.push(prod_coeff);
        i = 0;
        k += 1;
    }

    BigUint{ data: res_vec}
}

//https://aquarchitect.github.io/swift-algorithm-club/Karatsuba%20Multiplication/
/*
pub fn karatsuba_mult(a: BigUint, b: BigUint) -> BigUint {
    if(a.data.len() == 1 || b.data.len() == 1) {
        // in this case it's not worth it?
    }

    let n = max(a.data.len(), b.data.len());
}
*/