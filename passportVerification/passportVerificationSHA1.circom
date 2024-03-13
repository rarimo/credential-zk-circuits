pragma circom  2.1.6;

include "../node_modules/circomlib/circuits/bitify.circom";
include "./passportVerificationCore.circom";
include "./utils/sha1.circom";

template PassportVerificationSHA1(N) {
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

    component hasher = Sha1(N);

    hasher.in <== dg1;

    component bits2NumHash = Bits2Num(160);

    for (var i = 0; i < 160; i++) {
        bits2NumHash.in[160 - 1 - i] <== hasher.out[i];
    }

    out[0] <== bits2NumHash.out;
}

component main {public [currDateDay, 
                        currDateMonth,
                        currDateYear, 
                        credValidYear, 
                        credValidMonth, 
                        credValidDay,
                        ageLowerbound]} = PassportVerificationSHA1(744);