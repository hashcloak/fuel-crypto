library tests_vect_subfunctions;

use ::fields::*;
use ::vect::*;
use ::test_helpers::*;
use std::logging::log;
use std::{assert::assert, vec::Vec};
use ::consts::*;

pub fn vect_subfunctions_tests() -> bool {
    // NOTE: Don't run all at the same time, because will run out of gas

    // add_mod_n tests. They have the same test values as add_fp
    // which should be correct, but of course add_mod_n should do more
    // assert(test_add_zero_to_zero_addn());
    // assert(test_add_zero_to_random_addn());
    // assert(test_add_random_to_small_addn());

    // assert(test_mul_mont_n_by_zero());
    // assert(test_mul_mont_n_zero_by_one());
    // assert(test_mul_mont_n_one_by_one());
    // assert(test_mul_mont_n_random_by_one());
    // assert(test_mul_mont_n_random_by_random());
    assert(test_mont_mul_partial());

    // these tests are the same as for sub_fp and work. But they should support more values of n, thus more tests have to be added
    // assert(test_sub_zero_from_zero_subn());
    // assert(test_sub_zero_from_random_subn());
    // assert(test_sub_random_from_zero_subn());
    // assert(test_sub_random_from_small_subn());
    // assert(test_sub_2_randoms_subn());
    // assert(test_sub_2_randoms_reverse_subn());

    //  assert(tests_redc_mont());
    true
}

fn get_test_vectors() -> (Vec<u64>, Vec<u64>) {
    let mut zero_vec = ~Vec::new::<u64>();
    zero_vec.push(0);
    zero_vec.push(0);
    zero_vec.push(0);
    zero_vec.push(0);
    zero_vec.push(0);
    zero_vec.push(0);

    let mut p_vec = ~Vec::new::<u64>();
    p_vec.push(0xb9feffffffffaaab);
    p_vec.push(0x1eabfffeb153ffff);
    p_vec.push(0x6730d2a0f6b0f624);
    p_vec.push(0x64774b84f38512bf);
    p_vec.push(0x4b1ba7b6434bacd7);
    p_vec.push(0x1a0111ea397fe69a);

    (zero_vec, p_vec)
}

fn test_mul_mont_n_by_zero() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();

    let res = mul_mont_n(zero_vec, zero_vec, p_vec, P0, 6);
    equals_vec(res, zero_vec, 6);
    true
}

fn get_one_vec() -> Vec<u64> {
    let mut one_vec = ~Vec::new::<u64>();
    one_vec.push(1);
    one_vec.push(0);
    one_vec.push(0);
    one_vec.push(0);
    one_vec.push(0);
    one_vec.push(0);
    one_vec
}

fn test_mul_mont_n_zero_by_one() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();
    let one_vec = get_one_vec();

    let res = mul_mont_n(zero_vec, one_vec, p_vec, P0, 6);
    equals_vec(res, zero_vec, 6);
    true
}

fn test_mul_mont_n_one_by_one() -> bool {
    let(_, p_vec) = get_test_vectors();
    let one_vec = get_one_vec();

    let res = mul_mont_n(one_vec, one_vec, p_vec, P0, 6);
    equals_vec(res, one_vec, 6);
    //print_vec(res);
    // print_vec(one_vec);
    true
}

fn test_mul_mont_n_random_by_one() -> bool {
    let(_, p_vec) = get_test_vectors();
    //28700440645560700010247999350858186656965165501286811298915027297835050275063552879691348405696442872566701753802544
    let mut r_vec = ~Vec::new::<u64>();
    r_vec.push(0x54439c4ae7869f30); //6071868568151433008
    r_vec.push(0xa7fdefad55c032ba); //12105094901188801210
    r_vec.push(0x21282f739c0a15e7); //2389211775905699303
    r_vec.push(0x6cc7a6e8c38430ff); //7838417195104481535
    r_vec.push(0x50db69783b321139); //5826366508043997497
    r_vec.push(0xba78745dadd17a93); //13436617433956842131
    let one_vec = get_one_vec();

    let res = mul_mont_n(r_vec, one_vec, p_vec, P0, 6);
    // print_vec(res);
    /*

    */
    // let b = equals_vec(res, r_vec, 6);
    // log(b);
    let mut i = 0;
    while i < 6 {
        assert(unpack_or_0(res.get(i)) == unpack_or_0(r_vec.get(i)));
        i += 1;
    }
    true
}

