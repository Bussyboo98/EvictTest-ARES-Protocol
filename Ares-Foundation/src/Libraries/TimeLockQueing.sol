// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TimelockQueing {

    struct Queue {
        mapping(uint256 => uint256) eta; // proposalId: thats the earliest execution timestamp
        mapping(uint256 => bool) executed;
        mapping(uint256 => bool) cancelled;
    }

    /// @notice Schedule a proposal in the queue
    function queue(Queue storage self, uint256 proposalId, uint256 delay) internal {
        require(self.eta[proposalId] == 0, "Already queued");
        self.eta[proposalId] = block.timestamp + delay;
    }

    /// @notice Check if proposal is ready for execution
    function canExecute(Queue storage self, uint256 proposalId) internal view returns (bool) {
        return !self.executed[proposalId] && !self.cancelled[proposalId] && block.timestamp >= self.eta[proposalId];
    }

    /// @notice Mark proposal as executed
    function markExecuted(Queue storage self, uint256 proposalId) internal {
        self.executed[proposalId] = true;
    }

    /// @notice Mark proposal as cancelled
    function markCancelled(Queue storage self, uint256 proposalId) internal {
        self.cancelled[proposalId] = true;
    }

    /// @notice Get ETA for a queued proposal
    function getEta(Queue storage self, uint256 proposalId) internal view returns (uint256) {
        return self.eta[proposalId];
    }
}