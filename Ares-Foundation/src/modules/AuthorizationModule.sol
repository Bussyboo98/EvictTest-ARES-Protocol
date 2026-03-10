// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/SignatureVerifyer.sol";

abstract contract AuthorizationModule {

    using SignatureVerifyer for bytes32;

    mapping(address => uint256) public nonces;

    address public approver;

    constructor(address _approver) {
        approver = _approver;
    }

    function verifyApproval(
        bytes32 digest,
        bytes memory signature,
        address signer
    ) internal returns (bool) {

        address recovered = SignatureVerifyer.recoverSigner(digest, signature);

        require(recovered == signer, "Invalid signature");

        nonces[signer]++;

        return true;
    }
}