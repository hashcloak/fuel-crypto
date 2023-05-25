library;

use std::option::Option;
use ::ecdsa::Signature;
use ::scalar::{Scalar, MODULUS_SCALAR};
use ::modular_helper::{to_bytes, add};
use utils::integer_utils::adc;
pub struct RecoveryId{id: u8}

// The error type used when the `ec_recover` function fails.
pub enum EcRecoverError {
    UnrecoverablePublicKey: (),
}

fn from_bool(b: bool) -> u8 {
        // using assembly to avoid if branch
        let id_as_u8 = asm(r1: b) { // set register 1 (r1) to value b
            r1: u8 //simply read the bool as a u8
        };
        id_as_u8
    }

fn checked_add(a: [u64;4], b: [u64;4]) -> Option<[u64;4]> {

    let (w0, carry0) = adc(a[0], b[0], 0);
    let (w1, carry1) = adc(a[1], b[1], carry0);
    let (w2, carry2) = adc(a[2], b[2], carry1);
    let (w3, w4) = adc(a[3], b[3], carry2);

    if w4 == 0 {
        Option::Some([w0, w1, w2, w3])
    }

    else {Option::None}
}
impl RecoveryId {

    // Maximum supported value for the recovery ID (inclusive).
    const MAX: u8 = 3;

    // Create a new [`RecoveryId`] from the following 1-bit arguments:
    //
    // - `is_y_odd`: is the affine y-coordinate of 𝑘×𝑮 odd?
    // - `is_x_reduced`: did the affine x-coordinate of 𝑘×𝑮 overflow the curve order?

    pub fn new(is_y_odd: bool, is_x_reduced: bool) -> Self {
        RecoveryId{id: (from_bool(is_x_reduced)) << 1 | from_bool(is_y_odd)}
    }

    // Did the affine x-coordinate of 𝑘×𝑮 overflow the curve order?
    pub fn is_x_reduced(self) -> bool {
        self.id & 2 != 0
    }

    // Is the affine y-coordinate of 𝑘×𝑮 odd?
    pub fn is_y_odd(self) -> bool {
        (self.id & 1) != 0
    }

    // Convert a `u8` into a [`RecoveryId`].
    pub fn from_byte(byte: u8) -> Option<Self> {
        if byte <= Self::MAX {
            Option::Some(RecoveryId{id:byte})
        } else {
            Option::None
        }
    }

    // Convert this [`RecoveryId`] into a `u8`.
    pub fn to_byte(self) -> u8 {
        self.id
    }
}

// impl RecoveryId {
//     pub fn recover_from_prehash(prehash: [u8;32], sign: Signature, recovery_id: RecoveryId) {
//         let mut r = sign.r.ls;
//         let s = sign.s;
//         let z = Scalar::from_bytes(prehash);

//         // let mut r_bytes = to_bytes(r.ls);
//         if recovery_id.is_x_reduced() {

//             let sum = checked_add(r, MODULUS_SCALAR);
//             if Option::is_none(sum) {
//                 EcRecoverError::UnrecoverablePublicKey
//             }
//             else {
//                 Option::unwrap(sum)
//             }
//         }
//     }
// }
