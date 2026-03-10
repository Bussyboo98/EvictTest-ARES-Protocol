// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum TreasuryActionType {
    ETH_TRANSFER,
    ERC20_TRANSFER,
    CALL,
    UPGRADE
}

struct TreasuryAction {
    TreasuryActionType actionType;
    address target;
    address recipient;
    uint256 value;
    bytes data;
}

interface IAresTreasury {

    struct Proposal {
        address proposer;
        uint256 executeAfter;
        bool executed;
        bool cancelled;
    }

    event ProposalCreated(uint256 indexed proposalId, address proposer);
    event ProposalCommitted(uint256 indexed proposalId);
    event ProposalQueued(uint256 indexed proposalId, uint256 executeAfter);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);

    function propose(TreasuryAction[] calldata actions, uint256 deadline,
        bytes calldata approverSignature) external returns (uint256 proposalId);

    function commit(uint256 proposalId) external;

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId, TreasuryAction[] calldata actions) external payable;

    function cancel(uint256 proposalId) external;

    function getProposal(uint256 proposalId) external view returns (Proposal memory);
}