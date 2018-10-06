let ConvertLib = artifacts.require('ConvertLib');
let MetaCoin = artifacts.require('MetaCoin');
let ECRecovery = artifacts.require('ECRecovery');
let SafeMath = artifacts.require('SafeMath');
let ProxyWallet = artifacts.require('ProxyWallet');
let ENS = artifacts.require('ENS');
let ENSRegistry = artifacts.require('ENSRegistry');

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
  deployer.deploy(ENSRegistry, ENSadministrator);
};
