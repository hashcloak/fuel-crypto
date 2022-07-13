library ec1;

dep fields;
dep consts;

use ::fields::*;
use ::consts::*;

/*
 y^2 = x^3 + B

B = (4 << 384) % P
= 1514052131932888505822357196874193114600527104240479143842906308145652716846165732392247483508051665748635331395571

According to Zcash impl this is equal to 4
 */
const B_E1: vec384 = {
    ls: [0xaa270000000cfff3, 0x53cc0032fc34000a,
    0x478fe97a6b0a807f, 0xb1d37ebee6ba24d7,
    0x8ec9733bbf78ab2f, 0x09d645513d83de7e]
};

const BLS12_381_G1: POINTonE1 = {    /* generator point [in Montgomery] */
    /* 
    (0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905
        a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb << 384) % P
    = 2771334866125919199105806127325991204049638301394587550983394276622338185155646768704112188431188468948617777056790
    */
    x: [0x5cb38790fd530c16, 0x7817fc679976fff5, 0x154f95c7143ba1c1, 0xf0ae6acdf3d0e747, 0xedce6ecc21dbf440, 0x120177419e0bfb75`],
    /*
    (0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af6
        00db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1 << 384) % P
    = 1806233535529883172442092828064561001318757138177058380995827434860385074092408792531060859215838632649768391090801
    */
    y: [0xbaac93d50ce72271, 0x8c22631a7918fd8e, 0xdd595f13570725ce, 0x51ac582950405194, 0xe1c8c3fad0059c0, 0xbbc3efc5008a26a],
    z: ONE_MONT_P
};

const BLS12_381_NEG_G1: POINTonE1 = {    /* negative generator [in Montgomery] */
    /* 
    (0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905
        a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb << 384) % P
    = 2771334866125919199105806127325991204049638301394587550983394276622338185155646768704112188431188468948617777056790
    */
    x: [0x5cb38790fd530c16, 0x7817fc679976fff5, 0x154f95c7143ba1c1, 0xf0ae6acdf3d0e747, 0xedce6ecc21dbf440, 0x120177419e0bfb75],
    /*
    (0x114d1d6855d545a8aa7d76c8cf2e21f267816aef1db507c9
        6655b9d5caac42364e6f38ba0ecb751bad54dcd6b939c2ca << 384) % P
    = 2196176019691784220975696997671343155238125681761949504336230701263646576398429071911626769913177031388125881468986
    */
    y: [0xff526c2af318883a, 0x92899ce4383b0270, 0x89d7738d9fa9d055, 0x12caf35ba344c12a, 0x3cff1b76964b5317, 0xe44d2ede9774430],
    z: ONE_MONT_P
};

// TODO TEST
// TODO: why is mul by b equal to *4? 
// value of b is 4 << 384 mod p
pub fn mul_by_b_onE1(in: vec384) -> vec384 {
    lshift_fp(in, 2)
}

// TODO TEST
pub fn mul_by_4b_onE1(in: vec384) -> vec384 {
    lshift_fp(in, 4)
}

// TODO TEST
pub fn POINTonE1_cneg(p: POINTonE1, cbit: u64) -> vec384 {
    cneg_fp(p.y, cbit)
}

// TODO TEST
pub fn blst_p1_cneg(a: POINTonE1, cbit: u32) -> vec384 {
    POINTonE1_cneg(a, is_zero(cbit) ^1)
}

pub fn POINTonE1_from_Jacobian(in: POINTonE1) -> POINTonE1 {
    //TODO
    POINTonE1 { x: ONE_MONT_P, y: ONE_MONT_P, z: ONE_MONT_P }
}

