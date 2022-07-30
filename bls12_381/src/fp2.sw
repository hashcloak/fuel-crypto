library fp2;

dep fp;
use fp::*;

pub struct Fp2 {
    c0: Fp, //"real" part
    c1: Fp, //"imaginary" part
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
        self.c0.eq(other.c0) && self.c1.eq(other.c1) 
    }

//TODO test
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

        let a = (self.c0).add(self.c1);
        let b = (self.c0).sub(self.c1);
        let c = (self.c0).add(self.c0);

        Fp2 {
            c0: (a).mul(b),
            c1: (c).mul(self.c1),
        }
    }

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
    }
//TODO test
    pub fn add(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: (self.c0).add(rhs.c0),
            c1: (self.c1).add(rhs.c1),
        }
    }
//TODO test
    pub fn sub(self, rhs: Fp2) -> Fp2 {
        Fp2 {
            c0: (self.c0).sub(rhs.c0),
            c1: (self.c1).sub(rhs.c1),
        }
    }
//TODO test
    pub fn neg(self) -> Fp2 {
        Fp2 {
            c0: (self.c0).neg(),
            c1: (self.c1).neg(),
        }
    }

}