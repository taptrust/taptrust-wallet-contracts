let ConvertLib = artifacts.require('ConvertLib');
let MetaCoin = artifacts.require('MetaCoin');
let ECRecovery = artifacts.require('ECRecovery');
let SafeMath = artifacts.require('SafeMath');
let ProxyWallet = artifacts.require('ProxyWallet');
let ENSRegistry = artifacts.require('ENSRegistry');
let PublicResolver = artifacts.require('PublicResolver');
let ReverseRegistrar = artifacts.require('ReverseRegistrar');

module.exports = function (deployer, network, accounts) {
  const administrators = [
    accounts[0],
    accounts[1],
    accounts[2],
    accounts[3],
    accounts[4]
  ];

  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);

  deployer.deploy(ECRecovery);
  deployer.deploy(SafeMath);
  deployer.link(ECRecovery, ProxyWallet);
  deployer.link(SafeMath, ProxyWallet);

  deployer.deploy(ProxyWallet, administrators);

  const ENSadministrator = accounts[5];
  deployer.link(ECRecovery, ENSRegistry);
  deployer.deploy(ENSRegistry, ENSadministrator).then(function () {
    return deployer.deploy(PublicResolver, ENSRegistry.address).then(function () {
      return deployer.deploy(ReverseRegistrar, ENSRegistry.address, PublicResolver.address);
    });
  });
};
