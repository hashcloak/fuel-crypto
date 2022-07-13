script;

dep vect;
dep fields;
dep test_helpers;
dep consts;

use std::{assert::assert, option::*, u128::*, vec::Vec};
use ::fields::*;
use ::vect::*;
use ::consts::*;
use ::test_helpers::*;
use std::logging::log;

fn main() {
    // assert(fp_tests());
    // assert(fp2_tests());
    // assert(test_multiply_wrap());
    // assert(test_mac());
    assert(vect_subfunctions_tests());
}

fn fp_tests() -> bool {
    // Don't run all tests at the same time...

    // assert(test_add_fp());
    // assert(test_sub_fp());
    // assert(test_helpers());
    assert(tests_mul_by_3_fp());
    assert(tests_mul_by_8_fp());
    assert(test_lshift_p());

    true
}

fn fp2_tests() -> bool {
    assert(tests_add_fp2());
    assert(tests_sub_fp2());
    true
}

fn vect_subfunctions_tests() -> bool {
    // NOTE: Don't run all at the same time, because will run out of gas

    // add_mod_n tests. They have the same test values as add_fp
    // which should be correct, but of course add_mod_n should do more
    // assert(test_add_zero_to_zero_addn());
    // assert(test_add_zero_to_random_addn());
    assert(test_add_random_to_small_addn());

    // assert(test_mul_mont_n_by_zero());
    // assert(test_mul_mont_n_zero_by_one());
    // assert(test_mul_mont_n_one_by_one());
    assert(test_mul_mont_n_random_by_one());
    assert(test_mul_mont_n_random_by_random());

    // these tests are the same as for sub_fp and work. But they should support more values of n, thus more tests have to be added
    // assert(test_sub_zero_from_zero_subn());
    // assert(test_sub_zero_from_random_subn());
    // assert(test_sub_random_from_zero_subn());
    // assert(test_sub_random_from_small_subn());
    assert(test_sub_2_randoms_subn());
    assert(test_sub_2_randoms_reverse_subn());
    true
}

fn tests_add_fp2() -> bool {
    // the function should add the "real" and "imaginary" part separately
    //2094911124722355591130592080039857597898930618341226282859888392249028304430218244612311046228146839310359642074358
    let r_1 = vec384 {
        ls: [14795151457364307190,
        6622185142386025417, 17709159039044576520, 1719961663313476946, 4148264363906786574, 980769587779429096]
    };
    //1854013830343626212433083622699305309002946726548085159596712876339371488002438401231777242990713512722976854546804
    let i_1 = vec384 {
        ls: [8306319196692453748,
        10328470218072223240, 3451314819045096133, 17542580433704256157, 9684937745078445131, 867989271079206780]
    };
    let a_1 = vec384x {
        r: r_1,
        i: i_1,
    };

    //4045376134997543930094609209908421750094711219583275861031869422142617896643947085410916305865237922018531567230463
    let r_2 = vec384 {
        ls: [16448140995118783999,
        9520526689676604696, 7916863578364318753, 8691145487628551970, 16531338352426028355, 1893914179705411585]
    };
    //4250620933501754476426212648635705132171856148319059449262917285281574574065816436709319684883958930577072278499582
    let i_2 = vec384 {
        ls: [1139524850979729662,
        10226030227531743340, 16078343496594203218, 16066350528929326807, 17232578759082026236, 1990003151713484304]
    };
    let a_2 = vec384x {
        r: r_2,
        i: i_2,
    };

    let res = add_fp2(a_1, a_2);

    // real part
    //2137877704498232127807411464212375191436759017985494258559699678267614550583327465580539722964369097290996936745034
    // i part
    //2102225208623713295441506445599106284617920054928136723527572025496914411577416973498409298745656779262154860486599
    equals_vec384(res.r, vec384 {
        ls: [17840861436405227594, 13932570320545421538, 18190348043844813573, 3171769190527316405, 15267498937862112634, 1000885149837300815]
    });
    equals_vec384(res.i, vec384 {
        ls: [14490157105303871431, 18344358934086758004, 12093983742075217651, 7922848928509318837, 3058668651980217457, 984193805145151219]
    });
    true
}

