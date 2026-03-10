// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/MerkleClaiming.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RewardDistributor {
    using SafeERC20 for IERC20;
    using MerkleProof for bytes32[];

    IERC20 public immutable rewardToken;
    address public treasury;
    uint256 public currentRootId;

    struct RootInfo {
        bytes32 root;
        uint256 createdAt;
    }

    mapping(uint256 => RootInfo) public roots;
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap; // rootId -> word index -> bits

    event RootPushed(uint256 indexed rootId, bytes32 root);
    event Claimed(uint256 indexed rootId, uint256 indexed index, address indexed account, uint256 amount);
    event TreasuryUpdated(address indexed treasury);

    modifier onlyTreasury() {
        require(msg.sender == treasury, "Only treasury");
        _;
    }

    constructor(IERC20 _rewardToken, address _treasury) {
        require(address(_rewardToken) != address(0), "token zero");
        require(_treasury != address(0), "treasury zero");
        rewardToken = _rewardToken;
        treasury = _treasury;
    }

    function setTreasury(address _treasury) external onlyTreasury {
        require(_treasury != address(0), "treasury zero");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function pushMerkleRoot(bytes32 root) external onlyTreasury returns (uint256 rootId) {
        require(root != bytes32(0), "invalid root");
        currentRootId += 1;
        roots[currentRootId] = RootInfo({root: root, createdAt: block.timestamp});
        emit RootPushed(currentRootId, root);
        return currentRootId;
    }

    function isClaimed(uint256 rootId, uint256 index) public view returns (bool) {
        require(rootId > 0 && rootId <= currentRootId, "bad rootId");
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 word = claimedBitMap[rootId][wordIndex];
        return (word & (1 << bitIndex)) != 0;
    }

    function _setClaimed(uint256 rootId, uint256 index) private {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        claimedBitMap[rootId][wordIndex] |= (1 << bitIndex);
    }

    function claim(
        uint256 rootId,
        uint256 index,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        require(rootId > 0 && rootId <= currentRootId, "unknown root");
        require(!isClaimed(rootId, index), "already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(MerkleProof.verify(proof, roots[rootId].root, leaf), "invalid proof");

        _setClaimed(rootId, index);
        rewardToken.safeTransfer(msg.sender, amount);
        emit Claimed(rootId, index, msg.sender, amount);
    }
}

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