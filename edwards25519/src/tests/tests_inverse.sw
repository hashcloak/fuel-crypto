// library tests_inverse;

// use ::field_element::*;
// use std::assert::assert;
// use ::test_helpers::*;
// use std::u128::*;

// pub fn tests_inverse() -> bool {
//     assert(test_inverse_random());
//     true
// }

// fn test_inverse_random() -> bool {
//     /*
// 4521863078758786565316692829643046466943720546816241094731251542329584501189
// [715325916561861, 1128975921026318, 1696955067652624, 2081297221826529, 175872643896950]

// res 
// 21685099821915697185699787072152716570859124738499628703633803656742289717999
// [2187613694507759, 1614434677729781, 1594711943325299, 378203143193209, 843416921835783]
//     */
//     let a = Element {
//         l0: 715325916561861,
//         l1: 1128975921026318,
//         l2: 1696955067652624,
//         l3: 2081297221826529,
//         l4: 175872643896950
//     };
//     let res: Element = inverse(a);
//     let res_check = Element {
//         l0: 2187613694507759,
//         l1: 1614434677729781,
//         l2: 1594711943325299,
//         l3: 378203143193209,
//         l4: 843416921835783
//     };
//     // print_el(res);
//     //res_equals(res, res_check);
//     true
// }