fn tests_sub_fp2() -> bool {
    // the function should subtract the "real" and "imaginary" part separately
    //2094911124722355591130592080039857597898930618341226282859888392249028304430218244612311046228146839310359642074358
    let r_1 = vec384 {
        ls: [14795151457364307190,
        6622185142386025417, 17709159039044576520, 1719961663313476946, 4148264363906786574, 980769587779429096]
    };
    //1854013830343626212433083622699305309002946726548085159596712876339371488002438401231777242990713512722976854546804
    let i_1 = vec384 {
        ls: [8306319196692453748,
        10328470218072223240, 3451314819045096133, 17542580433704256157, 9684937745078445131, 867989271079206780]
    };
    let a_1 = vec384x {
        r: r_1,
        i: i_1,
    };

    //4045376134997543930094609209908421750094711219583275861031869422142617896643947085410916305865237922018531567230463
    let r_2 = vec384 {
        ls: [16448140995118783999,
        9520526689676604696, 7916863578364318753, 8691145487628551970, 16531338352426028355, 1893914179705411585]
    };
    //4250620933501754476426212648635705132171856148319059449262917285281574574065816436709319684883958930577072278499582
    let i_2 = vec384 {
        ls: [1139524850979729662,
        10226030227531743340, 16078343496594203218, 16066350528929326807, 17232578759082026236, 1990003151713484304]
    };
    let a_2 = vec384x {
        r: r_2,
        i: i_2,
    };

    let res = sub_fp2(a_1, a_2);
    //real
    //2051944544946479054453772695867340004361102218696958307160077106230442058277109023644082369491924581329722347403682
    //i
    //1605802452063539129424660799799504333387973398168033595665853727181828564427459828965145187235770246183798848607009
    equals_vec384(res.r, vec384 {
        ls: [11749441478323386786, 17758544037936180912, 17227970034244339466, 268154136099637487, 11475773863661012130, 960654025721557376]
    });
    equals_vec384(res.i, vec384 {
        ls: [2122481288081036065, 2312581502057688476, 13255389969724526231, 8715567865189641860, 16311206838176672806, 751784737013262341]
    });
    true
}

fn test_helpers() -> bool {
    assert(test_not());
    assert(tests_subtract_wrap());
    assert(tests_sbb());
    assert(tests_adc());
    assert(test_neg());
    assert(test_subtract_p());
    true
}

fn test_not() -> bool {
    let res = not(18417751708719972248);
    assert(res == 28992364989579367);
    true
}

fn tests_subtract_wrap() -> bool {
    let mut res = subtract_wrap(U128 {
        lower: 100, upper: 0
    },
    U128 {
        lower: 80, upper: 0
    });
    assert(res.lower == 20);
    assert(res.upper == 0);

    res = subtract_wrap(U128 {
        lower: 100, upper: 0
    },
    U128 {
        lower: 230, upper: 0
    });
    let res_should_be = ~U128::max() - U128 {
        lower: 130, upper: 0
    };
    // 2^128 - 230 = 340282366920938463463374607431768211226
    // [18446744073709551486, 18446744073709551615]
    assert(res.lower == 18446744073709551486);
    assert(res.upper == 18446744073709551615);
    true
}

fn tests_sbb() -> bool {
    // 0-0-0 should give (0,0)
    let mut res = sbb(0, 0, 0);
    assert(res.0 == 0);
    assert(res.1 == 0);

    // 0-1-0 should give (2^64 -1, 1)
    res = sbb(0, 1, 0);
    assert(res.0 == ~u64::max());
    assert(res.1 == 1);

    // 0-1-1 should give (2^64 -2, 1)
    res = sbb(0, 1, 1);
    assert(res.0 == ~u64::max() - 1);
    assert(res.1 == 1);

    // a-0-1 should give (a-1, 0)
    let a = 435983458;
    res = sbb(a, 0, 1);
    assert(res.0 == a - 1);
    assert(res.1 == 0);
    true
}

fn tests_adc() -> bool {
    assert(test_adc_random());
    assert(test_adc_random_with_carry());
    true
}

fn test_adc_random() -> bool {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let res: (u64, u64) = adc(a, b, 0);
    let a_plus_b: (u64, u64) = (1400544309406770619, 1);

    assert(res.0 == a_plus_b.0);
    assert(res.1 == a_plus_b.1);
    true
}

fn test_adc_random_with_carry() -> bool {
    let a = 9837491998535547791;
    let b = 10009796384580774444;
    let res: (u64, u64) = adc(a, b, 1);
    let a_plus_b_and_carry: (u64, u64) = (1400544309406770620, 1);

    assert(res.0 == a_plus_b_and_carry.0);
    assert(res.1 == a_plus_b_and_carry.1);
    true
}

