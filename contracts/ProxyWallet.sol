pragma solidity ^0.4.24;

import './ECRecovery.sol';

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

  // Session data structure
  struct Data {
    address deviceId;
    bytes32 keyOne;
    bytes32 keyTwo;
    string subject;
    bytes32 hashedData;
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint256 startTime;
    uint256 duration;
  }

  // Session data instance
  mapping(string => Data) private sessionData;

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
   * Fired when session data is added.
   */
  event SessionDataAdded(address indexed admin);

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
   * @dev Add session data.
   * @param dataId string Data id value.
   * @param deviceId string Device id value.
   * @param first bytes32 First key.
   * @param second bytes32 Second key.
   * @param hashed bytes32 Hashed value.
   * @param subject string Description/subject value.
   * @param r bytes32 Signature r param.
   * @param s bytes32 Signature s param.
   * @param v uint8 Signature v param.
   * @param startTime uint256 Session start time value.
   * @param duration uint256 Session length value.
   */
  function addSessionData(string dataId, address deviceId, bytes32 first, bytes32 second, bytes32 hashed, string subject, bytes32 r, bytes32 s, uint8 v, uint256 startTime, uint256 duration) public {
    sessionData[dataId] = Data(deviceId, first, second, subject, hashed, r, s, v, startTime, duration);
  }

  /**
   * @dev Add a new administrator to the contract.
   * @param _admin address The address of the administrator to add.
   */
  function addAdministrator(address _admin) isOwner public {
    require(!isAdministrator[_admin]);
    administrators.push(_admin);
    isAdministrator[_admin] = true;
    emit AdministratorAdded(_admin);
  }

  /**
   * @dev Get all administrator addresses.
   * @return address[] List of all administrators.
   */
  function getAllAdministrators() public view returns (address[]) {
    return administrators;
  }

  /**
   * @dev Get public key value from session data.
   * @param dataId string Data id value used as index to find data from session.
   * @return bytes32, bytes32 First and second key from session data.
   */
  function getPublicKey(string dataId) public constant returns (bytes32, bytes32)  {
    return (sessionData[dataId].keyOne, sessionData[dataId].keyTwo);
  }

  /**
   * @dev Get signature value from session data.
   * @param dataId string Data id value used as index to find data from session.
   * @return bytes32, bytes32, uint8 Signature data.
   */
  function getSignature(string dataId) public constant returns (bytes32, bytes32, uint8)  {
    return (sessionData[dataId].r, sessionData[dataId].s, sessionData[dataId].v);
  }

  /**
   * @dev Get other session data from session data.
   * @param dataId string Data id value used as index to find data from session.
   * @return address, string, bytes32, uint256, uint256 Device id, subject, hashed data, start time and duration values form session.
   */
  function getOtherSessionData(string dataId) public constant returns (address, string, bytes32, uint256, uint256)  {
    return (sessionData[dataId].deviceId, sessionData[dataId].subject, sessionData[dataId].hashedData, sessionData[dataId].startTime, sessionData[dataId].duration);
  }

  /**
   * @dev Sign message address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be signed.
   * @return bytes32 Encoded message.
   */
  function signMessage(bytes32 _messageHash) public pure returns (bytes32) {
    return ECRecovery.toEthSignedMessageHash(_messageHash);
  }

  /**
   * @dev Recover address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be checked.
   * @param _sig bytes Signature hashed value.
   * @return address Returning address which signed the message.
   */
  function recoverAddress(bytes32 _messageHash, bytes _sig) public pure returns (address) {
    return ECRecovery.recover(_messageHash, _sig);
  }

  /**
   * @dev Check if the given address signed the message.
   * @param _address address Address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be checked.
   * @param _sig bytes Signature message.
   * @return bool True if the given address signed the message.
   */
  function isSignedMessage(address _address, bytes32 _messageHash, bytes _sig) internal pure returns (bool) {
    return recoverAddress(_messageHash, _sig) == _address;
  }

  /**
   * @dev Destroy the contract.
   */
  function kill() isOwner public {
    selfdestruct(msg.sender);
  }
}
