const HDWalletProvider = require("truffle-hdwallet-provider");

// add your Oasis Devnet mnemonic here. Be sure to keep it secret!
const MNEMONIC = 'junk human real manual destroy echo salon virus mule denial explain again';

// mnemonic for Contract Kit local blockchain
const CONTRACT_KIT_MNEMONIC = 'candy maple cake sugar pudding cream honey rich smooth crumble sweet treat';

module.exports = {
  networks: {
    // Oasis Devnet
    oasis: {
      provider: function () {
        return new HDWalletProvider(MNEMONIC, "https://web3.oasiscloud.io");
      },
      network_id: "42261"
    },

    // Contract Kit local chain
    development: {
      provider: function () {
        return new HDWalletProvider(CONTRACT_KIT_MNEMONIC, "http://localhost:8545", 0, 10);
      },
      network_id: "*"
    },
  },
  compilers: {
    external: {
      command: "./node_modules/.bin/oasis-compile",
      targets: [{
        path: "./.oasis-build/*.json"
      }]
    },
    solc: {
        version: "0.4.24"
    }
  }
};

