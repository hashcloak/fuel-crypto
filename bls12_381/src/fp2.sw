library fp2;

dep fp;
use fp::Fp;
use core::ops::{Eq, Add, Subtract, Multiply};

pub struct Fp2 {
    c0: Fp,
    c1: Fp,
}

impl Fp2 {
    fn from(f: Fp) -> Fp2 {
        Fp2 {
            c0: f,
            c1: ~Fp::zero(),
        }
    }

    pub fn zero() -> Fp2 {
        Fp2 {
            c0: ~Fp::zero(),
            c1: ~Fp::zero(),
        }
    }

    pub fn one() -> Fp2 {
        Fp2 {
            c0: ~Fp::one(),
            c1: ~Fp::zero(),
        }
    }

    fn eq(self, other: Self) -> bool {
        self.c0 == other.c0 && self.c1 == other.c1
    }
/*
// //TODO test
    pub fn square(self) -> Fp2 {
        // Complex squaring:
        //
        // v0  = c0 * c1
        // c0' = (c0 + c1) * (c0 + \beta*c1) - v0 - \beta * v0
        // c1' = 2 * v0
        //
        // In BLS12-381's F_{p^2}, our \beta is -1 so we
        // can modify this formula:
        //
        // c0' = (c0 + c1) * (c0 - c1)
        // c1' = 2 * c0 * c1

        let a = self.c0 + self.c1;
        let b = self.c0 - self.c1;
        let c = self.c0 + self.c0;

        Fp2 {
            c0: a * b,
            c1: c * self.c1,
        }
    }
    */
/*
    pub fn mul(self, rhs: Fp2) -> Fp2 {
        // F_{p^2} x F_{p^2} multiplication implemented with operand scanning (schoolbook)
        // computes the result as:
        //
        //   a·b = (a_0 b_0 + a_1 b_1 β) + (a_0 b_1 + a_1 b_0)i
        //
        // In BLS12-381's F_{p^2}, our β is -1, so the resulting F_{p^2} element is:
        //
        //   c_0 = a_0 b_0 - a_1 b_1
        //   c_1 = a_0 b_1 + a_1 b_0
        //
        // Each of these is a "sum of products", which we can compute efficiently.

        Fp2 {
            c0: ~Fp::sum_of_products_2([self.c0, self.c1.neg()], [rhs.c0, rhs.c1]),
            c1: ~Fp::sum_of_products_2([self.c0, self.c1], [rhs.c1, rhs.c0]),
        }
        //--------------------------------------------
        // From zcash impl
        // fn mul_assign(&mut self, other: &Self) {
        // let mut aa = self.c0;
        // aa.mul_assign(&other.c0);
        // let mut bb = self.c1;
        // bb.mul_assign(&other.c1);
        // let mut o = other.c0;
        // o.add_assign(&other.c1);
        // self.c1.add_assign(&self.c0);
        // self.c1.mul_assign(&o);
        // self.c1.sub_assign(&aa);
        // self.c1.sub_assign(&bb);
        // self.c0 = aa;
        // self.c0.sub_assign(&bb);
        //------------------------------------
        // let mut aa = self.c0;
        // let mut aa = aa.mul(rhs.c0);
        // let mut bb = self.c1;
        // let mut bb = bb.mul(rhs.c1);
        // let mut o = rhs.c0;
        // let mut o = o.add(rhs.c1);
        // let mut c1 = self.c1.add(self.c0);
        // let mut c1 = self.c1.mul(o);
        // let mut c1 = self.c1.sub(aa);
        // let mut c1 = self.c1.sub(bb);
        // let mut c0 = aa;
        // let mut c1 = self.c0.sub(bb);

        // Fp2{
        //     c0: c0,
        //     c1: c1
        // }
    }
*/
    pub fn add(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: self.c0 + rhs.c0,
            c1: self.c1 + rhs.c1,
        }
    }

    pub fn sub(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: self.c0 - rhs.c0,
            c1: self.c1 - rhs.c1,
        }
    }

    pub fn neg(self) -> Fp2 {
        Fp2 {
            c0: (self.c0).neg(),
            c1: (self.c1).neg(),
        }
    }

    // Is not tested directly, but will be indirectly
    pub fn mul_by_nonresidue(self) -> Fp2 {
        // Multiply a + bu by u + 1, getting
        // au + a + bu^2 + bu
        // and because u^2 = -1, we get
        // (a - b) + (a + b)u

        Fp2 {
            c0: self.c0 - self.c1,
            c1: self.c0 + self.c1,
        }
    }

}

impl Eq for Fp2 {
    fn eq(self, other: Self) -> bool {
        self.eq(other)
    }
}

impl Add for Fp2 {
    fn add(self, other: Self) -> Self {
        self.add(other)
    }
}

impl Subtract for Fp2 {
    fn subtract(self, other: Self) -> Self {
        self.sub(other)
    }
}

// impl Multiply for Fp2 {
//         fn multiply(self, other: Self) -> Self {
//             self.mul(other)
//         }
// }