fn test_subtract_p() -> bool {
    assert(test_subtract_p_smaller());
    assert(test_subtract_p_larger());
    true
}

fn test_subtract_p_smaller() -> bool {
    let a_smaller_than_p = vec384 {
        ls: [13402431016077863508,
        2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    };
    let res = subtract_p(a_smaller_than_p, BLS12_381_P);
    equals_vec384(res, a_smaller_than_p);
    true
}

fn test_subtract_p_larger() -> bool {
    // p+200
    let a_larger_than_p = vec384 {
        ls: [13402431016077863795,
        2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    };
    let res = subtract_p(a_larger_than_p, BLS12_381_P);
    equals_vec384(res, vec384 {
        ls: [200, 0, 0, 0, 0, 0]
    });
    true
}

fn test_add_fp() -> bool {
    assert(test_add_zero_to_zero());
    assert(test_add_zero_to_random());
    assert(test_add_random_to_zero());
    assert(test_add_random_to_small());
    assert(test_add_larger_than_p());
    assert(test_add_2_randoms());
    true
}

fn test_add_zero_to_zero() -> bool {
    let res: vec384 = add_fp(ZERO, ZERO);
    equals_vec384(res, ZERO);
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

    let res = mul_mont_n(zero_vec, zero_vec, p_vec, 1, 6);
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

    let res = mul_mont_n(zero_vec, one_vec, p_vec, 1, 6);
    equals_vec(res, zero_vec, 6);
    true
}

fn test_mul_mont_n_one_by_one() -> bool {
    let(_, p_vec) = get_test_vectors();
    let one_vec = get_one_vec();

    let res = mul_mont_n(one_vec, one_vec, p_vec, 1, 6);
    equals_vec(res, one_vec, 6);
    true
}

fn test_mul_mont_n_random_by_one() -> bool {
    let(_, p_vec) = get_test_vectors();
    //28700440645560700010247999350858186656965165501286811298915027297835050275063552879691348405696442872566701753802544
    let mut r_vec = ~Vec::new::<u64>();
    r_vec.push(0x54439c4ae7869f30);
    r_vec.push(0xa7fdefad55c032ba);
    r_vec.push(0x21282f739c0a15e7);
    r_vec.push(0x6cc7a6e8c38430ff);
    r_vec.push(0x50db69783b321139);
    r_vec.push(0xba78745dadd17a93);
    let one_vec = get_one_vec();

    let res = mul_mont_n(r_vec, one_vec, p_vec, 1, 6);
    equals_vec(res, r_vec, 6);
    true
}

fn test_mul_mont_n_random_by_random() -> bool {
    let(_, p_vec) = get_test_vectors();
    //28700440645560700010247999350858186656965165501286811298915027297835050275063552879691348405696442872566701753802544
    let mut r1_vec = ~Vec::new::<u64>();
    r1_vec.push(0x54439c4ae7869f30);
    r1_vec.push(0xa7fdefad55c032ba);
    r1_vec.push(0x21282f739c0a15e7);
    r1_vec.push(0x6cc7a6e8c38430ff);
    r1_vec.push(0x50db69783b321139);
    r1_vec.push(0xba78745dadd17a93);
    //845585313160814446158446407435059620350609671735802091463220815564059525214346533476776130630310896229502998576879
    let mut r2_vec = ~Vec::new::<u64>();
    r2_vec.push(0xeb6f61c69e4c7eef);
    r2_vec.push(0xa70784fb3f9ac549);
    r2_vec.push(0x91f41a633e1d9601);
    r2_vec.push(0xf89a44e9a52e99e);
    r2_vec.push(0x1eb242ddd39638bc);
    r2_vec.push(0x57e6ed499f0c7c1);

    //1128153310087946582770541547041113021655162062067663357733024411531633319713239944238808860915038256082620363451095
    let mut res_vec = ~Vec::new::<u64>();
    res_vec.push(0x42863c4b7ea22ad7);
    res_vec.push(0x27627bfa644b580d);
    res_vec.push(0x16930ecb9e3a308f);
    res_vec.push(0xd5802a33c5512d6a);
    res_vec.push(0x19591b38f5515036);
    res_vec.push(0x7546b2615f748cd);
    let res = mul_mont_n(r1_vec, r2_vec, p_vec, 1, 6);
    equals_vec(res, res_vec, 6);
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
    let (zero_vec, p_vec) = get_test_vectors();
    let (r1_vec, r2_vec) = get_r1_r2_vecs();

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
    let (zero_vec, p_vec) = get_test_vectors();
    let (r1_vec, r2_vec) = get_r1_r2_vecs();

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

fn test_add_zero_to_random() -> bool {
    let random = vec384 {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d]
    };
    let res: vec384 = add_fp(random, ZERO);
    equals_vec384(res, random);
    true
}

fn test_add_random_to_zero() -> bool {
    let random = vec384 {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d]
    };
    /*
4478030004447473542
2814704111667093002
15884408734010272158
17001047363111187578
932823543034528547
1051481384684610845
    */
    let res: vec384 = add_fp(ZERO, random);
    equals_vec384(res, random);
    true
}

fn test_add_random_to_small() -> bool {
    let small = vec384 {
        ls: [0x1,
        0x2, 0x3, 0x4, 0x5, 0x6]
    };
    let random = vec384 {
        ls: [0x3e2528903ca1ef86,
        0x270fd67a03bf9e0a, 0xdc70c19599cb699e, 0xebefda8057d5747a, 0xcf20e11f0b1c323, 0xe979cbf960fe51d]
    };
    let res: vec384 = add_fp(small, random);
    equals_vec384(res, vec384 {
        ls: [4478030004447473543, 2814704111667093004, 15884408734010272161, 17001047363111187582, 932823543034528552, 1051481384684610851]
    });
    true
}

fn test_add_larger_than_p() -> bool {
    /*
    4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559700
    +
    100
    is a little bit larger than p
    */
    //[13402431016077863508, 2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    let a = vec384 {
        ls: [13402431016077863508,
        2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    };

    let b = vec384 {
        ls: [100,
        0, 0, 0, 0, 0]
    };

    // should be 13
    let res: vec384 = add_fp(a, b);
    equals_vec384(res, vec384 {
        ls: [13, 0, 0, 0, 0, 0]
    });
    true
}

fn test_add_2_randoms() -> bool {
    //[4510245898505151773, 8849327944066866226, 11451510199254766964, 782624411996506985, 9666712539018543006, 17492304704872943]
    let random_1 = vec384 {
        ls: [4510245898505151773,
        8849327944066866226, 11451510199254766964, 782624411996506985, 9666712539018543006, 17492304704872943]
    };

    //[8877477209635348035, 16708328088811667500, 14014037299927741552, 1795070958963053268, 10606788931721547929, 841903545056265961]
    let random_2 = vec384 {
        ls: [8877477209635348035,
        16708328088811667500, 14014037299927741552, 1795070958963053268, 10606788931721547929, 841903545056265961]
    };
    /*
a=37363336077986948456666213736586466128287562369519105825429602984091321919274233302919361890839579644111801541917
b=1798295057736039902482424641059918570220554796267905001254827923367760771974871956830417883729301310309317980773955
a+b=1835658393814026850939090854796505036348842358637424107080257526351852093894146190133337245620140889953429782315872
[13387723108140499808, 
7110911959168982110, 
7018803425472956901, 
2577695370959560254, 
1826757397030539319, 
859395849761138905]

a+b< p is true
*/
    let res: vec384 = add_fp(random_1, random_2);
    equals_vec384(res, vec384 {
        ls: [13387723108140499808, 7110911959168982110, 7018803425472956901, 2577695370959560254, 1826757397030539319, 859395849761138905]
    });
    true
}

fn test_neg() -> bool {
    assert(test_neg_p());
    assert(test_neg_1());
    assert(test_neg_random());
    true
}

// neg(p, p) should result in 0
fn test_neg_p() -> bool {
    let p = vec384 {
        ls: [0xb9feffffffffaaab,
        0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a]
    };
    let res = neg(p, BLS12_381_P);
    equals_vec384(res, ZERO);
    true
}

fn test_neg_1() -> bool {
    /* p (=BLS12_381_P)
    [13402431016077863595, 
    2210141511517208575, 
    7435674573564081700, 
    7239337960414712511, 
    5412103778470702295, 
    1873798617647539866]
    */
    let res = neg(vec384 {
        ls: [1, 0, 0, 0, 0, 0]
    },
    BLS12_381_P);
    let p_minus_1 = vec384 {
        ls: [13402431016077863594,
        2210141511517208575, 7435674573564081700, 7239337960414712511, 5412103778470702295, 1873798617647539866]
    };

    equals_vec384(res, p_minus_1);
    true
}

fn test_neg_random() -> bool {
    //1281534117852017820269267861584320258656990227317793864009951923807317297699607442944495077621627898376663719366433
    //[13059245463466299169, 17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };

    // p-r =
    // 2720875437369649573148521964151583897899892592621214021322106212316714352791230421498192551507387765661230553193354
    let res = neg(r, BLS12_381_P);
    equals_vec384(res, vec384 {
        ls: [343185552611564426, 2882282484148780005, 6545683898001206309, 12914691390957992833, 41210333997197102, 1273825819919628179]
    });
    true
}

fn test_sub_fp() -> bool {
    // assert(test_sub_zero_from_zero());
    // assert(test_sub_zero_from_random());
    // assert(test_sub_random_from_zero());
    // assert(test_sub_random_from_small());
    assert(test_sub_2_randoms());
    assert(test_sub_2_randoms_reverse());
    true
}

fn test_sub_zero_from_zero() -> bool {
    let res = sub_fp(ZERO, ZERO);
    equals_vec384(res, ZERO);
    true
}

fn test_sub_zero_from_random() -> bool {
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };
    let res = sub_fp(r, ZERO);
    equals_vec384(res, r);
    true
}

