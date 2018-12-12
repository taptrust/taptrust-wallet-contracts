pragma solidity ^0.4.24;

import './ECRecovery.sol';
import './SafeMath.sol';

/**
 * @title Proxy Wallet Smart Contract.
 * @author Tap Trust
 * @dev Proof of concept implementation of a Solidity proxy wallet.
 * Unlike most authentication in Ethereum contracts,
 * the address of the transaction sender is arbitrary,
 * but it includes a signed message that can be authenticated
 * as being from either the account owner.
 */
contract ProxyWallet {

	// Using SafeMath library for math expressions.
	using SafeMath for uint256;

	// Hooking up bytes32 with ERRecovery library.
	using ECRecovery for bytes32;

	bytes public userPublicKey;

	uint public nextNonce;
	mapping(bytes32 => bool) public usedMessageHashes;

	constructor(bytes publicKey) public {
		require(publicKey.length == 64);
		userPublicKey = publicKey;
		nextNonce = 1;
	}
	
	function() public payable { }
	
	modifier requireSignedMessage(bytes message, bytes signature, uint256 nonce, uint gasPrice, uint gasLimit) {
	    uint gas = gasleft();
	    require(address(this).balance >= gasPrice.mul(gasLimit));
	    require(tx.gasprice == gasPrice && gas >= gasLimit);
	    
	    //If message includes a nonce, ensure that it is the next nonce that we expect to execute.
		require(nonce == 0 || nextNonce == nonce);
			
		// This recreates the message that was signed on the client.
		bytes32 messageHash = keccak256(message).toEthSignedMessageHash();
		address recoveredSigner = messageHash.recover(signature);

		// Require that the signature recovers the correct user address of the owner.
		require(recoveredSigner == address(keccak256(userPublicKey)));

		//Prevent replay of signed messages.
		if(nonce == 0) {
			require(!usedMessageHashes[messageHash]);
			usedMessageHashes[messageHash] = true;
		} else {
			nextNonce++;
		}
	    _;
	    refundGas(gas, gasPrice);
	}
	
	function refundGas(uint gas, uint gasPrice) private {
	    gas -= gasleft();
	    gas += 21000;
		msg.sender.transfer(gas.mul(gasPrice));
	}
	
	event PublicKeyChanged(bytes _publicKey);
	
	function changePublicKey(uint nonce, uint gasPrice, uint gasLimit, bytes publicKey, bytes signature) public 
	    requireSignedMessage(abi.encodePacked(nonce, gasPrice, gasLimit, "changePublicKey"), signature, nonce, gasPrice, gasLimit)
	{
	    require(publicKey.length == 64);
		userPublicKey = publicKey;
		emit PublicKeyChanged(publicKey);
	}
	
	event TransactionSent(address to, uint256 value, bytes data);
	event TransactionFailed(address to, uint256 value, bytes data);

	function sendTransaction(uint256 nonce, uint256 gasPrice, uint256 gasLimit, address to, uint256 value, bytes data, bytes signature) public 
	    requireSignedMessage(abi.encodePacked(nonce, gasPrice, gasLimit, to, value, data, "sendTransaction"), signature, nonce, gasPrice, gasLimit)
	{
		if(to.call.value(value).gas(gasLimit - 21000)(data))
		    emit TransactionSent(to,value,data);
		else
		    emit TransactionFailed(to,value,data);
	}
}
