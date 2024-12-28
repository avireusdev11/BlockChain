// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract BagelToken is ERC20, Ownable{
    // some list of addresses
    // Allow someone in the list to claim tokens
    constructor() ERC20("BagelToken", "BAGEL") Ownable(msg.sender) {

    }

    function mint(address to, uint256 amount) external onlyOwner{
        _mint(to, amount);
    }
}