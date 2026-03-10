// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/ProposalCodec.sol";
import "../interface/IAresTreasury.sol";

abstract contract ProposalModule {

    using ProposalCodec for TreasuryAction[];

    uint256 public proposalCount;

    mapping(uint256 => bytes32) public proposalHashes;

    mapping(uint256 => IAresTreasury.Proposal) internal proposals;

    function _createProposal(address proposer, TreasuryAction[] calldata actions) internal returns (uint256) {

        proposalCount++;

        uint256 proposalId = proposalCount;

        bytes32 hash = ProposalCodec.hashActions(actions);

        proposalHashes[proposalId] = hash;

        proposals[proposalId] = IAresTreasury.Proposal({
            proposer: proposer,
            executeAfter: 0,
            executed: false,
            cancelled: false
        });

        return proposalId;
    }
}