fn test_mul_mont_n_random_by_random() -> bool {
    let(_, p_vec) = get_test_vectors();
    //28700440645560700010247999350858186656965165501286811298915027297835050275063552879691348405696442872566701753802544
    let mut r1_vec = ~Vec::new::<u64>();
    r1_vec.push(6071868568151433008);
    r1_vec.push(12105094901188801210);
    r1_vec.push(2389211775905699303);
    r1_vec.push(7838417195104481535);
    r1_vec.push(5826366508043997497);
    r1_vec.push(13436617433956842131);
    //845585313160814446158446407435059620350609671735802091463220815564059525214346533476776130630310896229502998576879
    let mut r2_vec = ~Vec::new::<u64>();
    r2_vec.push(16964885827015180015);
    r2_vec.push(12035734743809705289);
    r2_vec.push(10517060043363161601);
    r2_vec.push(1119606639881808286);
    r2_vec.push(2211903887497377980);
    r2_vec.push(395875676649998273);

    //1128153310087946582770541547041113021655162062067663357733024411531633319713239944238808860915038256082620363451095
    //[4793585148327242455, 2837967030551533581, 1626660158106644623,
    //15384342728939744618, 1826521055323312182, 528164867630647501]

    // mult by p0
    //241244430210532575562827373868655963084727802841779217074318408842127082994632785925923353131362216879147315212775676243090892648326992525470904388378004276874316175983655739522130737118499414971959740231422333803704862166384557102941841719958128272
    // mod p
    //1233002344306172478209354248697859329250780126726480993298462574958424022710616415994206080732967265541051783400711
    //[1734233419737550087, 7827676449723675145, 5835727259298429301, 3992373620040751347, 13994230039556723943, 577251792061825638]
    let mut res_vec = ~Vec::new::<u64>();
    res_vec.push(0x42863c4b7ea22ad7); //4793585148327242455
    res_vec.push(0x27627bfa644b580d); //2837967030551533581
    res_vec.push(0x16930ecb9e3a308f); //1626660158106644623
    res_vec.push(0xd5802a33c5512d6a); //15384342728939744618
    res_vec.push(0x19591b38f5515036); //1826521055323312182
    res_vec.push(0x7546b2615f748cd); //528164867630647501
    let res = mul_mont_n(r1_vec, r2_vec, p_vec, P0, 6);
    print_vec(res);
    /*
10466566815393401694
14579313370948138685
11816151785009594293
7246864926219872143
15908820384664990112
328568623818015453

blst impl
3517150968681791168
13347192682519393737
4541454005160136609
16590274403525876995
17086414653262144931
16572945458942657492
    */
    // equals_vec(res, res_vec, 6);

    true
}

fn test_mont_mul_partial() -> bool {
    let(_, p_vec) = get_test_vectors();

    let mut intermediate_res_vec = ~Vec::new::<u64>();
    intermediate_res_vec.push(8042921339150017446);
    intermediate_res_vec.push(4899742317194411181);
    intermediate_res_vec.push(11922910400151252689);
    intermediate_res_vec.push(7736564210120511729);
    intermediate_res_vec.push(10892349319971706476);
    intermediate_res_vec.push(542573957820843489);

    let mut ONE: Vec<u64> = ~Vec::new::<u64>();
    ONE.push(0x1);
    ONE.push(0);
    ONE.push(0);
    ONE.push(0);
    ONE.push(0);
    ONE.push(0);

    let res = mul_mont_n(intermediate_res_vec, ONE, p_vec, P0, 6);
    print_vec(res);

    /*
Should be
16494539950903960225
6909894500484332639
10854278113294925999
10279541547892741855
12499445441687670930
440910865060157199

//Current output is:
4899742317194411181
11922910400151252689
7736564210120511729
10892349319971706476
542573957820843489
0
This is almost the input vector...
*/
    true
}

fn test_add_zero_to_zero_addn() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();

    let res = add_mod_n(zero_vec, zero_vec, p_vec, 6);
    equals_vec(res, zero_vec, 6);
    true
}

