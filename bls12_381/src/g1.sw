library g1;

// Comment from zkcrypto
/// This is an element of $\mathbb{G}_1$ represented in the affine coordinate space.
/// It is ideal to keep elements in this representation to reduce memory usage and
/// improve performance through the use of mixed curve model arithmetic.
///
/// Values of `G1Affine` are guaranteed to be in the $q$-order subgroup unless an
/// "unchecked" API was misused.
pub struct G1Affine {
    pub x: Fp,
    pub y: Fp,
    infinity: Choice,
}

pub struct G1Projective {
    pub x: Fp,
    pub y: Fp,
    pub z: Fp,
}

// TODO: trying to get this to work, seems like a good starting point
// fn from(p: G1Projective) -> G1Affine {
//     let zinv = p.z.invert().unwrap_or(~Fp::zero());
//     let x = p.x * zinv;
//     let y = p.y * zinv;

//     let tmp = G1Affine {
//         x,
//         y,
//         infinity: Choice::from(0u8),
//     };

//     G1Affine::conditional_select(&tmp, &G1Affine::identity(), zinv.is_zero())
// }

impl G1Affine {
    /// Returns the identity of the group: the point at infinity.
    pub fn identity() -> G1Affine {
        G1Affine {
            x: Fp::zero(),
            y: Fp::one(),
            infinity: Choice::from(1u8),
        }
    }
}