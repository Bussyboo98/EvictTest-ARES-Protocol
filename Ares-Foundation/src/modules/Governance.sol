// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract GovernanceGuard {

    uint256 public constant PROPOSAL_COOLDOWN = 1 hours;
    uint256 public constant MAX_ACTIONS = 10;

    mapping(address => uint256) public lastProposalTime;

    modifier proposalCooldown() {
        require(
            block.timestamp >= lastProposalTime[msg.sender] + PROPOSAL_COOLDOWN,
            "Proposal cooldown active"
        );

        lastProposalTime[msg.sender] = block.timestamp;
        _;
    }

    modifier limitActions(uint256 actionCount) {
        require(actionCount <= MAX_ACTIONS, "Too many actions");
        _;
    }
}