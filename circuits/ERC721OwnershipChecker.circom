pragma circom 2.0.4;

template ERC721OwnershipChecker() {
    // Message checking
    // signal input message;
    // log(message);
    // signal input attestorPublicKey[32]; // TODO: figure out the size
    // signal input tokenAddress;
    // log(tokenAddress);
    // EdDSA signature
    // signal input A[256];
    // signal input R8[256];
    // signal input S[256];
    // Result
    // signal output result;
    // result <== tokenAddress;

    // TODO: check validity of EdDSA signature
    // TODO: check that EdDSA signature was signed by the public key of the attestor
    // TODO: check if the message ends with 'owns-${tokenAddress}'
    // TODO: write the result into the result signal

    // DEBUG
    signal input a;
    signal input b;
    signal output c;
    c <== a * b;  
}

component main{public [a]} = ERC721OwnershipChecker();
