// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MerkleAirDrop} from "../src/MerkleAirDrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script{
    bytes32 private s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private s_amountToTransfer = 4*25 * 1e18; //*4 because we have 4 people to claim it
    function deployMerkleAirdrop() public returns (MerkleAirDrop, BagelToken){
        vm.startBroadcast();
        BagelToken token = new BagelToken();
        MerkleAirDrop airdrop = new MerkleAirDrop(s_merkleRoot, IERC20(token));
        token.mint(token.owner(), s_amountToTransfer);
        token.transfer(address(airdrop), s_amountToTransfer);
        vm.stopBroadcast();
        return (airdrop, token);

    }
    function run() external returns (MerkleAirDrop, BagelToken){
        
    }
}