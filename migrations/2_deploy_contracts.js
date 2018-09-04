let ProxyWallet = artifacts.require('ProxyWallet');

module.exports = function (deployer) {
  const admin1 = '0x23159c0f232335f0211Ce0443BaE38870dB2F18B';
  const admin2 = '0xdCf5082AdC8c1b35c1AB319F58Af36dfbAa0ed50';
  const admin3 = '0x928255F2C7418C6206341E8F0950fD8CED394882';
  const admin4 = '0x9422D78A6864ed5C6bE081Fb90A9B2Ea5c0062c3';
  const admin5 = '0xb602A158Dd02a97f8E5daA7e9636E9A1F9a8DA4c';

  const administrators = [
    admin1,
    admin2,
    admin3,
    admin4,
    admin5
  ];

  const username = 'test_username';
  const publicKey = '38bf319433a9d9188fcfd213c32ccb7b93465d67deadf896f644058c3a620d2c';

  deployer.deploy(ProxyWallet,
    administrators,
    username,
    publicKey
  )
};
