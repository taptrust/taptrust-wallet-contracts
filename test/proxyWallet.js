let ProxyWallet = artifacts.require('ProxyWallet');
let util = require('ethereumjs-util');
let Web3 = require('web3');
let web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:7545'));
let node = web3.version.node;
console.log('Using node=' + node);

let testrpc = false;
let geth = false;
let parity = false;
let ganache = false;

if (node === 'Geth') geth = true;
if (node === 'EthereumJS TestRPC') testrpc = true;
if (node === 'Ganache') ganache = true;
if (node === 'Parity') parity = true;
console.log('testrpc=' + ganache);

function toHex(str) {
  let hex = '';
  for (let i = 0; i < str.length; i++) {
    hex += '' + str.charCodeAt(i).toString(16);
  }
  return hex
}

async function generateSignature(address, message) {
  console.log('Generating signature');
  console.log('  address=' + address);
  let encoded;
  if (testrpc) {
    encoded = web3.utils.sha3(message);
  }
  if (geth || parity) {
    encoded = '0x' + Buffer.from(message).toString('hex');
  }
  if (ganache) {
    encoded = web3.utils.sha3(message);
  }
  console.log('  encoded message=' + encoded);
  return web3.eth.sign(address, encoded);
}

async function verifySignature(address, message, sig) {
  console.log('Verifying signature');
  console.log('  address=' + address);
  let encoded;
  if (testrpc) {
    //encoded = web3.sha3(message);
    encoded = util.hashPersonalMessage(util.toBuffer(web3.sha3(message)))
  } else if (geth || parity) {
    //encoded = web3.sha3('\x19Ethereum Signed Message:\n32' + web3.sha3(message).substr(2));
    encoded = util.hashPersonalMessage(util.toBuffer(web3.sha3(message)))
  } else if (ganache) {
    encoded = util.hashPersonalMessage(util.toBuffer(web3.sha3(message)))
  }
  console.log('  encoded message=' + encoded.toString('hex'));
  if (sig.slice(0, 2) === '0x') sig = sig.substr(2);
  if (testrpc || geth) {
    let r = '0x' + sig.substr(0, 64);
    let s = '0x' + sig.substr(64, 64);
    let v = web3.toDecimal(sig.substr(128, 2)) + 27;
  }
  if (parity) {
    v = '0x' + sig.substr(0, 2);
    r = '0x' + sig.substr(2, 64);
    s = '0x' + sig.substr(66, 64);
  }
  if (ganache) {
    r = '0x' + sig.substr(0, 64);
    s = '0x' + sig.substr(64, 64);
    v = web3.toDecimal(sig.substr(128, 2)) + 27;
  }
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

contract('Initialize ProxyWallet Smart Contract', function (accounts) {
  it('Check if Proxy Wallet is Initialized', function () {
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

  it('Check and save administrators account', function () {
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

  it('Recover the address and check signature', function () {
    let address = accounts[0];
    console.log('Owner=' + address);
    const message = 'Lorem ipsum mark mark dolor sit';

    //let sig = await generateSignature(address, message);
    //let ret = await verifySignature(address, message, sig);
    //let sig, ret;

    return ProxyWallet.deployed().then(async function (instance) {
      ProxyWalletInstance = instance;
      console.log('sig =>', address);
      console.log('sig =>', message);
      let sig = await generateSignature(address, message);
      console.log('sig =>', sig);
      let ret = await verifySignature(address, message, sig);
      return ProxyWalletInstance.recoverAddress(ret.encoded, ret.v, ret.r, ret.s)
    }).then((data) => {
      console.log(data);
    })
  });

  it("Check account has ETH balance", function () {
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return web3.eth.getBalance(accounts[0]);
    }).then((balance) => {
      console.log(web3.utils.fromWei(balance));
    })
  })

  /*it('Recover the address and check signature.', function () {
    let addr = accounts[0];
    let msg = 'I really did make this message';
    console.log(msg, addr);
    let signature = web3.eth.sign(addr, '0x' + toHex(msg));
    console.log(signature);
    signature = signature.substr(2);
    let r = '0x' + signature.slice(0, 64);
    let s = '0x' + signature.slice(64, 128);
    let v = '0x' + signature.slice(128, 130);
    let v_decimal = web3.toDecimal(v);
    let fixed_msg = `\x19Ethereum Signed Message:\n${msg.length}${msg}`;
    let fixed_msg_sha = web3.sha3(fixed_msg);
    const message = web3.utils.sha3('\x19Ethereum Signed Message:\n32' + 'Message to sign here.');
    const unlockedAccount = accounts[0];
    signature = web3.eth.sign(unlockedAccount, message).slice(2);
    console.log(signature);
    r = signature.slice(0, 64);
    s = '0x' + signature.slice(64, 128);
    v = web3.toDecimal(signature.slice(128, 130)) + 27;
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.recoverAddress(message, v, r, s);
    }).then((receipt) => {
      console.log(unlockedAccount);
      console.log(receipt);
    })
  })*/
});
