// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interface/IAresTreasury.sol";

library ProposalCodec {

    function hashAction(
        TreasuryAction memory action
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                uint8(action.actionType),
                action.target,
                action.recipient,
                action.value,
                keccak256(action.data)
            )
        );
    }

    function hashActions(
        TreasuryAction[] memory actions
    ) internal pure returns (bytes32) {

        bytes32[] memory hashes = new bytes32[](actions.length);

        for (uint256 i = 0; i < actions.length; i++) {
            hashes[i] = hashAction(actions[i]);
        }

        return keccak256(abi.encodePacked(hashes));
    }
}