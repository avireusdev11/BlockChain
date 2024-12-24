// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DscEngine} from "../src/DSCEngine.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script{
    struct NetworkConfig{
        address wethUsdPriceFeed; ///weth is ERC20 Version of etherium
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE=2000e8;
    int256 public constant BTC_USD_PRICE=1000e8;
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY= 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    NetworkConfig public activeNetworkConfig;
    constructor(){
        // activeNetworkConfig= new NetworkConfig();
        if(block.chainid==11155111)
        {
            activeNetworkConfig= getSepoliaEthConfig();
        }
        else{
            activeNetworkConfig= getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory ) {

        return NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306, // ETH / USD
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.wethUsdPriceFeed!=address(0))
        {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            ETH_USD_PRICE
        );
        ERC20Mock wethMock= new ERC20Mock();

        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            BTC_USD_PRICE
        );
        ERC20Mock wbtcMock= new ERC20Mock();
        vm.stopBroadcast();
        return NetworkConfig({
                wethUsdPriceFeed: address(ethUsdPriceFeed), // ETH / USD
                weth: address(wethMock),
                wbtcUsdPriceFeed: address(btcUsdPriceFeed),
                wbtc: address(wbtcMock),
                deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
                });
        
    }
}