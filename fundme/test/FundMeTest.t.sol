// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test{
    FundMe fundMe;
    function setUp() external{
       fundMe= new FundMe();

    }
    function testMinimumUsdisFive() public{
        assertEq(fundMe.minusd(),5e18);

    }
    function testOwnerisMessageSender() public{
        assertEq(fundMe.i_owner(),address(this));

    }
}