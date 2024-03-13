pragma circom  2.1.6;

include "../node_modules/circomlib/circuits/sha256/sha256.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "./passportVerificationCore.circom";

template PassportVerificationSHA256(N) {
    signal input currDateYear;
    signal input currDateMonth;
    signal input currDateDay;

    signal input credValidYear;
    signal input credValidMonth;
    signal input credValidDay;

    signal input ageLowerbound;

    signal input dg1[N];
    signal input selector;

    signal output out[5];

    component passportVerificationCore = PassportVerificationCore(N);

    passportVerificationCore.selector <== selector;
    passportVerificationCore.dg1 <== dg1;

    passportVerificationCore.currDateYear   <== currDateYear;
    passportVerificationCore.currDateMonth  <== currDateMonth;
    passportVerificationCore.currDateDay    <== currDateDay;

    passportVerificationCore.credValidYear  <== credValidYear;
    passportVerificationCore.credValidMonth <== credValidMonth;
    passportVerificationCore.credValidDay   <== credValidDay;

    passportVerificationCore.ageLowerbound  <== ageLowerbound;

    out[2] <== passportVerificationCore.out[0];
    out[3] <== passportVerificationCore.out[1];
    out[4] <== passportVerificationCore.out[2];
    // -------

    component hasher = Sha256(N);

    hasher.in <== dg1;

    component bits2NumFirst = Bits2Num(128);
    component bits2NumSecond = Bits2Num(128);

    for (var i = 0; i < 128; i++) {
        bits2NumFirst.in[127 - i] <== hasher.out[i];
    }

    for (var i = 0; i < 128; i++) {
        bits2NumSecond.in[127 - i] <== hasher.out[128 + i];
    }

    out[0] <== bits2NumFirst.out;
    out[1] <== bits2NumSecond.out;
}

component main {public [currDateDay, 
                        currDateMonth, 
                        currDateYear, 
                        credValidYear, 
                        credValidMonth, 
                        credValidDay,
                        ageLowerbound]} = PassportVerificationSHA256(744);