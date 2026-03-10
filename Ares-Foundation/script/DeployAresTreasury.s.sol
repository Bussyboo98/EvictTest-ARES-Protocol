// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/AresTreasury.sol";
import "../src/modules/RewardDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployAresTreasury is Script {
    function run() external {
        // Retrieve deployment configurations from environment variables
        // If not set, use default values for local testing or placeholder
        address deployer = vm.envOr("DEPLOYER_ADDRESS", msg.sender);
        address guardian = vm.envOr("EMERGENCY_GUARDIAN", deployer);
        address rewardToken = vm.envOr("REWARD_TOKEN", address(0));
        
        // Initial governors - for deployment, we can use the deployer or a list from env
        address[] memory initialGovernors = new address[](1);
        initialGovernors[0] = deployer;

        vm.startBroadcast(deployer);

        // 1. Deploy AresTreasury
        AresTreasury treasury = new AresTreasury(initialGovernors, guardian);
        console.log("AresTreasury deployed at:", address(treasury));

        // 2. Deploy RewardDistributor (if reward token is provided)
        if (rewardToken != address(0)) {
            RewardDistributor distributor = new RewardDistributor(
                IERC20(rewardToken), 
                address(treasury)
            );
            console.log("RewardDistributor deployed at:", address(distributor));

            // 3. Link RewardDistributor to Treasury
            treasury.setRewardDistributor(address(distributor));
            console.log("RewardDistributor linked to AresTreasury");
        } else {
            console.log("Warning: No REWARD_TOKEN provided. Skipping RewardDistributor deployment.");
        }

        vm.stopBroadcast();
    }
}
