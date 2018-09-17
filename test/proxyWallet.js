let ProxyWallet = artifacts.require('ProxyWallet');
let util = require('ethereumjs-util');
let Web3 = require('web3');
let web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:7545'));
let node = web3.version.node;
console.log('Using node =>' + node);
let BigNumber = web3.utils.BN;

let testrpc = false;
let geth = false;
let parity = false;
let ganache = false;

if (node === 'Geth') geth = true;
if (node === 'EthereumJS TestRPC') testrpc = true;
if (node === 'Ganache') ganache = true;
if (node === 'Parity') parity = true;
console.log('testrpc=' + ganache);

async function signMessage(hash) {
  return web3.utils.keccak256("\x19Ethereum Signed Message:\n32", hash);
}

async function generateSignature(address, message) {
  console.log('Generating signature');
  console.log('Address =>' + address);
  let encoded;
  /*if (testrpc) {
    encoded = web3.utils.sha3(message);
  }
  if (geth || parity) {
    encoded = '0x' + Buffer.from(message).toString('hex');
  }
  if (ganache) {
    encoded = web3.utils.sha3(message);
  }*/
  encoded = web3.utils.sha3(message);
  console.log('Encoded message =>' + encoded);
  return web3.eth.sign(encoded, address);
}

async function verifySignature(address, message, sig) {
  console.log('Verifying signature');
  console.log('Address =>' + address);
  let encoded;
  /*if (testrpc) {
    //encoded = web3.sha3(message);
    encoded = util.hashPersonalMessage(util.toBuffer(web3.utils.sha3(message)));
  } else if (geth || parity) {
    //encoded = web3.sha3('\x19Ethereum Signed Message:\n32' + web3.sha3(message).substr(2));
    encoded = util.hashPersonalMessage(util.toBuffer(web3.utils.sha3(message)));
  } else if (ganache) {
    encoded = util.hashPersonalMessage(util.toBuffer(web3.utils.sha3(message)));
  }*/
  encoded = util.hashPersonalMessage(util.toBuffer(web3.utils.sha3(message)));
  console.log('  encoded message=' + encoded.toString('hex'));
  if (sig.slice(0, 2) === '0x') sig = sig.substr(2);
  /*if (testrpc || geth) {
    let r = '0x' + sig.substr(0, 64);
    let s = '0x' + sig.substr(64, 64);
    let v = web3.utils.toDecimal(sig.substr(128, 2)) + 27;
  }
  if (parity) {
    v = '0x' + sig.substr(0, 2);
    r = '0x' + sig.substr(2, 64);
    s = '0x' + sig.substr(66, 64);
  }
  if (ganache) {
    r = '0x' + sig.substr(0, 64);
    s = '0x' + sig.substr(64, 64);
    v = web3.utils.toDecimal(sig.substr(128, 2)) + 27;
  }*/

  r = '0x' + sig.substr(0, 64);
  s = '0x' + sig.substr(64, 64);
  v = web3.utils.toDecimal(sig.substr(128, 2)) + 27;

  console.log('  r: ' + r);
  console.log('  s: ' + s);
  console.log('  v: ' + v);

  let ret = {};
  ret.r = r;
  ret.s = s;
  ret.v = v;
  ret.encoded = '0x' + encoded.toString('hex');
  return ret;
}

