library field_element;

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
return reduced element mod 2^255-19
*/
pub fn mod_25519(e: Element) -> Element {
    let red: Element = carry_propagate(e);

    //Determine whether *red* is already completely reduced mod 2^255-19 or not
    // if v >= 2^255 - 19 => v + 19 >= 2^255
    let mut carry0 = (red.l0 + 19) >> 51;
    carry0 = (red.l1 + carry0) >> 51;
    carry0 = (red.l2 + carry0) >> 51;
    carry0 = (red.l3 + carry0) >> 51;
    carry0 = (red.l4 + carry0) >> 51;

    if carry0 == 1 { // not sure if == 1 is necessary
        carry_propagate(red)
    } else {
        red
    }
}