fn test_sub_random_from_zero() -> bool {
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };
    let res = sub_fp(ZERO, r);
    // p-r (is the same as 0-r mod p)
    equals_vec384(res, vec384 {
        ls: [343185552611564426, 2882282484148780005, 6545683898001206309, 12914691390957992833, 41210333997197102, 1273825819919628179]
    });
    true
}

fn test_sub_random_from_small() -> bool {
    // 1 + 2 *2^64 + 3*2^128 + 4 * 2^192 + 5 * 2^256 + 6 * 2^320
    //12815922215525460494949090683203893664759190466124902882004963575055114655935967659265637031608321
    let small = vec384 {
        ls: [1,
        2, 3, 4, 5, 6]
    };
    //1281534117852017820269267861584320258656990227317793864009951923807317297699607442944495077621627898376663719366433
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };

    let res: vec384 = sub_fp(small, r);
    //result should be 2720875437369649585964444179677044392848983275825107686081296678441617234796193996553307207443355424926867584801675
    //[343185552611564427, 2882282484148780007, 6545683898001206312, 12914691390957992837, 41210333997197107, 1273825819919628185]
    equals_vec384(res, vec384 {
        ls: [343185552611564427, 2882282484148780007, 6545683898001206312, 12914691390957992837, 41210333997197107, 1273825819919628185]
    });
    true
}

