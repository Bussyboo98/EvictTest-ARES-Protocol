// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRewardDistrib {

    event RewardClaimed(uint256 indexed rootId, uint256 indexed index, address account, uint256 amount);
    event RootAddedSuccessfully(uint256 indexed rootId, bytes32 root);

    function pushMerkleRoot(bytes32 root) external;

    function claim(uint256 rootId, uint256 index, address account, uint256 amount, bytes32[] calldata proof) external;

    function isClaimed(uint256 rootId,uint256 index) external view returns (bool);

    function merkleRoot(uint256 rootId) external view returns (bytes32);
}