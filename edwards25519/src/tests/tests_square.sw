library tests_square;

use ::field_element::*;
use std::assert::assert;
use ::test_helpers::*;

pub fn tests_square() -> bool {
    // assert(test_square_one());
    // assert(test_square_zero());
    assert(test_square_random());
    true
}

fn test_square_one() -> bool {
    let res: Element = square(ONE);
    res_equals(res, ONE)
}

fn test_square_zero() -> bool {
    let res: Element = square(ZERO);
    res_equals(res, ZERO)
}

fn test_square_random() -> bool {
    /*
    a   = 10406084254717298682985401286246103758749877058048555650117556132341049525816
        = [404732633123850, 312158315551803, 595911506101250, 1303372017735434, 1292655137982008]

    a^2 = 108286589516275277577373161473966445398256506358898379115846293425853328039181187715348880647692926795184739504006825065723361671067040986483318450465856

    a^2 mod p = 31042580993865580304222384966530826020546840941977848835924726765219788840807
              = [1207365348681671, 713663780369466, 912635275234964, 596790797966485, 2144628324130663]

    */

    let a: Element = Element {
        l0: 1292655137982008,
        l1: 1303372017735434,
        l2: 595911506101250,
        l3: 312158315551803,
        l4: 404732633123850
    };

    let a_square: Element = Element {
        l0: 2144628324130663,
        l1: 596790797966485,
        l2: 912635275234964,
        l3: 713663780369466,
        l4: 1207365348681671
    };

    let res: Element = square(a);
    res_equals(res, a_square)
}