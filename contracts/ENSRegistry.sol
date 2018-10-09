pragma solidity ^0.4.24;

import './ENS.sol';
import './ProxyWallet.sol';

/**
 * @title ENS Registry.
 * @author Tap Trust
 * @dev The ENS registry contract.
 */
contract ENSRegistry is ENS {

  // Account Record structure.
  struct AccountRecord {
    address owner;
    address resolver;
    uint64 ttl;
  }

  // Account registry mapping.
  mapping(bytes32 => AccountRecord) accountRegistry;

  // Administrator address.
  address public administrator;

  // Administrators array
  address[] administrators;

  // Proxy Wallet Contract
  ProxyWallet walletContract;

  /**
   * @dev Permits modifications only by the owner of the specified node.
   * @param _node bytes32 Node param.
   */
  modifier onlyOwner(bytes32 _node) {
    require(accountRegistry[_node].owner == msg.sender);
    _;
  }

  /**
   * @dev Checks if the administrator's address is valid or not.
   * @param _administrator address Administrators address.
   */
  modifier onlyValidAdministrator(address _administrator) {
    require(_administrator != address(0));
    _;
  }

  /**
   * @dev Checks if user is added.
   * @param _username bytes32 Username.
   */
  modifier isNotAddedUser(bytes32 _username) {
    require(bytes32(accountRegistry[_username].owner).length > 0);
    _;
  }

  /**
   * @dev Checks if user is not added.
   * @param _username bytes32 Username.
   */
  modifier isNotAddedUser(bytes32 _username) {
    require(bytes32(accountRegistry[_username].owner).length == 0);
    _;
  }

  /**
   * @dev Checks if the administrator's address is valid or not.
   * @param _administrator address Administrators address.
   */
  modifier isOnlyAdministrator(address _administrator) {
    require(_administrator == administrator);
    _;
  }

  /**
   * @dev ENS Registry constructor.
   * @param _administrator address Administrator's address.
   */
  constructor(address _administrator) onlyValidAdministrator(_administrator) public {
    administrator = _administrator;
  }

  /**
   * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
   * @param _node bytes32 The node to transfer ownership of.
   * @param _owner address The address of the new owner.
   */
  function setOwner(bytes32 _node, address _owner) onlyOwner(_node) public {
    emit Transfer(_node, _owner);
    accountRegistry[_node].owner = _owner;
  }

  /**
   * @dev Create new user contract.
   * @param _dataId string Data id value.
   * @param _username string Username of the user.
   * @param _publicKey string Public key of the user.
   */
  function createUserContract(string _dataId, bytes32 _username, string _publicKey) isOnlyAdministrator(msg.sender) isNotAddedUser(_username) public {
    accountRegistry[_username].owner = msg.sender;
    administrators.push(administrator);
    walletContract = new ProxyWallet(administrators);
    walletContract.setNewUser(_dataId, _username, _publicKey);
    accountRegistry[_username].resolver = address(walletContract);
  }

  /**
   * @dev Remove user contract.
   * @param _username bytes32 Username.
   */
  function removeUserContract(bytes32 _username) isOnlyAdministrator(msg.sender) isAddedUser(_username) public {
    delete accountRegistry[_username];
    delete walletContract;
  }

  /**
   * @dev Forward ENS subnode.
   */
  function forwardENSsubnode() pure public {
  }

  /**
   * @dev Transfers ownership of a subnode keccak256(node, label) to a new address. May only be called by the owner of the parent node.
   * @param _node bytes32 The parent node.
   * @param _label bytes32 The hash of the label specifying the subnode.
   * @param _owner address The address of the new owner.
   */
  function setSubnodeOwner(bytes32 _node, bytes32 _label, address _owner) onlyOwner(_node) public {
    bytes32 subnode = keccak256(abi.encodePacked(_node, _label));
    emit NewOwner(_node, _label, _owner);
    accountRegistry[subnode].owner = _owner;
  }

  /**
   * @dev Sets the resolver address for the specified node.
   * @param _node bytes32 The node to update.
   * @param _resolver address The address of the resolver.
   */
  function setResolver(bytes32 _node, address _resolver) onlyOwner(_node) public {
    emit NewResolver(_node, _resolver);
    accountRegistry[_node].resolver = _resolver;
  }

  /**
   * @dev Sets the TTL for the specified node.
   * @param _node bytes32 The node to update.
   * @param _ttl uint64 The TTL in seconds.
   */
  function setTTL(bytes32 _node, uint64 _ttl) onlyOwner(_node) public {
    emit NewTTL(_node, _ttl);
    accountRegistry[_node].ttl = _ttl;
  }

  /**
   * @dev Returns the address that owns the specified node.
   * @param _node bytes32 The specified node.
   * @return address The address of the owner.
   */
  function getOwner(bytes32 _node) public view returns (address) {
    return accountRegistry[_node].owner;
  }

  /**
   * @dev Returns the address of the resolver for the specified node.
   * @param _node bytes32 The specified node.
   * @return address The address of the resolver.
   */
  function getResolver(bytes32 _node) public view returns (address) {
    return accountRegistry[_node].resolver;
  }

  /**
   * @dev Returns the TTL of a node, and any records associated with it.
   * @param _node bytes32 The specified node.
   * @return uint64 The TTL of the node.
   */
  function getTTL(bytes32 _node) public view returns (uint64) {
    return accountRegistry[_node].ttl;
  }
}
