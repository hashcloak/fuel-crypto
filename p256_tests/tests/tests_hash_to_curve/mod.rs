use fuels::prelude::*;
use crate::utils::{
  helpers::{get_contract_methods, assert_xy, convert_from_montgomery}
};

mod success {
  use super::*;

// !!! Keeping the tests here as a reference, imports have not been checked

// // fn assert_fieldelement(a: FieldElement, expected_res: [u64; 4]) {
// //   assert_eq!(a.ls[0], expected_res[0]);
// //   assert_eq!(a.ls[1], expected_res[1]);
// //   assert_eq!(a.ls[2], expected_res[2]);
// //   assert_eq!(a.ls[3], expected_res[3]);
// // }

// // #[tokio::test]#[ignore]
// // async fn test_from_okm () {

// //   let (_methods, _id) = get_contract_methods().await;

// //   // random(2^384)
// //   // 29574121323020303933831581169207951122829468626121072655439219863093377468360436174282205068642494412975233236534840
// //   // big-endian [13845646450878251009, 10719928016004921607, 6631139461101160670, 14991082624209354397, 7557322358563246340, 13282407956253574712]

// //   // let data: [u64;6] = [13282407956253574712, 7557322358563246340, 14991082624209354397, 6631139461101160670, 10719928016004921607, 13845646450878251009];
// //   let data: [u8; 48] = [56, 6, 81, 186, 169, 151, 84, 184, 4, 145, 71, 11, 165, 0, 225, 104, 157, 126, 135, 118, 56, 6, 11, 208, 222, 136, 2, 227, 52, 138, 6, 92, 7, 57, 187, 227, 187, 213, 196, 148, 1, 0, 63, 246, 22, 158, 37, 192];

// //   let result = _methods
// //     .from_okm(data)
// //     .call().await.unwrap();

// //   // correct value according to reference repo:
// //   // 0xBC5BDAC732B6B32C0C76A01A486F2AAF0CE104CE7EE79FB2D9FAD9EE57DEF6E7
// //   // equals: 85197108567622674053253976229903765397140825897163024844039591489851386427111
// //   // digits [13572682451095302956, 898081210451831471, 928028283153915826, 15707106268107699943]

// //   assert_fieldelement(result.value, [15707106268107699943, 928028283153915826, 898081210451831471, 13572682451095302956]);
// // }

// // #[tokio::test]#[ignore]
// // async fn test_expand_msg () {
// //   let (_methods, _id) = get_contract_methods().await;

// //   let data = vec![97,98,99];
// //   let result = _methods
// //     .expand_message(data)
// //     .call().await.unwrap();

// //   let expected = Bits256 ([216, 204, 171, 35, 181, 152, 92, 206, 168, 101, 198, 201, 123, 110, 91, 131, 80, 231, 148, 230, 3, 180, 185, 121, 2, 245, 58, 138, 13, 96, 86, 21]);
// //   assert_eq!(result.value.0, expected);

// //   // second message
// //   // msg: b"abcdef0123456789",
// //   // uniform_bytes: &hex!("eff31487c770a893cfb36f912fbfcbff40d5661771ca4b2cb4eafe524333f5c1"),
// //   let data2 = vec![97, 98, 99, 100, 101, 102, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57];
// //   let result2 = _methods
// //     .expand_message(data2)
// //     .call().await.unwrap();

// //   // This test only works with DST equal to: "QUUX-V01-CS02-with-expander-SHA256-128"
// //   // let DST_prime: [u8; 39] = [81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116, 104, 45, 101, 120, 112, 97, 110, 100, 101, 114, 45, 83, 72, 65, 50, 53, 54, 45, 49, 50, 56, 38];
  
// //   // let expected2 = Bits256([239, 243, 20, 135, 199, 112, 168, 147, 207, 179, 111, 145, 47, 191, 203, 255, 64, 213, 102, 23, 113, 202, 75, 44, 180, 234, 254, 82, 67, 51, 245, 193]);
// //   // assert_eq!(result2.value.0, expected2);

// // }

// // // TODO hash_to_field has to be debugged and fixed
// // #[tokio::test]#[ignore]
// // async fn test_hash_to_field() {
// //   let (_methods, _id) = get_contract_methods().await;

// //   struct TestVector {
// //     msg: Vec<u8>,
// //     p_x: FieldElement,
// //     p_y: FieldElement,
// //     u_0: FieldElement,
// //     u_1: FieldElement,
// //     q0_x: FieldElement,
// //     q0_y: FieldElement,
// //     q1_x: FieldElement,
// //     q1_y: FieldElement,
// //   }

// // // TestVector {
// // //   msg: b"abc",
// // //   p_x: hex!("0bb8b87485551aa43ed54f009230450b492fead5f1cc91658775dac4a3388a0f"),
// // //   p_y: hex!("5c41b3d0731a27a7b14bc0bf0ccded2d8751f83493404c84a88e71ffd424212e"),
// // //   u_0: hex!("afe47f2ea2b10465cc26ac403194dfb68b7f5ee865cda61e9f3e07a537220af1"),
// // //   u_1: hex!("379a27833b0bfe6f7bdca08e1e83c760bf9a338ab335542704edcd69ce9e46e0"),
// // //   q0_x: hex!("5219ad0ddef3cc49b714145e91b2f7de6ce0a7a7dc7406c7726c7e373c58cb48"),
// // //   q0_y: hex!("7950144e52d30acbec7b624c203b1996c99617d0b61c2442354301b191d93ecf"),
// // //   q1_x: hex!("019b7cb4efcfeaf39f738fe638e31d375ad6837f58a852d032ff60c69ee3875f"),
// // //   q1_y: hex!("589a62d2b22357fed5449bc38065b760095ebe6aeac84b01156ee4252715446e"),


// //   let vector1: TestVector = TestVector { 
// //     msg: vec![97,98,99], 
// //     p_x: FieldElement{ls: [9760948305482254863, 5273691893279789413, 4527611864262133003, 844627740724632228]},
// //     p_y: FieldElement{ls: [12145770588654543150, 9750847572926286980, 12775516694752652589, 6647792232841226151]},
// //     // first fieldelement should be:
// //     u_0: FieldElement{ls: [11474617306762578673, 10051857245547636254, 14710634624562028470, 12674395089602151525]},
// //     // second:
// //     u_1: FieldElement{ls: [355165799953876704, 13806404278462796839, 8925185093799233376, 4006558263084318319]},
// //     q0_x: FieldElement{ls: [8245103793509288776, 7845454890279372487,13192191604878931934, 5915949860614556745]}, 
// //     q0_y: FieldElement{ls: [3837913169617567439, 14525823833306047554, 17040321694184184214, 8741509203355699915]}, 
// //     q1_x: FieldElement{ls: [3674762227143116639, 6545563691401106128, 11489685293311925559, 115823331987417843]}, 
// //     q1_y: FieldElement{ls: [1544422570455286894, 675186360566958849, 15367579092470052704, 6384524078822414334]} 
// //   };

  
// //   let hash2field = _methods
// //     .hash_to_field(vector1.msg)
// //     .tx_params(TxParameters::default().set_gas_limit(100_000_000_000))
// //     .call().await.unwrap();

// //   let logs = hash2field.get_logs().unwrap();
// //   println!("{:#?}", logs);
// //   /*
// // [
// //     "Bits256([74, 151, 151, 159, 152, 135, 73, 68, 128, 177, 121, 235, 244, 54, 25, 242, 43, 215, 199, 145, 250, 236, 109, 31, 93, 198, 191, 106, 247, 218, 120, 34])",
// //     "Bits256([239, 145, 238, 93, 213, 160, 16, 174, 98, 67, 178, 255, 92, 45, 3, 185, 170, 44, 40, 226, 162, 105, 211, 36, 51, 255, 166, 248, 152, 179, 188, 215])",
// //     "Bits256([65, 241, 157, 161, 18, 14, 79, 142, 179, 18, 235, 177, 114, 43, 158, 145, 41, 51, 77, 35, 177, 218, 196, 67, 28, 184, 16, 176, 90, 8, 177, 144])",
// //     "[74, 151, 151, 159, 152, 135, 73, 68, 128, 177, 121, 235, 244, 54, 25, 242, 43, 215, 199, 145, 250, 236, 109, 31, 93, 198, 191, 106, 247, 218, 120, 34, 239, 145, 238, 93, 213, 160, 16, 174, 98, 67, 178, 255, 92, 45, 3, 185]",
// //     "[170, 44, 40, 226, 162, 105, 211, 36, 51, 255, 166, 248, 152, 179, 188, 215, 65, 241, 157, 161, 18, 14, 79, 142, 179, 18, 235, 177, 114, 43, 158, 145, 41, 51, 77, 35, 177, 218, 196, 67, 28, 184, 16, 176, 90, 8, 177, 144]",
// // ]
// // [
// //     FieldElement {
// //         ls: [
// //             1728813152584433580,
// //             1780581177103270634,
// //             8480265857755027571,
// //             1974814188125222243,
// //         ],
// //     },
// //     FieldElement {
// //         ls: [
// //             2011117570769239119,
// //             139850257455497610,
// //             3924352572349401321,
// //             8445929672427632768,
// //         ],
// //     },
// // ]
// //   */

// //   println!("{:#?}", hash2field.value);
// //   assert_xy(hash2field.value[0].clone(), hash2field.value[1].clone(), vector1.u_0.ls, vector1.u_1.ls);
// // }
}