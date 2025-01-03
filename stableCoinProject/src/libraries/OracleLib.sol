// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


import {AggregatorV3Interface} from "@chainlink/src/interfaces/feeds/AggregatorV3Interface.sol";


/**
 * @title OracleLib
 * @author Aviral Singh Halsi
 * @notice This library is used to check the ChainLin Oracle for stale data.
 * If a price is stale, the function will revert, and render the DSCEngine unsuable.
 */

library OracleLib {
    error OracleLib__StalePrice();
    uint256 private constant TIMEOUT = 3 hours; //3* 60* 60
    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) public view returns(uint80,int256, uint256, uint256, uint80){
        (uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =priceFeed.latestRoundData();

        uint256 secondsSince = block.timestamp - updatedAt;

        if(secondsSince > TIMEOUT)
        {
            revert OracleLib__StalePrice();
        }
        return (roundId, price, startedAt, updatedAt, answeredInRound);
    }
}