fn test_add_zero_to_random_addn() -> bool {
    let mut random_vec = ~Vec::new::<u64>();
    random_vec.push(0x3e2528903ca1ef86);
    random_vec.push(0x270fd67a03bf9e0a);
    random_vec.push(0xdc70c19599cb699e);
    random_vec.push(0xebefda8057d5747a);
    random_vec.push(0xcf20e11f0b1c323);
    random_vec.push(0xe979cbf960fe51d);
    let(zero_vec, p_vec) = get_test_vectors();

    let res = add_mod_n(random_vec, zero_vec, p_vec, 6);
    equals_vec(res, random_vec, 6);
    true
}

fn test_add_random_to_small_addn() -> bool {
    let mut small_vec = ~Vec::new::<u64>();
    small_vec.push(0x1);
    small_vec.push(0x2);
    small_vec.push(0x3);
    small_vec.push(0x4);
    small_vec.push(0x5);
    small_vec.push(0x6);
    let mut random_vec = ~Vec::new::<u64>();
    random_vec.push(0x3e2528903ca1ef86);
    random_vec.push(0x270fd67a03bf9e0a);
    random_vec.push(0xdc70c19599cb699e);
    random_vec.push(0xebefda8057d5747a);
    random_vec.push(0xcf20e11f0b1c323);
    random_vec.push(0xe979cbf960fe51d);
    let mut res_vec = ~Vec::new::<u64>();
    res_vec.push(4478030004447473543);
    res_vec.push(2814704111667093004);
    res_vec.push(15884408734010272161);
    res_vec.push(17001047363111187582);
    res_vec.push(932823543034528552);
    res_vec.push(1051481384684610851);

    let(_, p_vec) = get_test_vectors();

    let res = add_mod_n(small_vec, random_vec, p_vec, 6);
    equals_vec(res, res_vec, 6);
    true
}

fn test_sub_zero_from_zero_subn() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();

    let res = sub_mod_n(zero_vec, zero_vec, p_vec, 6);
    equals_vec(res, zero_vec, 6);
    true
}

fn test_sub_zero_from_random_subn() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();

    let mut random_vec = ~Vec::new::<u64>();
    random_vec.push(0x3e2528903ca1ef86);
    random_vec.push(0x270fd67a03bf9e0a);
    random_vec.push(0xdc70c19599cb699e);
    random_vec.push(0xebefda8057d5747a);
    random_vec.push(0xcf20e11f0b1c323);
    random_vec.push(0xe979cbf960fe51d);

    let res = sub_mod_n(random_vec, zero_vec, p_vec, 6);
    equals_vec(res, random_vec, 6);
    true
}

fn test_sub_random_from_zero_subn() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();

    let mut random_vec = ~Vec::new::<u64>();
    random_vec.push(13059245463466299169);
    random_vec.push(17774603101077980186);
    random_vec.push(889990675562875390);
    random_vec.push(12771390643166271294);
    random_vec.push(5370893444473505192);
    random_vec.push(599972797727911687);

    let res = sub_mod_n(zero_vec, random_vec, p_vec, 6);
    // p-r (is the same as 0-r mod p)
    let mut res_vec = ~Vec::new::<u64>();
    res_vec.push(343185552611564426);
    res_vec.push(2882282484148780005);
    res_vec.push(6545683898001206309);
    res_vec.push(12914691390957992833);
    res_vec.push(41210333997197102);
    res_vec.push(1273825819919628179);
    equals_vec(res, res_vec, 6);
    true
}

