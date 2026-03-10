// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/MerkleClaiming.sol";

abstract contract RewardDistributionModule {

    using MerkleClaim for mapping(uint256 => uint256);

    uint256 public rootCount;

    mapping(uint256 => bytes32) public merkleRoots;

    mapping(uint256 => mapping(uint256 => uint256)) internal claimedBitMaps;

    event RewardClaimed(uint256 rootId, uint256 index, address account, uint256 amount);
    event RootAddedSuccessfully(uint256 rootId, bytes32 root);

    function _pushRoot(bytes32 root) internal {

        merkleRoots[rootCount] = root;

        emit RootAddedSuccessfully(rootCount, root);

        rootCount++;
    }

    function _claim(uint256 rootId, uint256 index, address account, uint256 amount,
        bytes32[] calldata proof) internal {
        require(
            !MerkleClaim.isClaimed(claimedBitMaps[rootId], index),
            "Already claimed"
        );

        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));

        require(
            MerkleClaim.verify(proof, merkleRoots[rootId], leaf),
            "Invalid proof"
        );

        MerkleClaim.setClaimed(claimedBitMaps[rootId], index);
        emit RewardClaimed(rootId, index, account, amount);
    }
}