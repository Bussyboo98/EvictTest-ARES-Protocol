// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SignatureVerifyer {

    function recoverSigner(bytes32 digest, bytes memory signature) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(digest, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}