fn test_sub_random_from_small_subn() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();
    // 1 + 2 *2^64 + 3*2^128 + 4 * 2^192 + 5 * 2^256 + 6 * 2^320
    //12815922215525460494949090683203893664759190466124902882004963575055114655935967659265637031608321
    let mut small_vec = ~Vec::new::<u64>();
    small_vec.push(1);
    small_vec.push(2);
    small_vec.push(3);
    small_vec.push(4);
    small_vec.push(5);
    small_vec.push(6);

    //1281534117852017820269267861584320258656990227317793864009951923807317297699607442944495077621627898376663719366433
    let mut r_vec = ~Vec::new::<u64>();
    r_vec.push(13059245463466299169);
    r_vec.push(17774603101077980186);
    r_vec.push(889990675562875390);
    r_vec.push(12771390643166271294);
    r_vec.push(5370893444473505192);
    r_vec.push(599972797727911687);

    let mut res_vec = ~Vec::new::<u64>();
    res_vec.push(343185552611564427);
    res_vec.push(2882282484148780007);
    res_vec.push(6545683898001206312);
    res_vec.push(12914691390957992837);
    res_vec.push(41210333997197107);
    res_vec.push(1273825819919628185);

    //result should be 2720875437369649585964444179677044392848983275825107686081296678441617234796193996553307207443355424926867584801675
    let res = sub_mod_n(small_vec, r_vec, p_vec, 6);
    equals_vec(res, res_vec, 6);

    true
}

fn get_r1_r2_vecs() -> (Vec<u64>, Vec<u64>) {
    //a = 1636725880549280067486622211868244649555599468607198938781220718077581339058902572863029175226410795172800087248680
    //[10587454305359941416, 4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194]
    let mut r1_vec = ~Vec::new::<u64>();
    r1_vec.push(10587454305359941416);
    r1_vec.push(4615625447881587853);
    r1_vec.push(9368308553698906485);
    r1_vec.push(9494054596162055604);
    r1_vec.push(377309137954328098);
    r1_vec.push(766262085408033194);

    //b = 633982047616931537296775994873240773075794315607478597677958352919546237170580686209956468014669319291596219488262
    //[13403040667047958534, 405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174]
    let mut r2_vec = ~Vec::new::<u64>();
    r2_vec.push(13403040667047958534);
    r2_vec.push(405585388298286396);
    r2_vec.push(7295341050629342949);
    r2_vec.push(1749456428444609784);
    r2_vec.push(1856600841951774635);
    r2_vec.push(296809876162753174);

    (r1_vec, r2_vec)
}

fn test_sub_2_randoms_subn() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();
    let(r1_vec, r2_vec) = get_r1_r2_vecs();

    //res =
    //1002743832932348530189846216995003876479805152999720341103262365158035101888321886653072707211741475881203867760418
    //[15631157712021534498, 4210040059583301456, 2072967503069563536, 7744598167717445820, 16967452369712105079, 469452209245280019]
    let mut res_vec = ~Vec::new::<u64>();
    res_vec.push(15631157712021534498);
    res_vec.push(4210040059583301456);
    res_vec.push(2072967503069563536);
    res_vec.push(7744598167717445820);
    res_vec.push(16967452369712105079);
    res_vec.push(469452209245280019);

    let res = sub_mod_n(r1_vec, r2_vec, p_vec, 6);
    equals_vec(res, res_vec, 6);

    true
}

fn test_sub_2_randoms_reverse_subn() -> bool {
    let(zero_vec, p_vec) = get_test_vectors();
    let(r1_vec, r2_vec) = get_r1_r2_vecs();

    //res =
    //-1002743832932348530189846216995003876479805152999720341103262365158035101888321886653072707211741475881203867760418
    // => mod p
    //2999665722289318863227943608740900280077077666939287544228795770965996548602515977789614921917274188156690404799369
    //[16218017377765880713, 16446845525643458734, 5362707070494518163, 17941483866406818307, 6891395482468148831, 1404346408402259846]
    let mut res_vec = ~Vec::new::<u64>();
    res_vec.push(16218017377765880713);
    res_vec.push(16446845525643458734);
    res_vec.push(5362707070494518163);
    res_vec.push(17941483866406818307);
    res_vec.push(6891395482468148831);
    res_vec.push(1404346408402259846);

    let res = sub_mod_n(r2_vec, r1_vec, p_vec, 6);
    equals_vec(res, res_vec, 6);

    true
}

