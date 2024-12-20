// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";




contract DeployFundMe is Script {
    function run() external returns (FundMe){

        HelperConfig HelperConfig = new HelperConfig();

        vm.startBroadcast();
        new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        vm.stopBroadcast();
    }
}