pragma circom 2.0.0;

template ERC721OwnershipChecker(messageLength) {
    // Message checking
    signal input message;
    // signal input attestorPublicKey[32]; // TODO: figure out the size
    signal input tokenAddress;
    // EdDSA signature
    // signal input A[256];
    // signal input R8[256];
    // signal input S[256];
    // Result
    signal output result <== 1;

    // TODO: check validity of EdDSA signature
    // TODO: check that EdDSA signature was signed by the public key of the attestor
    // TODO: check if the message ends with 'owns-${tokenAddress}'
    // TODO: write the result into the result signal
}

component main{public [tokenAddress]} = ERC721OwnershipChecker(90); // TODO: figure out the size
