library fp;

use std::u128::*;

/*
Follows implementations
https://github.com/zkcrypto/bls12_381
https://github.com/zcash/librustzcash/tree/6e0364cd42a2b3d2b958a54771ef51a8db79dd29/pairing/src 

Standard
https://tools.ietf.org/id/draft-yonezawa-pairing-friendly-curves-02.html#rfc.section.4.2.2
Naming of variables follows this standard

Additionally specifically on the instantiation of the curve
https://github.com/zcash/librustzcash/tree/6e0364cd42a2b3d2b958a54771ef51a8db79dd29/pairing/src/bls12_381

*/

// Stores field element with max 384 bits
pub struct Fp {
    ls: [u64; 6],
}

const ZERO: Fp = Fp {ls: [0, 0, 0, 0, 0, 0]};

/*
    p = 0x1a0111ea 397fe69a 4b1ba7b6 434bacd7 64774b84 f38512bf 6730d2a0 f6b0f624 1eabfffe b153ffff b9feffff ffffaaab
    = 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787
    (381 bits)
*/
const MODULUS: Fp = Fp {
    ls: [0xb9feffffffffaaab,
    0x1eabfffeb153ffff,
    0x6730d2a0f6b0f624,
    0x64774b84f38512bf,
    0x4b1ba7b6434bacd7,
    0x1a0111ea397fe69a]
};

/*
    r : 0x73eda753 299d7d48 3339d808 09a1d805 53bda402 fffe5bfe ffffffff 00000001
    52435875175126190479447740508185965837690552500527637822603658699938581184513
    255 bits prime order of first group
*/
const R: Fp = Fp {
    ls: [0xffffffff00000001,
    0x53bda402fffe5bfe,
    0x3339d80809a1d805,
    0x73eda753299d7d48,
    0,
    0]
};

/*
    x: 0x17f1d3a7 3197d794 2695638c 4fa9ac0f c3688c4f 9774b905 a14e3a3f 171bac58 6c55e83f f97a1aef fb3af00a db22c6bb
    3685416753713387016781088315183077757961620795782546409894578378688607592378376318836054947676345821548104185464507
*/
const G1_GENERATOR_X: Fp = Fp {
    ls: [0xfb3af00adb22c6bb,
    0x6c55e83ff97a1aef,
    0xa14e3a3f171bac58,
    0xc3688c4f9774b905,
    0x2695638c4fa9ac0f,
    0x17f1d3a73197d794]
};

/*
    y: 0x08b3f481 e3aaa0f1 a09e30ed 741d8ae4 fcf5e095 d5d00af6 00db18cb 2c04b3ed d03cc744 a2888ae4 0caa2329 46c5e7e1
    1339506544944476473020471379941921221584933875938349620426543736416511423956333506472724655353366534992391756441569
*/
const G1_GENERATOR_Y: Fp = Fp {
    ls: [0xcaa232946c5e7e1,
    0xd03cc744a2888ae4,
    0xdb18cb2c04b3ed,
    0xfcf5e095d5d00af6,
    0xa09e30ed741d8ae4,
    0x8b3f481e3aaa0f1]
};

// INV = -(q^{-1} mod 2^64) mod 2^64
const INV: u64 = 0x89f3fffcfffcfffd;

//TODO GET TESTS
//TODO this function is also in edwards25519/src/field_element.sw (called add64). Where do we want to place these overlapping functions?
//returns sum with carry of a and b
fn adc (a: u64, b: u64, carry: u64) -> (u64, u64) {
    let A:U128 = U128{upper: 0, lower: a};
    let B:U128 = U128{upper: 0, lower: b};
    let Carry: U128 = U128 { upper: 0, lower: carry };

    let sum: u64 = (A+B+Carry).lower;
    let notSum = ~u64::max() - sum;
    let carryOut =  ((a & b) | ((a | b) & notSum)) >> 63; 

    (sum, carryOut)
}

pub trait Add {
    pub fn add(self, other: Self) -> Self;
}

// TODO TEST
// If x >= y: x-y, else max::U128 - (y-x)
fn subtract_wrap(x: U128, y: U128) -> U128 {
    if y > x {
        ~U128::max() - (y - x)
    } else {
        x - y
    }
}

//TODO TEST
/// Compute a - (b + borrow), returning the result and the new borrow.
fn sbb(a: u64, b: u64, borrow: u64) -> (u64, u64) {
    let a_128: U128 = U128 { lower: a, upper: 0};
    let b_128: U128 = U128 { lower: b, upper: 0};
    let borrow_128: U128 = U128 { lower: borrow >> 63, upper: 0};

    let ret: U128 = subtract_wrap(a_128, b_128 + borrow_128);
    (ret.lower, ret.upper) //(result, borrow)
}

//TODO TEST
fn not(input: u64) -> u64 {
    ~u64::max() - input
}

// from https://github.com/zkcrypto/bls12_381
//TODO TEST
// If a >= p, return a-p, else return a
fn subtract_p(a: Fp) -> Fp {
        let (r0, borrow) = sbb(a.ls[0], MODULUS.ls[0], 0);
        let (r1, borrow) = sbb(a.ls[1], MODULUS.ls[1], borrow);
        let (r2, borrow) = sbb(a.ls[2], MODULUS.ls[2], borrow);
        let (r3, borrow) = sbb(a.ls[3], MODULUS.ls[3], borrow);
        let (r4, borrow) = sbb(a.ls[4], MODULUS.ls[4], borrow);
        let (r5, borrow) = sbb(a.ls[5], MODULUS.ls[5], borrow);

        // If underflow occurred on the final limb, borrow = 0xfff...fff, otherwise
        // borrow = 0x000...ls00. Thus, we use it as a mask!
        let r0 = (a.ls[0] & borrow) | (r0 & not(borrow));
        let r1 = (a.ls[1] & borrow) | (r1 & not(borrow));
        let r2 = (a.ls[2] & borrow) | (r2 & not(borrow));
        let r3 = (a.ls[3] & borrow) | (r3 & not(borrow));
        let r4 = (a.ls[4] & borrow) | (r4 & not(borrow));
        let r5 = (a.ls[5] & borrow) | (r5 & not(borrow));

        Fp{ ls: [r0, r1, r2, r3, r4, r5]}
    }

impl Add for Fp {
    pub fn add(self, rhs: Self) -> Self {
        let (d0, carry) = adc(self.ls[0], rhs.ls[0], 0);
        let (d1, carry) = adc(self.ls[1], rhs.ls[1], carry);
        let (d2, carry) = adc(self.ls[2], rhs.ls[2], carry);
        let (d3, carry) = adc(self.ls[3], rhs.ls[3], carry);
        let (d4, carry) = adc(self.ls[4], rhs.ls[4], carry);
        let (d5, _) = adc(self.ls[5], rhs.ls[5], carry);

        //subtract p if needed
        subtract_p(Fp{ ls: [d0, d1, d2, d3, d4, d5] })
    }
}
