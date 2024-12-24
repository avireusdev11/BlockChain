// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;



import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title DecentralizedStableCoin
*@author Aviral Singh Halsi
Minting Algorithmic
Relative Stability: Pegged to USD
 */

contract DecentralizedStableCoin is ERC20Burnable,Ownable{

    error DecentralizedStableCoin__MustbeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();



    constructor()ERC20("DecentralizedStableCoin","DSC") Ownable(msg.sender){

    }

    function burn(uint256 _amount) public override onlyOwner{

        uint256 balance = balanceOf(msg.sender);
        if(_amount<=0)
        {
            revert DecentralizedStableCoin__MustbeMoreThanZero();
        }

        if(balance < _amount)
        {
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }

        super.burn(_amount);

    }

    function mint(address _to, uint256 _amount) external onlyOwner returns(bool){
        if(_to == address(0))
        {
            revert DecentralizedStableCoin__NotZeroAddress();

        }
        if(_amount<=0)
        {
            revert DecentralizedStableCoin__MustbeMoreThanZero();
        }

        _mint(_to,_amount);
        return true;

    }

}