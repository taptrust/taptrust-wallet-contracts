var ProxyWallet = artifacts.require('ProxyWallet');
var BondingCurve = artifacts.require("BondingCurve.sol");
var Web3EthAbi = require('web3-eth-abi');

var encodedBuyCall = Web3EthAbi.encodeFunctionCall({
    name: 'buy',
    type: 'function',
    inputs: []
}, []);

function generateSignature(address, message) {
	console.log('Generating signature');
	console.log('Address =>' + address);
	let encoded = web3.utils.sha3(message);
	console.log('Encoded message =>' + encoded);
	return web3.eth.sign(encoded, address);
}

contract('ProxyWallet Smart Contract', function (accounts) {
	it('should be initialized correctly', function () {

	});

	it('should be able to execute a Voucher transaction without gas and ether', function () {
	  
	});

	it('should not allow non-Voucher transaction if the ProxyWallet does not have gas funds', function () {

	});

	it('should not allow an invalid signature transaction', function () {
		
	});

	it('should execute an ether transfer correctly', function () {

	});

	it('should refund gas costs to the transaction sender', function () {

	});
});
