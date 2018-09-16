let ProxyWallet = artifacts.require('ProxyWallet');
let util = require('ethereumjs-util');
let Web3 = require('web3');
let web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:7545'));
let node = web3.version.node;
console.log('Using node =>' + node);

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

  it('Check number of users at the start', function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.users;
    }).then((users) => {
      assert.equal(users, undefined);
    })
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
});
