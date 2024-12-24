// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AggregatorV3Interface} from "@chainlink/src/interfaces/feeds/AggregatorV3Interface.sol";

/*
 * @title DSCEngine
 * @author Aviral Singh Halsi
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */




contract DscEngine is ReentrancyGuard{

    error DscEngine__NeedsMoreThanZero();
    error DscEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DscEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor();
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;
    uint256 private constant LIQUIDATION_BONUS =10;

    mapping(address token=> address priceFeed) private s_priceFeeds;
    mapping(address user=>mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user=> uint256 amountDSCMinted) private s_DSCMinted;
    address[] private s_collateralTokens;


    DecentralizedStableCoin private immutable i_dsc; 
    ///modifiers

    modifier moreThanZero(uint256 amount){
        if(amount == 0)
        {
            revert DscEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token)
    {
        if(s_priceFeeds[token] == address(0))
        {
            revert DscEngine__NotAllowedToken();
        }
        _;

    }

    ///Events

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed reddemedFrom, address indexed redeemedTo, address indexed token,uint256 amount);


    //functions
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddress, address dscAddress){

        //USD Price Feed
        if(tokenAddresses.length != priceFeedAddress.length)
        {
            revert DscEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        //ex ETH/USD, BTC/USD, MKR/USD, etc
        for(uint256 i=0;i<tokenAddresses.length;i++)
        {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddress[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /*
    * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
    * @param amountCollateral: The amount of collateral you're depositing
    */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant{

        s_collateralDeposited[msg.sender][tokenCollateralAddress] +=amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success =IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
        if(!success)
        {
            revert DSCEngine__TransferFailed();
        }



    }
    /*
     * 
     * @param tokenCollteralAddress  The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositColletralAndMintDsc(address tokenCollteralAddress, uint256 amountCollateral, uint256 amountDscToMint) external{
        depositCollateral(tokenCollteralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    // function depositCollateral() public {}

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) external{
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    function burnDsc(uint256 amount) public moreThanZero(amount){
        _burnDsc(amount,msg.sender,msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);//won't need it
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) nonReentrant{
        // in order to redeem collateral, the user must have a health factor of 1 after collateral pulled
        _redeemCollateral( tokenCollateralAddress, amountCollateral,msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);

        
    }

    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant{
        s_DSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if(!minted){
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc() external {}

    /*
     * 
     * @param collateral The ERC20 token address of the collateral to liquidate from USER
     * @param user The user who has broken the health factor. Their _healthFactor should be below MIN_HEALTH_FACTOR
     * @param debtToCover the amount of DSC you want to burn to improve the users health factor
     * @notice You can partially liquidate user
     * @notice You will get a liquidation bonus for taking the users funds
     * @notice This functino working assumes the protocol will be roughly 200% overcollateralized in order for this to work
     */
    //if someone is almost undercollateralized, we will pay you to liquidate them!
    function liquidate(address collateral, address user, uint256 debtToCover) external moreThanZero(debtToCover) nonReentrant{
        
        // need to check health factor of USER
        uint256 startingUserHealthFactor = _healthFactor(user);

        if(startingUserHealthFactor >= MIN_HEALTH_FACTOR)
        {
            revert DSCEngine__HealthFactorOk();
        }

        // we want to burn their DSC debt and take their collateral. Ex- BAD USER: $140ETH, $100DSC, Debt to cover $100DSC
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);

        //And give them a 10% bonus
        //So we are giving the liquidator $110 of WETH for 100DSC
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToRedeeem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(collateral,totalCollateralToRedeeem,user,msg.sender);

        //we need to burn the DSC
        _burnDsc(debtToCover,user,msg.sender);
        uint256 endingUserHealthFactor = _healthFactor(user);
        if(endingUserHealthFactor <= startingUserHealthFactor)
        {
            revert DSCEngine__HealthFactorNotImproved();
        }

        _revertIfHealthFactorIsBroken(msg.sender);  
        
    }

    //threshold to let's sat 150%
    //$100eth -> $74 ETH

    function getHealthFactor() external view{}


    ////// internal functions

    //Returns how close to liquidation a user is
    //if a user goes below 1 then they can get liquidated

    function _getAccountInformation(address user) private view returns(uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }
    function _healthFactor(address user) private view returns (uint256) {
        //total DSC minted
        //total collateral value
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }


    function _revertIfHealthFactorIsBroken(address user) internal view{
        // if they do not have enough collateral
        // revert if they don't
        uint256 userHealthFactor=_healthFactor(user);
        if(userHealthFactor<MIN_HEALTH_FACTOR)
        {
            revert DSCEngine__BreaksHealthFactor();
        }

        
    }

    function getAccountCollateralValue(address user) public view returns(uint256 totalCollateralValueInUsd){
        //loop through each collateral token
        for(uint256 i=0;i<s_collateralTokens.length;i++)
        {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token,amount);

        }
    }

    function getUsdValue(address token, uint256 amount) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        //if 1eth = 1000usd
        // the returned value will be 1000 * 1e8
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount)/PRECISION;
        
    }

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        
        return (usdAmountInWei*PRECISION)/(uint256(price) * ADDITIONAL_FEED_PRECISION);
    }


    function _redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to) private{

        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from,to, tokenCollateralAddress, amountCollateral);
        //calculate Health Factor after()
        bool success =IERC20(tokenCollateralAddress).transfer(to,amountCollateral);
        if(!success)
        {
            revert DSCEngine__TransferFailed();
        }
        _revertIfHealthFactorIsBroken(msg.sender);

    }



    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private{
        s_DSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        if(!success)
        {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
        

    }

    function getAccountInformation(address user) external view returns(uint256 totalDscMinted, uint256 collateralValueInUsd){

        (totalDscMinted, collateralValueInUsd) = _getAccountInformation(user);
    } 
}