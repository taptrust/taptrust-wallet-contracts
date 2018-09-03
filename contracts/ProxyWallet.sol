pragma solidity ^0.4.24;

/**
 * @title Proxy Wallet.
 * @author Tap Trust
 * @dev Proof of concept implementation of a Solidity proxy wallet.
 * Unlike most authentication in Ethereum contracts,
 * the address of the transaction sender is arbitrary,
 * but it includes a signed message that can be authenticated
 * as being from either the account owner or a dApp
 * for whom the account owner has created a session with permissions.
 */
contract ProxyWallet {

  // Owner of the contract
  address public owner;

  // List of administrator addresses
  address[] public administrators;

  // List of administrator checks for each address
  mapping(address => bool) public isAdministrator;

  // Owner Username
  string private ownerUsername;

  // Owner Public Key
  string private ownerPublicKey;

  /**
   * @dev Requires a valid owner of the contract.
   */
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Requires that a valid administrator address was provided.
   * @param _admin address Administrator address.
   */
  modifier onlyValidAdministrator(address _admin) {
    require(_admin != address(0));
    _;
  }

  /**
   * @dev Requires that a valid administrator list was provided.
   * @param _administrators address[] List of administrators.
   */
  modifier onlyValidAdministrators(address[] _administrators) {
    require(_administrators.length > 0);
    _;
  }

  /**
   * @dev Requires that a valid username of the user was provided.
   * @param _username string Username of the user.
   */
  modifier onlyValidUsername(string _username) {
    require(bytes(_username).length > 0);
    _;
  }

  /**
   * @dev Requires that a valid public key of the user was provided.
   * @param _publicKey string Public key of the user.
   */
  modifier onlyValidPublicKey(string _publicKey) {
    require(bytes(_publicKey).length > 0);
    _;
  }

  /**
   * Fired when username is set.
   */
  event UsernameSet(address indexed from, string username);

  /**
   * Fired when public key is set.
   */
  event PublicKeySet(address indexed from, string publicKey);

  /**
   * Fired when administrator is added.
   */
  event AdministratorAdded(address indexed admin);

  /**
   * @dev Proxy Wallet constructor.
   * @param _administrators address[] List of administrator addresses.
   * @param _username string Username of the user.
   * @param _publicKey string Public key of the user.
   */
  constructor(address[] _administrators, string _username, string _publicKey) onlyValidAdministrators(_administrators) public {

    owner = msg.sender;

    setOwnerUsername(_username);

    setOwnerPublicKey(_publicKey);

    for (uint256 i = 0; i < _administrators.length; i++) {
      addAdministrator(_administrators[i]);
    }
  }

  /**
   * @dev Set owner username.
   * @param _username string Username of the user.
   */
  function setOwnerUsername(string _username) onlyValidUsername(_username) internal {
    ownerUsername = _username;
    emit UsernameSet(msg.sender, _username);
  }

  /**
   * @dev Set owner public key.
   * @param _publicKey string Public key of the user.
   */
  function setOwnerPublicKey(string _publicKey) onlyValidPublicKey(_publicKey) internal {
    ownerPublicKey = _publicKey;
    emit PublicKeySet(msg.sender, _publicKey);
  }

  /**
   * @dev Add a new administrator to the contract.
   * @param _admin address The address of the administrator to add.
   */
  function addAdministrator(address _admin) onlyValidAdministrator(_admin) internal {
    require(!isAdministrator[_admin]);
    administrators.push(_admin);
    isAdministrator[_admin] = true;
    emit AdministratorAdded(_admin);
  }

  /**
   * @dev Get all administrator addresses.
   * @return address[] List of all administrators.
   */
  function getAllAdministrators() public view returns (address[]){
    return administrators;
  }

  /**
   * @dev Recover address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be checked.
   * @param v uint8 Part of Signature validation.
   * @param r bytes32 Part of Signature validation.
   * @param s bytes32 Part of Signature validation.
   * @return address Returning address which signed the message.
   */
  function recoverAddress(bytes32 _messageHash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
    return ecrecover(_messageHash, v, r, s);
  }

  /**
   * @dev Check if the given address signed the message.
   * @param _address address Address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be checked.
   * @param v uint8 Part of Signature validation.
   * @param r bytes32 Part of Signature validation.
   * @param s bytes32 Part of Signature validation.
   * @return bool True if the given address signed the message.
   */
  function isSignedMessage(address _address, bytes32 _messageHash, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
    return ecrecover(_messageHash, v, r, s) == _address;
  }
}
