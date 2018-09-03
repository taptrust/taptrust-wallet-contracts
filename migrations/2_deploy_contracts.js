let ProxyWallet = artifacts.require('./ProxyWallet.sol');

module.exports = function (deployer) {
  deployer.deploy(ProxyWallet);
};
