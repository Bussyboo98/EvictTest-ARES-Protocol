// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/AresTreasury.sol";
import "../src/modules/RewardDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployAresTreasury is Script {
    function run() external {
        /*
         If not set, use default values for local testing or placeholder
        */
         // sst yourDEPLOYER_ADDRESS
        address deployer = vm.envOr("DEPLOYER_ADDRESS", msg.sender);
        // set your EMERGENCY_GUARDIAN
        address guardian = vm.envOr("EMERGENCY_GUARDIAN", deployer);
        // set your REWARD_TOKEN 
        address rewardToken = vm.envOr("REWARD_TOKEN ", address(0));
        
       
        address[] memory initialGovernors = new address[](1);
        initialGovernors[0] = deployer;

        vm.startBroadcast(deployer);

        //  Deploy AresTreasury
        AresTreasury treasury = new AresTreasury(initialGovernors, guardian);
        console.log("AresTreasury deployed at:", address(treasury));

        if (rewardToken != address(0)) {
            RewardDistributor distributor = new RewardDistributor(
                IERC20(rewardToken), 
                address(treasury)
            );
            console.log("RewardDistributor deployed at:", address(distributor));

            // Link RewardDistributor to Treasury
            treasury.setRewardDistributor(address(distributor));
            console.log("RewardDistributor linked to AresTreasury");
        } else {
            console.log("Warning: No REWARD_TOKEN provided. Skipping RewardDistributor deployment.");
        }

        vm.stopBroadcast();
    }
}
