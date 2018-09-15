let ConvertLib = artifacts.require('ConvertLib');
let MetaCoin = artifacts.require('MetaCoin');
let ECRecovery = artifacts.require('ECRecovery');
let SafeMath = artifacts.require('SafeMath');
let ProxyWallet = artifacts.require('ProxyWallet');

module.exports = function (deployer) {
  const admin1 = '0xbe0942d848991C0b915CA6520c5F064dcF917c22';
  const admin2 = '0x659541FECCE1B053000657BBF08aB6E67406F711';
  const admin3 = '0xe1c3972879c4D5fE2340c8DA8DFa927DcEBFa956';
  const admin4 = '0xc93ddb424CEdeC354c0b85B3c6ba8BD7ff79B3C9';
  const admin5 = '0x753A8f9829F3935d88C5C4640e02eC4E51Be941B';

  const administrators = [
    admin1,
    admin2,
    admin3,
    admin4,
    admin5
  ];

  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);

  deployer.deploy(ECRecovery);
  deployer.deploy(SafeMath);
  deployer.link(ECRecovery, ProxyWallet);
  deployer.link(SafeMath, ProxyWallet);

  deployer.deploy(ProxyWallet,
    administrators
  )
};
