// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployMoodNft is Script{
    
    function run() external returns(MoodNft){
        string memory SAD_SVG_URI=svgToImageURI(vm.readFile("./img/sad.svg"));
        string memory HAPPY_SVG_URI=svgToImageURI(vm.readFile("./img/happy.svg"));
        vm.startBroadcast();
        MoodNft moodNft = new MoodNft(SAD_SVG_URI,HAPPY_SVG_URI);
        vm.stopBroadcast();
        return moodNft;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory){
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg))) // Removing unnecessary type castings, this line can be resumed as follows : 'abi.encodePacked(svg)'
        );
        return string(abi.encodePacked(baseURI, svgBase64Encoded));

    }
}