fn test_sub_2_randoms() -> bool {
    //a = 1636725880549280067486622211868244649555599468607198938781220718077581339058902572863029175226410795172800087248680
    //[10587454305359941416, 4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194]
    let a = vec384 {
        ls: [10587454305359941416,
        4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194]
    };
    //b = 633982047616931537296775994873240773075794315607478597677958352919546237170580686209956468014669319291596219488262
    //[13403040667047958534, 405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174]
    let b = vec384 {
        ls: [13403040667047958534,
        405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174]
    };
    //res =
    //1002743832932348530189846216995003876479805152999720341103262365158035101888321886653072707211741475881203867760418
    //[15631157712021534498, 4210040059583301456, 2072967503069563536, 7744598167717445820, 16967452369712105079, 469452209245280019]
    let res: vec384 = sub_fp(a, b);
    equals_vec384(res, vec384 {
        ls: [15631157712021534498, 4210040059583301456, 2072967503069563536, 7744598167717445820, 16967452369712105079, 469452209245280019]
    });
    true
}

fn test_sub_2_randoms_reverse() -> bool {
    // Same a,b from test_sub_2_randoms only subtract the other way around
    let a = vec384 {
        ls: [10587454305359941416,
        4615625447881587853, 9368308553698906485, 9494054596162055604, 377309137954328098, 766262085408033194]
    };
    let b = vec384 {
        ls: [13403040667047958534,
        405585388298286396, 7295341050629342949, 1749456428444609784, 1856600841951774635, 296809876162753174]
    };

    //res =
    //-1002743832932348530189846216995003876479805152999720341103262365158035101888321886653072707211741475881203867760418
    // => mod p
    //2999665722289318863227943608740900280077077666939287544228795770965996548602515977789614921917274188156690404799369
    //[16218017377765880713, 16446845525643458734, 5362707070494518163, 17941483866406818307, 6891395482468148831, 1404346408402259846]
    let res: vec384 = sub_fp(b, a);
    equals_vec384(res, vec384 {
        ls: [16218017377765880713, 16446845525643458734, 5362707070494518163, 17941483866406818307, 6891395482468148831, 1404346408402259846]
    });
    true
}

