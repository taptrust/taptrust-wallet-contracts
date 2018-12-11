pragma solidity ^0.4.24;

import './ProxyWallet.sol';

contract WalletFactory {
	
	event WalletCreated(address indexed wallet);

	function createNewWallet(bytes publicKey) public {
		emit WalletCreated(address(new ProxyWallet(publicKey)));
	}
}