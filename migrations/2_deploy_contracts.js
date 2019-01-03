// Required by zos-lib when running from truffle
global.artifacts = artifacts;
global.web3 = web3;

const { Contracts, SimpleProject  } = require('zos-lib')

const VouchersRegistry = Contracts.getFromLocal('VouchersRegistry');
const WalletFactory = Contracts.getFromLocal('WalletFactory');

const _appAdmin = web3.eth.accounts[1];
const _upgradeAdmin = web3.eth.accounts[0];

module.exports = function (deployer, network, accounts) {
  const project = new SimpleProject('taptrust-wallet-contracts', { from: _upgradeAdmin });
  
  console.log('Creating an upgradeable instance of V0...');
  const proxy = await project.createProxy(VouchersRegistry, { initArgs: [_appAdmin] });
  
  console.log('Contract\'s storage value: ' + (await proxy.value()).toString() + '\n');
  console.log('Upgrading to v1...');
  await project.upgradeProxy(proxy, MyContractV1, { initMethod: 'add', initArgs: [1], initFrom: initializerAddress })
  console.log('Contract\'s storage new value: ' + (await instance.value()).toString() + '\n');
};
