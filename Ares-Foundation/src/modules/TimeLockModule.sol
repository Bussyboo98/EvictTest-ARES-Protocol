// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/TimelockQueing.sol";

abstract contract TimelockModule {

    using TimelockQueing for TimelockQueing.Queue;

    TimelockQueing.Queue internal queue;

    uint256 public constant MIN_DELAY = 2 days;

    function _queueProposal(uint256 proposalId) internal {
        queue.queue(proposalId, MIN_DELAY);
    }

    function _canExecute(uint256 proposalId) internal view returns (bool) {
        return queue.canExecute(proposalId);
    }

    function _markExecuted(uint256 proposalId) internal {
        queue.markExecuted(proposalId);
    }

    function _cancel(uint256 proposalId) internal {
        queue.markCancelled(proposalId);
    }

    function _eta(uint256 proposalId) internal view returns (uint256) {
        return queue.getEta(proposalId);
    }
}