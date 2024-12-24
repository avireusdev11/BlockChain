// SPDX-License-Identifier: MIT




// Have our invarinats aka properties hold true

// ex- Getter view functions should never revert

pragma solidity ^0.8.19;

import {Test,console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDecentralizedStableCoin} from "../../script/DeployDSC.s.sol";
import {DscEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";  
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test{
    DeployDecentralizedStableCoin deployer;
    DscEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address btc;
    Handler handler;

    function setUp() external{
        deployer = new DeployDecentralizedStableCoin();
        (dsc, dsce, config) = deployer.run();
        (,,weth,btc,)= config.activeNetworkConfig();

        handler = new Handler(dsce, dsc);
        targetContract(address(handler));
        // we don't want to call redeemcollateral, unless there is collateral to redeem so we need to use handler for it
        // targetContract(address(dsce)); //////// function from StdInvariant


    }

    function test_invarient_protocolMustHaveMoreValueThanTotalSupply() public view{
       // get value of all collateral in protocaol and compare it to debt
       uint256 totalSupply = dsc.totalSupply();
       uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
       uint256 totalBtcDeposited = IERC20(btc).balanceOf(address(dsce));

       uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
       uint256 btcValue = dsce.getUsdValue(btc, totalBtcDeposited);
       assert (wethValue + btcValue >= totalSupply);

    }
}