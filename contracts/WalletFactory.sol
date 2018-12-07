pragma solidity ^0.4.24;

import './ProxyWallet.sol';

contract WalletFactory {
	function createNewWallet(bytes publicKey) public returns (address) {
		return address(new ProxyWallet(publicKey));
	}
}