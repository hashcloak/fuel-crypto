library fp6;

dep fp2;
dep fp;
dep choice; 

use fp::*;
use fp2::*;
use choice::*;

pub struct Fp6 {
    c0: Fp2,
    c1: Fp2,
    c2: Fp2,
}


impl Fp6 {
    fn from(f: Fp) -> Fp6 {
        Fp6 {
            c0: ~Fp2::from(f),
            c1: ~Fp2::zero(),
            c2: ~Fp2::zero(),
        }
    }

    fn from(f: Fp2) -> Fp6 {
        Fp6 {
            c0: f,
            c1: ~Fp2::zero(),
            c2: ~Fp2::zero(),
        }
    }

    pub fn zero() -> Self {
        Fp6 {
            c0: ~Fp2::zero(),
            c1: ~Fp2::zero(),
            c2: ~Fp2::zero(),
        }
    }

    pub fn one() -> Self {
        Fp6 {
            c0: ~Fp2::one(),
            c1: ~Fp2::zero(),
            c2: ~Fp2::zero(),
        }
    }

//TODO test (but zkcrypto doesnt have a dedicated test, so will be tested implicitly)
    pub fn mul_by_1(self, c1: Fp2) -> Fp6 {
        let b_b = self.c1 * c1;

        let t1 = (self.c1 + self.c2) * c1 - b_b;
        let t1 = t1.mul_by_nonresidue();

        let t2 = (self.c0 + self.c1) * c1 - b_b;

        Fp6 {
            c0: t1,
            c1: t2,
            c2: b_b,
        }
    }
    //TODO: Testing
    pub fn mul_by_01(self, c0: Fp2, c1: Fp2) -> Fp6 {
        let a_a = self.c0 * c0;
        let b_b = self.c1 * c1;

        let t1 = (self.c1 + self.c2) * c1 - b_b;
        let t1 = t1.mul_by_nonresidue() + a_a;

        let t2 = (c0 + c1) * (self.c0 +self.c1) - a_a -b_b;

        let t3 = (self.c0 + self.c2) * c0 - a_a + b_b;

        Fp6 {
            c0: t1,
            c1: t2,
            c2: t3,
        }
    }
    //TODO: Testing
    pub fn add(self, rhs: Fp6) -> Fp6 {
        Fp6 {
            c0: self.c0 + rhs.c0,
            c1: self.c1 + rhs.c1,
            c2: self.c2 + rhs.c2,
        }
    }
    //TODO: Testing
    pub fn sub(self, rhs: Fp6) -> Fp6 {
        Fp6 {
            c0: self.c0 - rhs.c0,
            c1: self.c1 - rhs.c1,
            c2: self.c2 - rhs.c2, 
        }
    }
    //TODO: Testing
    pub fn neg(self) -> Fp6 {
        Fp6 {
            c0: self.c0.neg(),
            c1: self.c1.neg(),
            c2: self.c2.neg(),
        }
    }

    // // Is not tested
    // fn conditional_select(a: Fp6, b: Fp6, choice: Choice) -> Fp6 {
    //     Fp6 {
    //         c0: ~Fp2::conditional_select(a.c0, b.c0, choice),
    //         c1: ~Fp2::conditional_select(a.c1, b.c1, choice),
    //         c2: ~Fp2::conditional_select(a.c2, b.c2, choice),
    //     }
    // }
}