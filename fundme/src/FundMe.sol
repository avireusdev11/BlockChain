//Todo
//to get funds from user
//to withdraw funds
//Set a minimum USD value

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConvertor} from "./PriceConvertor.sol";

contract FundMe{
    using PriceConvertor for uint256;
    uint256 public constant minusd=5*1e18;
    address[] public funders;
    mapping(address funder=> uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor(){
        i_owner= msg.sender;
    }

    function fund() public payable {
        // msg.value.getConversionRate();
        // require(getConversionRate(msg.value) >= minusd,"didn't send enough eth");
        require(msg.value.getConversionRate() >= minusd,"didn't send enough eth");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]=msg.value;

    }

    function withdraw() public onlyOwner{
        // require(msg.sender == owner, "Must be Owner");

        for(uint256 funderIndex=0; funderIndex < funders.length ; funderIndex++)
        {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner(){
        require(msg.sender == i_owner, "Sender is not Owner");
        _; // first thing and do everything else
    }

    receive() external payable {
        fund();
     }
    fallback() external payable { 
        fund();
    }
}