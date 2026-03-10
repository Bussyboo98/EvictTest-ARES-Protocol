// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library MerkleClaim {

    /// @notice Check if claim index is claimed
    function isClaimed(mapping(uint256 => uint256) storage claimedBitMap, uint256 index) internal view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 word = claimedBitMap[wordIndex];
        uint256 mask = 1 << bitIndex;
        return word & mask != 0;
    }

    /// @notice Mark claim index as claimed
    function setClaimed(mapping(uint256 => uint256) storage claimedBitMap, uint256 index) internal {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        claimedBitMap[wordIndex] |= 1 << bitIndex;
    }

    /// @notice Verify a Merkle proof for a leaf
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
}