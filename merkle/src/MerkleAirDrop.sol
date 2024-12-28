// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirDrop is EIP712{
    using SafeERC20 for IERC20;
    event Claim(address account, uint256 amount);
    // some list of addresses
    // Allow someone in the list to claim tokens
    error MerkleAirDrop__InvalidProof();
    error MerkleAirDrop__AlreadyClaimed();
    error MerkleAirDrop__InvalidSignature();

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping (address claim => bool claimed) private s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirDrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;

    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external{
        //calculate using the account and the amount, the hash -> leaf node

        if(s_hasClaimed[account]){
            revert MerkleAirDrop__AlreadyClaimed();
        }
        // if the signature is not valid we revert
        if(!_isValidSignature(account,getMessageHash(account,amount), v,r ,s)){
            revert MerkleAirDrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encodePacked(account, amount)))); /// when using merkle proof, we need to hash it twice

        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)){
            
            revert MerkleAirDrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);

        
        
        
    }

    

    function getMessageHash(address account, uint256 amount) public view returns(bytes32 digest){
        return _hashTypedDataV4(keccak256(abi.encode(
        MESSAGE_TYPEHASH,
        AirdropClaim({account: account, amount: amount})
    )));
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns(bool){
        (address actualSigner, , ) = ECDSA.tryRecover(digest,v,r,s);
        return actualSigner == account;
    }

    function getMerkleRoot() external view returns(bytes32){
            return i_merkleRoot;
        }

    function getAirdropToken() external view returns(IERC20){
        return i_airdropToken;
    }

}