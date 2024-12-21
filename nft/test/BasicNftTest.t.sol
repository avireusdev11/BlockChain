// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployBasicNft} from "../script/DeployBasicNft.s.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract BasicNftTest is Test{

    DeployBasicNft public deployer; /// the deploying script we made in scripts folder
    BasicNft public basicNft;
    address public USER = makeAddr("user"); /// make a user for testing
    string public constant PUG_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";


    function setUp() public{
        deployer= new DeployBasicNft();
        basicNft = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName= "BasicNft";
        string memory actualName = basicNft.name();
        // assertEq(actualName, expectedName);
        assert(keccak256(bytes(expectedName)) == keccak256(bytes(actualName)));
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assert(basicNft.balanceOf(USER) == 1);
        assert(keccak256(bytes(PUG_URI) )== keccak256(bytes(basicNft.tokenURI(0))));

    }

}