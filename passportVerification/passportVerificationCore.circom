pragma circom  2.1.6;

include "../node_modules/circomlib/circuits/bitify.circom";
include "./dateComparison.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";

template PassportVerificationCore(N) {
    signal input currDateYear;
    signal input currDateMonth;
    signal input currDateDay;

    signal input credValidYear;
    signal input credValidMonth;
    signal input credValidDay;

    signal input ageLowerbound;

    signal input dg1[N];
    signal input selector;
    signal output out[3];

    // DATE OF EXPIRACY DECODING
    component bits2NumExpYearDigit1  = Bits2Num(4);
    component bits2NumExpYearDigit2  = Bits2Num(4);
    component bits2NumExpMonthDigit1 = Bits2Num(4);
    component bits2NumExpMonthDigit2 = Bits2Num(4);
    component bits2NumExpDayDigit1   = Bits2Num(4);
    component bits2NumExpDayDigit2   = Bits2Num(4);

    var POSITION = 564;
    var SHIFT = 8;
    for (var i = 0; i < 4; i++) {
        bits2NumExpYearDigit1.in[3 - i]  <== dg1[POSITION + 0 * SHIFT + i];
        bits2NumExpYearDigit2.in[3 - i]  <== dg1[POSITION + 1 * SHIFT + i];
        bits2NumExpMonthDigit1.in[3 - i] <== dg1[POSITION + 2 * SHIFT + i];
        bits2NumExpMonthDigit2.in[3 - i] <== dg1[POSITION + 3 * SHIFT + i];
        bits2NumExpDayDigit1.in[3 - i]   <== dg1[POSITION + 4 * SHIFT + i];
        bits2NumExpDayDigit2.in[3 - i]   <== dg1[POSITION + 5 * SHIFT + i];
    }

    signal TEN <== 10;
    signal expYear  <== bits2NumExpYearDigit1.out  * TEN + bits2NumExpYearDigit2.out;
    signal expMonth <== bits2NumExpMonthDigit1.out * TEN + bits2NumExpMonthDigit2.out;
    signal expDay   <== bits2NumExpDayDigit1.out   * TEN + bits2NumExpDayDigit2.out;

    //DATE OF BIRTH DECODING

    component bits2NumBirthYearDigit1  = Bits2Num(4);
    component bits2NumBirthYearDigit2  = Bits2Num(4);
    component bits2NumBirthMonthDigit1 = Bits2Num(4);
    component bits2NumBirthMonthDigit2 = Bits2Num(4);
    component bits2NumBirthDayDigit1   = Bits2Num(4);
    component bits2NumBirthDayDigit2   = Bits2Num(4);
    
    POSITION = 496+4;
    for (var i = 0; i < 4; i++) {
        bits2NumBirthYearDigit1.in[3 - i]  <== dg1[POSITION + 0 * SHIFT + i];
        bits2NumBirthYearDigit2.in[3 - i]  <== dg1[POSITION + 1 * SHIFT + i];
        bits2NumBirthMonthDigit1.in[3 - i] <== dg1[POSITION + 2 * SHIFT + i];
        bits2NumBirthMonthDigit2.in[3 - i] <== dg1[POSITION + 3 * SHIFT + i];
        bits2NumBirthDayDigit1.in[3 - i]   <== dg1[POSITION + 4 * SHIFT + i];
        bits2NumBirthDayDigit2.in[3 - i]   <== dg1[POSITION + 5 * SHIFT + i];
    }

    signal birthYear  <== bits2NumBirthYearDigit1.out  * TEN + bits2NumBirthYearDigit2.out;
    signal birthMonth <== bits2NumBirthMonthDigit1.out * TEN + bits2NumBirthMonthDigit2.out;
    signal birthDay   <== bits2NumBirthDayDigit1.out   * TEN + bits2NumBirthDayDigit2.out;

    // ----------
    // NAME DECODING
    // Name is encoded with 30 bytes in DG1 according to the ICAO docs
    var NAME_FIELD_SIZE = 30*8;
    component bits2NumName = Bits2Num(NAME_FIELD_SIZE);

    POSITION = 11;
    for (var i = 0; i < NAME_FIELD_SIZE; i++) {
        bits2NumName.in[i] <== dg1[POSITION + i];
    }
    // log(bits2NumName.out);

    // ----------
    // SEX DECODING
    var SEX_FIELD_SIZE = 8;
    component bits2NumSex = Bits2Num(SEX_FIELD_SIZE);

    var SEX_POSITION = 69;
    for (var i = 0; i < SEX_FIELD_SIZE; i++) {
        bits2NumSex.in[i] <== dg1[SEX_POSITION*8 + i];
    }
    // log(bits2NumSex.out);
    
    // ----------
    // CURRENT DATE < EXPIRACY DATE

    component isCurrLessExpiracy = DateIsLess();
    isCurrLessExpiracy.firstYear  <== currDateYear;
    isCurrLessExpiracy.firstMonth <== currDateMonth;
    isCurrLessExpiracy.firstDay   <== currDateDay;

    isCurrLessExpiracy.secondYear  <== expYear;
    isCurrLessExpiracy.secondMonth <== expMonth;
    isCurrLessExpiracy.secondDay   <== expDay;
    
    isCurrLessExpiracy.out === 1;

    // ---------
    // BIRTH_DATE + 18 < CURRENT DATE

    // The date year in a passport is stored with double digits (like "12")
    // To differ 19** and 20** we use normalization:
    // If year is less than currentYear, then we consider it 20**
    // Example: birthYear = 14, currDateYear = 24 ==> currDateYearNormalized = 24
    // Otherwise, we consider it 19**
    // Example: birthYear = 79, currDateYear = 24 ==> currDateYearNormalized = 124

    component isAdult = DateIsLess();

    component isPrevCentury = LessThan(8);

    signal CENTURY <== 100;

    isPrevCentury.in[0] <== currDateYear;
    isPrevCentury.in[1] <== birthYear;

    signal currDateYearNormalized <== currDateYear + isPrevCentury.out * CENTURY;    

    isAdult.firstYear  <== birthYear + ageLowerbound;
    isAdult.firstMonth <== birthMonth;
    isAdult.firstDay   <== birthDay;

    isAdult.secondYear  <== currDateYearNormalized;
    isAdult.secondMonth <== currDateMonth;
    isAdult.secondDay   <== currDateDay;

    isAdult.out === 1;

    // ---------
    // CRED_EXP < PASSPORT_EXP

    component isCredExpValid = DateIsLess();

    isCredExpValid.firstYear  <== credValidYear;
    isCredExpValid.firstMonth <== credValidMonth;
    isCredExpValid.firstDay   <== credValidDay;

    isCredExpValid.secondYear  <== expYear;
    isCredExpValid.secondMonth <== expMonth;
    isCredExpValid.secondDay   <== expDay;

    isCredExpValid.out === 1;

    // --------
    // OUT PASSPORT ISSUER CODE [56..80], 3*8 = 24 bits

    component passportIssuer = Bits2Num(24);

    for (var i = 0; i < 24; i++) {
        passportIssuer.in[i] <== dg1[56 + i];
    }

    component num2BitsSelector = Num2Bits(3);
    num2BitsSelector.in <== selector;

    // ---------
    // HASHING NAME

    component nameHasher = Poseidon(1);
    nameHasher.inputs[0] <== bits2NumName.out;

    // OUT SIGNALS

    out[0] <== bits2NumName.out * num2BitsSelector.out[0];
    out[1] <== nameHasher.out * num2BitsSelector.out[1];
    out[2] <== passportIssuer.out * num2BitsSelector.out[2];
}