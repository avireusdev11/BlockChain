// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test,console} from "forge-std/Test.sol";
import {DeployDecentralizedStableCoin} from "../../script/DeployDSC.s.sol";
import {console} from "forge-std/console.sol";
import {DscEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test{  
    DeployDecentralizedStableCoin deployer;
    DscEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLAERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;


    function setUp() public {
        deployer = new DeployDecentralizedStableCoin();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed,btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER,STARTING_ERC20_BALANCE);
    }

    ////////////   CONSTRUCTOR TESTS   ///////////

    address[] public tokenAddress;
    address[] public priceFeedAddress;
    function testRevertsIfTokenLengthDoesNotMatchPriceFeed() public{
        tokenAddress.push(weth);
        priceFeedAddress.push(ethUsdPriceFeed);
        priceFeedAddress.push(btcUsdPriceFeed); 
        vm.expectRevert(DscEngine.DscEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);  

        new DscEngine(tokenAddress, priceFeedAddress,address(dsc));     
    }

    function testGetTokenAmountFromUsd() public view{
        uint256 usdAmount = 100 ether;
        // $2000 / ETH, $100
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }



    ///////////   PRICE TESTS   ///////////


    function testGetUsdValue() public view{
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        console.log("Expected USD: ", expectedUsd);
        assertEq(expectedUsd,actualUsd, "USD value of 15 ETH should be 3000");
    }

    //////  DEPOSIT COLLATERAL TESTS  //////
    function testRevertsIfCollateralZero() public{
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLAERAL);
        vm.expectRevert(DscEngine.DscEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();

    }



    function testRevertsWithUnapprovedCollateral() public{
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, 100e18);
        vm.startPrank(USER);
        vm.expectRevert(DscEngine.DscEngine__NotAllowedToken.selector);
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLAERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral(){
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLAERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLAERAL);
        vm.stopPrank();
        _;

    }
    function testCanDepositCollateralAndGetAccountInfo() public{
        (uint256 totalDscMinted, uint256 collateralValueInUsd) =dsce.getAccountInformation(USER);
        uint256 expectedTotalDscMinted = 0;
       
        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        // assertEq(AMOUNT_COLLAERAL, expectedDepositAmount);

    }
}