fn tests_mul_by_3_fp() -> bool {
    //3*0=0
    let three_times_0 = mul_by_3_fp(ZERO);
    equals_vec384(three_times_0, ZERO);

    // 3311078190518289289936277681023239947232202294966126226561271980448667165835391482457451698237502148041582301891462
    let a = vec384 {
        ls: [5598198260030196614,
        9227139175563025534, 12721729458998794199, 15322498199590564519, 14360971206699872851, 1550139647308650475]
    };
    // a*3 mod p should be
    //1928415461111533082973253391597911528582841245020362909019699669097938196524498718486979836454475116048958360554812
    let res = mul_by_3_fp(a);
    equals_vec384(res, vec384 {
        ls: [8436476821644414268, 4814390429945107835, 4847095156158667582, 13042074604232716920, 13811961989448662348, 902821706630871694]
    });
    true
}

fn tests_mul_by_8_fp() -> bool {
    //8*0=0
    let eight_times_0 = mul_by_8_fp(ZERO);
    equals_vec384(eight_times_0, ZERO);

    // 2157040060242996582487091204805473379530946954236593619635912200349069530691884182763342898014216243417047961230344
    let a = vec384 {
        ls: [4748578380656466952,
        10419428663092908236, 18363049814497995794, 10615108747081361673, 10405771956295193853, 1009856344616347211]
    };
    // a*8 mod p should be
    //1246682261057303086225570335500170410020044354136717415759065058296429643571722004335992667597667291184806599603604
    let res = mul_by_8_fp(a);
    equals_vec384(res, vec384 {
        ls: [2825647054649832852, 727886963836225123, 6481235779470329860, 623285913863388498, 6257528315350086799, 583656286340618227]
    });
    true
}

fn test_lshift_p() -> bool {
    assert(test_1_lshift_p());
    assert(test_250_lshift_p());
    true
}

fn test_1_lshift_p() -> bool {
    //1281534117852017820269267861584320258656990227317793864009951923807317297699607442944495077621627898376663719366433
    //[13059245463466299169, 17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    let r = vec384 {
        ls: [13059245463466299169,
        17774603101077980186, 889990675562875390, 12771390643166271294, 5370893444473505192, 599972797727911687]
    };
    let res = lshift_fp(r, 1);
    // 1 leftshift is *2
    //2563068235704035640538535723168640517313980454635587728019903847614634595399214885888990155243255796753327438732866
    equals_vec384(res, vec384 {
        ls: [7671746853223046722, 17102462128446408757, 1779981351125750781, 7096037212622990972, 10741786888947010385, 1199945595455823374]
    });
    true
}

fn test_250_lshift_p() -> bool {
    //3801089353888592548165443178944616809833017335235566378191862939584686528734180895181864917846967916907395374952420
    let a = vec384 {
        ls: [13749239540608708580,
        16959468157877110068, 1567469580365175571, 14160078721051372203, 9626163454156242266, 1779547015017246937]
    };
    // leftshift 250 mod p
    //879994519659111629345302542423123869141449003108211674743509876497540102414622865945836408424086377077979782833710
    let res = lshift_fp(a, 250);
    equals_vec384(res, vec384 {
        ls: [13113011510218319406, 16706544215516829647, 7984223107370075095, 1162337285386263785, 307447685117845313, 411984953494678179]
    });
    true
}

fn test_mac() -> bool {
    let a = 13282407956253574712;
    let b = 7557322358563246340;
    let c = 14991082624209354397;

    let res = mac(a, b, c, 0);
    assert(res.0 == 15211181400380206508);
    assert(res.1 == 6141595689857899799);

    let carry = 1234555432334;
    let res2 = mac(a, b, c, carry);
    assert(res2.0 == 15211182634935638842);
    assert(res2.1 == 6141595689857899799);

    true
}

fn test_multiply_wrap() -> bool {
    let a: u64 = 562706585515371056;
    let b: u64 = 2854579515609623853;
    let res: u64 = multiply_wrap(a, b);
    assert(res == 2259604989141998192);
    true
}
