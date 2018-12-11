let ECRecovery = artifacts.require('ECRecovery');
let SafeMath = artifacts.require('SafeMath');
let ProxyWallet = artifacts.require('ProxyWallet');
let WalletFactory = artifacts.require('WalletFactory');

module.exports = function (deployer, network, accounts) {
  deployer.deploy(ECRecovery);
  deployer.deploy(SafeMath);
  deployer.link(ECRecovery, ProxyWallet);
  deployer.link(SafeMath, ProxyWallet);
  deployer.link(ECRecovery, WalletFactory);
  deployer.link(SafeMath, WalletFactory);
  
  deployer.deploy(WalletFactory);
  deployer.deploy(ProxyWallet, '0xc2f8e179bffa12aa0036c3fc926c060cbb3205a6ef43e7cdec3f819960d788f232b8c99008a32e52c90eea1fcd5782b40684ad4421d4772750f223ae142806ff');
};
