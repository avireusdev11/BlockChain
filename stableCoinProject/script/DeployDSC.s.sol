// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DscEngine} from "../src/DSCEngine.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDecentralizedStableCoin is Script{
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    function run() external returns(DecentralizedStableCoin, DscEngine, HelperConfig){
        HelperConfig config = new HelperConfig();
        
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) = config.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        vm.startBroadcast(deployerKey);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DscEngine engine = new DscEngine(tokenAddresses,priceFeedAddresses,address(dsc));
        dsc.transferOwnership(address(engine));
        vm.stopBroadcast();
        return (dsc,engine,config);
    }
}