contract('ProxyWallet Smart Contract', function (accounts) {
  it('Check if proxy wallet is initialized', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance;
    }).then((instance) => {
      assert.isDefined(instance);
    })
  });

  it('Check owner account hash', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.owner();
    }).then((owner) => {
      assert.equal(owner, accounts[0], 'Correct owner');
    })
  });

  it('Check account ETH balance', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return web3.eth.getBalance(accounts[0]);
    }).then((balance) => {
      console.log('Balance: ', web3.utils.fromWei(balance));
      assert.isDefined(balance);
    })
  });

  it('Check if account has ETH balance', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return web3.eth.getBalance(accounts[0]);
    }).then((balance) => {
      assert.notEqual(web3.utils.fromWei(balance), 0);
    })
  });

  it('Check session state at the start', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.sessionData;
    }).then((session) => {
      assert.equal(session, undefined);
    })
  });

  it('Check number of administrators at the start', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.getAdministratorsCount();
    }).then((numberOfAdmins) => {
      assert.equal(numberOfAdmins.toNumber(), 5, 'Correct length of administrators at the start is 5');
    })
  });

  it('Check and save administrators accounts', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.addAdministrator(accounts[2], {from: accounts[0]});
    }).then((receipt) => {
      assert.equal(receipt.logs.length, 1, 'triggers one event');
      assert.equal(receipt.logs[0].event, 'AdministratorAdded', 'should be the ' + 'AdministratorAdded event');
      assert.equal(receipt.logs[0].args.admin, accounts[2], 'correct admin account added.');
      return ProxyWalletInstance.getAllAdministrators();
    }).then((reply) => {
      assert.equal(reply.length, 6, 'Correct length of admin accounts.');
      return ProxyWalletInstance.addAdministrator(accounts[1], {from: accounts[0]});
    }).then(assert.fail).catch(function (error) {
      assert(error.message, 'Admin account already exist.');
    })
  });

  it('Check users at the start', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.users;
    }).then((users) => {
      assert.equal(users, undefined);
    })
  });

  it('Check total gas costs at the start', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.gasCost;
    }).then((gasCost) => {
      assert.equal(gasCost, undefined);
    })
  });

  it('Set new username and userPublicKey', function () {
    let id = '0xbe0942d848991C0b915CA6520c5F064dcF917c22';
    let username = 'test';
    let userPublicKey = '5fe8b9751389e884ccf697eb78afb47979fff9c32a541e31bb599c782d7c770e';
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.setNewUser(id, username, userPublicKey);
    }).then(() => {
      return ProxyWalletInstance.setNewUsername(id, username);
    }).then((receipt) => {
      assert.equal(receipt.logs[0].args.username, username, 'correct username added.');
      return ProxyWalletInstance.setNewUserPublicKey(id, userPublicKey);
    }).then((receipt) => {
      assert.equal(receipt.logs[0].args.publicKey, userPublicKey, 'correct userPublicKey added.');
    })
  });

  it('Start new session and add test session data', function () {
    let dataId = '0xbe0942d848991C0b915CA6520c5F064dcF917c22';
    let deviceId = 0x659541FECCE1B053000657BBF08aB6E67406F711;
    let first = '0x0';
    let second = '0x0';
    let hashed = '0x0';
    let subject = '0x0';
    let r = '0x0';
    let s = '0x0';
    let v = 0;
    let startTime = 0;
    let duration = 0;
    let sessionState = 0;
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.startSession(dataId, deviceId, first, second, hashed, subject, r, s, v, startTime, duration);
    }).then((data) => {
      assert.equal(data.logs[0].args.deviceId, deviceId);
      assert.equal(data.logs[0].args.dataId, dataId);
      assert.equal(data.logs[0].args.state.toNumber(), sessionState);
      return ProxyWalletInstance.checkSessionState(dataId);
    }).then((data) => {
      assert.equal(data.logs[0].args.state.toNumber(), sessionState);
    })
  });

  it('Close the session and delete test data', function () {
    let dataId = '0xbe0942d848991C0b915CA6520c5F064dcF917c22';
    let deviceId = 0x659541FECCE1B053000657BBF08aB6E67406F711;
    let sessionState = 1;
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.closeSession(dataId);
    }).then((data) => {
      assert.equal(data.logs[1].args.deviceId, deviceId);
      assert.equal(data.logs[1].args.dataId, dataId);
      assert.equal(data.logs[1].args.state.toNumber(), sessionState);
    })
  });

  it('Execute transfer correctly', function () {
    let accountOne = accounts[1];
    let accountTwo = accounts[0];
    let accountOneStartingBalance;
    let accountTwoStartingBalance;
    let accountOneEndingBalance;
    let accountTwoEndingBalance;
    let amount = 100000000000;
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.getBalance.call(accountOne);
    }).then(function (balance) {
      accountOneStartingBalance = balance.toNumber();
      return ProxyWalletInstance.getBalance.call(accountTwo);
    }).then(function (balance) {
      accountTwoStartingBalance = balance.toNumber();
      return ProxyWalletInstance.transfer(accountOne, accountTwo, amount, {from: accountOne});
    }).then(function () {
      return ProxyWalletInstance.getBalance.call(accountOne);
    }).then(function (balance) {
      accountOneEndingBalance = balance.toNumber();
      return ProxyWalletInstance.getBalance.call(accountTwo);
    }).then(function (balance) {
      accountTwoEndingBalance = balance.toNumber();
      assert.isBelow(accountOneEndingBalance, accountOneStartingBalance, 'Amount wasn\'t correctly taken from the sender');
      // assert.isAbove(accountTwoEndingBalance, accountTwoStartingBalance, 'Amount wasn\'t correctly sent to the receiver');
    });
  });

  /*it('Generate and check signature', async function() {
    return ProxyWallet.deployed().then(async function (instance) {
      ProxyWalletInstance = instance;
      let address = accounts[0];
      const message = 'Lorem ipsum mark mark dolor sit';
      console.log('Message =>', message);
      let encoded = web3.utils.sha3(message);
      console.log('Encoded message =>', encoded);
      let sig = await signMessage(encoded);
      console.log('Signature Message =>', sig);
      return ProxyWalletInstance.signMessage(message);
    }).then((result) => {
      console.log('Signed message hash =>', result);
      assert.equal(result, accounts[0]);
    });
  });

  it('Generate and check signature', function () {
    let address = accounts[0];
    console.log('Owner =>' + address);
    const message = 'Lorem ipsum mark mark dolor sit';
    return ProxyWallet.deployed().then(async function (instance) {
      ProxyWalletInstance = instance;
      console.log('Message =>', message);
      let signedMessage = await signMessage(message);
      console.log('Signed message from test message =>', signedMessage);
      return ProxyWalletInstance.signMessage(message);
    }).then((data) => {
      console.log('Signed message from Proxy Wallet Instance =>', data);
    })
  });

  it('Recover the address and check signature', function () {
    let address = accounts[0];
    console.log('Owner=' + address);
    const message = 'Lorem ipsum mark mark dolor sit';
    return ProxyWallet.deployed().then(async function (instance) {
      ProxyWalletInstance = instance;
      console.log('sig =>', address);
      console.log('sig =>', message);
      let sig = await generateSignature(address, message);
      console.log('sig =>', sig);
      let ret = await verifySignature(address, message, sig);
      return ProxyWalletInstance.recoverAddress(message, sig);
    }).then((data) => {
      console.log(data);
    })
  });*/

  it('Delete the contract', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.kill();
    }).then(() => {
      ProxyWalletInstance = undefined;
      assert.equal(ProxyWalletInstance, undefined);
    })
  });
});
