// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public{}

    function deployContract() public returns (Raffle, HelperConfig){

        HelperConfig helperConfig = new HelperConfig();
        
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId==0)
        {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoodinator) =createSubscription.createSubscription(config.vrfCoodinator);
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(config.entranceFee,config.interval,config.vrfCoodinator,config.gasLane,config.subscriptionId,config.callbackGasLimit);
        vm.stopBroadcast();

        return (raffle,helperConfig);
    }

}