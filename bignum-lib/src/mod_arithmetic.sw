library mod_arithmetic;

dep helpers;
dep big_uint;

use helpers::*;
use big_uint::*;

use std::{assert::assert, option::*, vec::Vec};
use std::logging::log;
use core::num::*;

//returns true if two BigUint are equal
pub fn is_equal (a: BigUint, b: BigUint) -> bool {

    if a.data.len() == 0 || b.data.len() == 0 {
        return false;
    }
    else if a.data.len() != b.data.len() {
        return false;
    } else {

        let mut flag = true;
        let mut i = a.data.len() - 1;
        while(i >= 0 && flag) {
            if unpack_or_0(a.data.get(i)) != unpack_or_0(b.data.get(i)) {
            flag = false;
            }
            i-=1;
        }

        return flag;
    }
}

//multiplication of BigUint with u32 integer

pub fn sclar_multiplication (a: BigUint, b: u32) -> BigUint {

    let mut i = 0;
    let mut res: Vec<u32> = ~Vec::new::<u32>();
    let mut a_i: u64 = 0;
    let mut carry: u64 = 0;

    while i < a.data.len() {
        a_i = unpack_or_0(a.data.get(i))*b + carry;
        res.push( a_i & 0xffffffff);
        carry = ((a_i >> 32) & 0xffffffff);

        i += 1;
    }

    if carry != 0 {
        res.push(carry);
    }

    BigUint {
        data: res
    }
}

pub fn mod (a: BigUint, n: BigUint) -> BigUint {

    //if a==n (a<=n & n<=a) then (a mod n) = 0
    // if a < n then (a mod n) = a
    //if a > n then a (mod n) = r where a = qn + r
    //      case1:  if  number of limbs are same
    //      case2:  if numner of limbs are unequal
    if is_equal (a, n){
        let mut a: Vec<u32> = ~Vec::new::<u32>(); 
        a.push(0u32);

        return BigUint {
            data: a
        };
    } else if is_bigger_or_equal(n,a) {
        return a;
    } else {

        let len_a = a.data.len();
        let len_n = n.data.len();
        let mut k: u32 = 1;
        let mut nk: BigUint = n;
        if len_a == len_n {
            //let  mut quotient: u32 = 1<<16; 
            while is_bigger_or_equal(a, nk) {
                
                k += 1;
                nk = sclar_multiplication(n, i);
            }
            nk = sclar_multiplication(n, k-1);
            //let res: BigUint = sub (a, nk);

            return sub(a, nk);
        } else {
            return sclar_multiplication(n, k);
        }
    }
}



// pub fn mod_add (a: BigUint, b: BigUint) -> BigUint {

// }