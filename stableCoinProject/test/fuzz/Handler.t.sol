// Handler is going to narrow down the way we call the functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {DscEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Test,console} from "forge-std/Test.sol";

contract Handler is Test{
    DscEngine dsce;
    DecentralizedStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;

    constructor(DscEngine _dscEngine, DecentralizedStableCoin _dsc){
        // console.log("Handler constructor");
        dsce = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // redeemCollateral only be called when there is collateral

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public{
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        vm.prank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);
        dsce.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
   
    }

    //Helper Function
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock){
        if(collateralSeed % 2 ==0 ){
            return weth;
        }
        return wbtc;
    }
}