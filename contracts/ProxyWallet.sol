pragma solidity ^0.4.24;

/**
 * @title Proxy Wallet
 * @author Tap Trust
 * @dev Proof of concept implementation of a Solidity proxy wallet.
 * Unlike most authentication in Ethereum contracts,
 * the address of the transaction sender is arbitrary,
 * but it includes a signed message that can be authenticated
 * as being from either the account owner or a dApp
 * for whom the account owner has created a session with permissions.
 */
contract ProxyWallet {

  // List of administrator addresses
  address[] public administrators;

  // Owner username
  string private ownerUsername;

  // Owner Public Key
  string private ownerPublicKey;

  /**
   * Proxy Wallet constructor
   */
  constructor(address[] _administrators) public {
    require(_administrators.length > 0);

    for (uint256 i = 0; i < _administrators.length; i++) {
      addAdministrator(_administrators[i]);
    }
  }

  /**
   * @dev Add a new administrator to the contract.
   * @param _admin The address of the administrator to add.
   */
  function addAdministrator(address _admin) internal {
    require(_admin != address(0));

    administrators.push(_admin);
  }
}
