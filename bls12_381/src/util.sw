library util;

dep choice; 
use choice::*;

impl ConditionallySelectable for u64 {
    // TODO How can we do this in Sway in constant time?
    fn conditional_select(a: u64, b: u64, choice: Choice) -> u64 {
        // From original impl:

        // if choice = 0, mask = (-0) = 0000...0000
        // if choice = 1, mask = (-1) = 1111...1111

        // let mask = -(choice.unwrap_u8() as to_signed_int!($t)) as $t;
        // a ^ (mask & (a ^ b))

// Apparently this doesn't work in Sway?
        // match choice {
        //     Choice(0) => a,
        //     Choice(1) => b,
        // }

        // TODO improve. 
        if (choice.unwrap_u8() == 0) {
            a
        } else {
            b
        }
    }
}