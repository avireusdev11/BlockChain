// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title A sample Rafle Contract
/// @author Aviral Singh Halsi
/// @notice Practicing solidity
/// @dev Implement Chainlink VRFv2.5

contract Raffle is VRFConsumerBaseV2Plus {
    /*Errors*/
    error Raffle__sendMoreToEnterRaffle();
    error Raffle__transferFailed();
    error Raffle_RaffleNotOpen();

    /*Enum*/
    enum RaffleState{OPEN, CALCULATING}

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // The duration between lottery rounds in seconds
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    bytes32 immutable i_keyHash;
    uint256 immutable i_subscriptionId;
    uint32 immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFORMATIONS = 2;
    uint32 private constant NUM_WORDS = 1;
    address private s_recentWinner;
    RaffleState private s_raffleState;



    //EVENTS
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        // s_vrfCoordinator.requestRandomWords();
        s_raffleState=RaffleState.OPEN;
    }

    // enter the raffle and pay some raffle money
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough Eth sent!");
        if (msg.value < i_entranceFee) {
            revert Raffle__sendMoreToEnterRaffle();
        }
        if(s_raffleState!=RaffleState.OPEN)
        {
            revert Raffle_RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
    }

    //1 Get a Random Number
    //2 Automatically calling
    function pickWinner() external {
        //check if enough time is passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }

        s_raffleState =RaffleState.CALCULATING;
        // Get our random number from chainlink so that it is non-deterministic
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFORMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner =randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner=recentWinner;
        (bool success, )= recentWinner.call{value:address(this).balance}("");
        s_raffleState=RaffleState.OPEN;

        //Empty out player array
        s_players = new address payable[](0);
        s_lastTimeStamp=block.timestamp;
        if(!success)
        {
            Raffle__transferFailed;

        }
        emit WinnerPicked(s_recentWinner);
        
    }

    /*Getter Function*/
    function getEntraceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