fn tests_redc_mont() -> bool {
    assert(test_redc_mont_n_small());
    // assert(test_redc_mont_n_p());
    // assert(test_redc_mont_n_random());
    // assert(test_redc_mont_n_random_large());

    true
}
fn test_redc_mont_n_small() -> bool {
    let mut a_vec: Vec<u64> = ~Vec::new::<u64>();
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(10);
    let mut res_vec: Vec<u64> = ~Vec::new::<u64>();
    res_vec.push(0);
    res_vec.push(0);
    res_vec.push(0);
    res_vec.push(0);
    res_vec.push(0);
    res_vec.push(10);
    let test_vec = get_test_vectors();
    let res = redc_mont_n(a_vec, test_vec.1, 0x89f3fffcfffcfffd, 6);
    equals_vec(res, res_vec, 6);
    true
}

fn test_redc_mont_n_p() -> bool {
    let mut p_vec = ~Vec::new::<u64>();
    p_vec.push(0xb9feffffffffaaab);
    p_vec.push(0x1eabfffeb153ffff);
    p_vec.push(0x6730d2a0f6b0f624);
    p_vec.push(0x64774b84f38512bf);
    p_vec.push(0x4b1ba7b6434bacd7);
    p_vec.push(0x1a0111ea397fe69a);
    p_vec.push(0);
    p_vec.push(0);
    p_vec.push(0);
    p_vec.push(0);
    p_vec.push(0);
    p_vec.push(0);
    let test_vec = get_test_vectors();
    let res = redc_mont_n(p_vec, test_vec.1, 0x89f3fffcfffcfffd, 6);
    //equals_vec(res, get_test_vectors().0, 6);
    print_vec(res);
    true
}

fn test_redc_mont_n_random() -> bool {
    /*
    a_vec = 3696765165377537992548071770426871989328256175267415194498929704185983294358703155983657203868185085593368583538232
          = [1730705806359781376, 10719928016004921607, 6631139461101160670, 14991082624209354397, 7557322358563246340, 13282407956253574712]
          (using GP Pari)
    a_vec mod P = 3696765165377537992548071770426871989328256175267415194498929704185983294358703155983657203868185085593368583538232
                = [1730705806359781376, 10719928016004921607, 6631139461101160670, 14991082624209354397, 7557322358563246340, 13282407956253574712]
    */
    let mut a_vec = ~Vec::new::<u64>();

    a_vec.push(13282407956253574712);
    a_vec.push(7557322358563246340);
    a_vec.push(14991082624209354397);
    a_vec.push(6631139461101160670);
    a_vec.push(10719928016004921607);
    a_vec.push(1730705806359781376);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    let mut result = ~Vec::new::<u64>();
    result.push(13282407956253574712);
    result.push(7557322358563246340);
    result.push(14991082624209354397);
    result.push(6631139461101160670);
    result.push(10719928016004921607);
    result.push(1730705806359781376);

    let test_vec = get_test_vectors();
    let res = redc_mont_n(a_vec, test_vec.1, 0x89f3fffcfffcfffd, 6);
    print_vec(res);
    //equals_vec(res, result, 6);
    true
}

fn test_redc_mont_n_random_large() -> bool {
    /*
    a = random({2^384}) = 21380795309672530537064108666460268360580493838230277925224860893329212391422460281305468429766194371347271041959862
                    = [10009796384580774444, 9837491998535547791, 12861376030615125811, 15982738825684268908, 17984324540840297179, 13142370077570254774]

    a mod p = 1368747533564193569975159537780747577796079738535238498564570212709054138968270959092030284121116051157799679160927
            = [640803296343075113, 1223717179891587930, 13558174375960666486, 15697854105282963640, 6933616983254254301, 1470447218309591647]

                

    */
    let mut a_vec = ~Vec::new::<u64>();
    a_vec.push(13142370077570254774);
    a_vec.push(17984324540840297179);
    a_vec.push(15982738825684268908);
    a_vec.push(12861376030615125811);
    a_vec.push(9837491998535547791);
    a_vec.push(10009796384580774444);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);
    a_vec.push(0);

    let mut result = ~Vec::new::<u64>();
    result.push(1470447218309591647);
    result.push(6933616983254254301);
    result.push(15697854105282963640);
    result.push(13558174375960666486);
    result.push(1223717179891587930);
    result.push(640803296343075113);

    let test_vec = get_test_vectors();
    let res = redc_mont_n(a_vec, test_vec.1, 0x89f3fffcfffcfffd, 6);
    //equals_vec(res, result, 6);
    print_vec(res);
    true
}
