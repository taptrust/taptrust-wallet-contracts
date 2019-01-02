pragma solidity ^0.4.24;

import "zos-lib/contracts/application/App.sol";
import './ProxyWallet.sol';
import 'zos-lib/contracts/Initializable.sol';
import './trustfund-vouchers/contracts/VouchersRegistry.sol';

contract WalletFactory is Initializable {
	
	event WalletCreated(address indexed wallet);
	
	VouchersRegistry private _registry;
	App private _app;
	
	function initialize(App app, VouchersRegistry registry) initializer public { 
		require(uint256(address(registry)) != 0);
		require(uint256(address(app)) != 0);
		_app = app;
		_registry = registry;
	}

	function createNewWallet(bytes publicKey) public {
		ProxyWallet wallet = ProxyWallet(_app.create("taptrust-wallet-contracts", "ProxyWallet", abi.encodeWithSignature("initialize(bytes,address)", publicKey, _registry)));
		emit WalletCreated(address(wallet));
	}
}