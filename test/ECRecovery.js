const ProxyWallet = artifacts.require('ProxyWallet');
let Web3 = require('web3');
let web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:7545'));
let utils = require('ethereumjs-util');

require('chai')
  .should();

/**
 * Hash and add same prefix to the hash that ganache use.
 * @param {string} message the plaintext/ascii/original message
 * @return {string} the hash of the message, prefixed, and then hashed again
 */
function hashMessage(message) {
  const messageHex = Buffer.from(utils.sha3(message).toString('hex'), 'hex');
  const prefix = utils.toBuffer('\u0019Ethereum Signed Message:\n' + messageHex.length.toString());
  return utils.bufferToHex(utils.sha3(Buffer.concat([prefix, messageHex])));
}

// signs message in node (auto-applies prefix)
// message must be in hex already! will not be autoconverted!
async function signMessage(signer, message) {
  return web3.eth.sign(message, signer);
}

async function expectThrow(promise, message) {
  try {
    await promise;
  } catch (error) {
    if (message) {
      assert(
        error.message.search(message) >= 0,
        'Expected \'' + message + '\', got \'' + error + '\' instead',
      );
      return;
    } else {
      const invalidOpcode = error.message.search('invalid opcode') >= 0;
      const outOfGas = error.message.search('out of gas') >= 0;
      const revert = error.message.search('revert') >= 0;
      assert(
        invalidOpcode || outOfGas || revert,
        'Expected throw, got \'' + error + '\' instead',
      );
      return;
    }
  }
  assert.fail('Expected throw not received');
}

contract('ECRecovery', function (accounts) {
  const TEST_MESSAGE = 'OpenZeppelin';

  it('recover v0', function () {
    const signer = '0x2cc1166f6212628a0deef2b33befb2187d35b86c';
    // Signature generated outside ganache with method web3.eth.sign(signer, message)
    const message = web3.utils.sha3(TEST_MESSAGE);
    // eslint-disable-next-line max-len
    const signature = '0x5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be89200';
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.recoverAddress(message, signature);
    }).then((receipt) => {
      assert.equal(receipt.logs[0].args.recoveredAddress, signer);
    })
  });

  it('recover v0', function () {
    const signer = '0x1e318623ab09fe6de3c9b8672098464aeda9100e';
    // Signature generated outside ganache with method web3.eth.sign(signer, message)
    const message = web3.utils.sha3(TEST_MESSAGE);
    // eslint-disable-next-line max-len
    const signature = '0x331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e001';
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.recoverAddress(message, signature);
    }).then((receipt) => {
      assert.equal(receipt.logs[0].args.recoveredAddress, signer);
    })
  });

  it('recover using web3.eth.sign()', async function () {
    const message = web3.utils.sha3(TEST_MESSAGE);
    const signature = await signMessage(accounts[0], message);
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.recoverAddress(hashMessage(TEST_MESSAGE), signature);
    }).then((receipt) => {
      assert.equal(receipt.logs[0].args.recoveredAddress, accounts[0]);
    })
  });

  it('recover using web3.eth.sign() - different hash message', async function () {
    const message = web3.utils.sha3(TEST_MESSAGE);
    const signature = await signMessage(accounts[0], message);
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.recoverAddress(hashMessage('Nope'), signature);
    }).then((receipt) => {
      assert.notEqual(receipt.logs[0].args.recoveredAddress, accounts[0]);
    })
  });

  it('recover should revert when a small hash is sent', async function () {
    const signature = await signMessage(accounts[0], TEST_MESSAGE);
    return ProxyWallet.deployed().then(async function (instance) {
      ProxyWalletInstance = instance;
      try {
        await expectThrow(
          ProxyWalletInstance.recoverAddress(hashMessage(TEST_MESSAGE).substring(2), signature)
        );
      } catch (error) {
        assert.isDefined(error);
      }
    });
  });

  it('toEthSignedMessage - should prefix hashes correctly', async function () {
    const message = web3.utils.sha3(TEST_MESSAGE);
    return ProxyWallet.deployed().then(function (instance) {
      ProxyWalletInstance = instance;
      return ProxyWalletInstance.signMessage(message);
    }).then((receipt) => {
      assert.equal(receipt.logs[0].args.signedMessage, hashMessage(TEST_MESSAGE));
    })
  });

  /*
  context('toEthSignedMessage', () => {
    it('should prefix hashes correctly', async function () {
      const hashedMessage = web3.sha3(TEST_MESSAGE);
      const ethMessage = await proxyWallet.signMessage(hashedMessage);
      ethMessage.should.eq(hashMessage(TEST_MESSAGE));
    });
  });*/
});
