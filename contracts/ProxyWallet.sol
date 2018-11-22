pragma solidity ^0.4.24;

import './ECRecovery.sol';
import './SafeMath.sol';

/**
 * @title Proxy Wallet Smart Contract.
 * @author Tap Trust
 * @dev Proof of concept implementation of a Solidity proxy wallet.
 * Unlike most authentication in Ethereum contracts,
 * the address of the transaction sender is arbitrary,
 * but it includes a signed message that can be authenticated
 * as being from either the account owner or a dApp
 * for whom the account owner has created a session with permissions.
 */
contract ProxyWallet {

  // Using SafeMath library for math expressions.
  using SafeMath for uint256;

  // Hooking up bytes32 with ERRecovery library.
  using ECRecovery for bytes32;

  // Owner of the contract.
  address public owner;

  // Account balance.
  uint256 balance;

  // Session state.
  enum SessionState {Active, Closed}

  // Transaction type.
  enum TransactionType {OneTime, Session}

  // User name.
  string public username;

  // User public key.
  string public userPublicKey;

  // Times data structure.
  struct Times {
    uint256 startTime;
    uint256 duration;
  }

  // Session data structure.
  struct Data {
    address deviceId;
    string keyOne;
    string keyTwo;
    string subject;
    bytes32 hashedData;
    bytes32 r;
    bytes32 s;
    uint8 v;
    Times times;
    SessionState state;
    TransactionType transactionType;
  }

  // Session data mapping.
  mapping(string => Data) private sessionData;

  // List of administrator addresses.
  address[] public administrators;

  // List of administrator checks for each address.
  mapping(address => bool) public isAdministrator;

  // Start gas value.
  uint256 public remainingGasStart;

  // Spent gas value.
  uint256 public remainingGasEnd;

  // Used gas calculation.
  uint256 public usedGas;

  // Total cost of gas for all methods.
  uint256 public gasCost;

  /**
   * @dev Requires a valid owner of the contract.
   */
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Checks if the admin is correct and belongs to list of administrators.
   * @param _admin address Administrator address.
   */
  modifier isAuthorizedAdmin(address _admin) {
    require(administrators.length > 0);
    require(_admin != address(0));
    bool isAdmin = false;
    for (uint256 i = 0; i < administrators.length; i++) {
      if (_admin == administrators[i]) {
        isAdmin = true;
      }
    }
    if (isAdmin) {
      _;
    }
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
    bytes memory tempValidUsername = bytes(_username);
    require(tempValidUsername.length > 0);
    _;
  }

  /**
   * @dev Requires that a valid public key of the user was provided.
   * @param _publicKey string Public key of the user.
   */
  modifier onlyValidPublicKey(string _publicKey) {
    bytes memory tempValidPublicKey = bytes(_publicKey);
    require(tempValidPublicKey.length > 0);
    _;
  }

  /**
   * @dev Check if user is not already added.
   */
  modifier checkIfNotAddedUser() {
    bytes memory tempNotAddedUsername = bytes(username);
    require(tempNotAddedUsername.length == 0);
    _;
  }

  /**
   * @dev Check if user is already added.
   */
  modifier checkIfAddedUser() {
    bytes memory tempAddedUsername = bytes(username);
    require(tempAddedUsername.length > 0);
    _;
  }

  /**
   * @dev Checks if account has funds.
   */
  modifier hasFunds() {
    require(balance > 0);
    _;
  }

  /**
   * @dev Checks if its one time transaction.
   * @param _transactionType TransactionType Type of transaction.
   */
  modifier isOneTimeTransaction(TransactionType _transactionType) {
    require(_transactionType == TransactionType.OneTime);
    _;
  }

  /**
   * @dev Checks if its not one time transaction.
   * @param _transactionType TransactionType Type of transaction.
   */
  modifier isNotOneTimeTransaction(TransactionType _transactionType) {
    require(_transactionType != TransactionType.OneTime);
    _;
  }

  /**
   * @dev Calculate used gas.
   * Calculation of the used gas which is used for every function,
   * that executes some kind of interaction with Smart Contract and adds on calculation amount of gas used so far.
   * Using usedGas variable to store total amount of gas used and gasCost variable to store total amount of gas value,
   * used so far (including the current function being run).
   */
  modifier calculateGasCost() {
    remainingGasStart = gasleft();
    _;
    remainingGasEnd = gasleft();
    usedGas = remainingGasStart - remainingGasEnd;
    usedGas += 21000 + 9700;
    gasCost += (usedGas * tx.gasprice);
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
   * Fired when session data is added/changed.
   */
  event SessionEvent(address indexed deviceId, string dataId, SessionState state);

  /**
   * Transfer event.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * Recovered address event.
   */
  event RecoveredAddress(bytes32 messageHash, bytes sig, address recoveredAddress);

  /**
   * Signed message event.
   */
  event SignedMessage(bytes32 messageHash, bytes32 signedMessage);

  /**
   * Gas refund event.
   */
  event GasRefundEvent(address indexed from, address to, uint256 gasCost);

  /**
   * Contract destroyed event.
   */
  event ContractDestroyed(address contractOwner);

  /**
   * @dev Proxy Wallet constructor.
   * @param _administrators address[] List of administrator addresses.
   * @param _username string Username of the user.
   * @param _publicKey string Public key of the user.
   */
  constructor(address[] _administrators, string _username, string _publicKey) onlyValidAdministrators(_administrators) checkIfNotAddedUser() public {
    owner = msg.sender;
    balance = address(msg.sender).balance;
    for (uint256 i = 0; i < _administrators.length; i++) {
      addAdministrator(_administrators[i]);
    }
    setNewUsername(_username);
    setNewUserPublicKey(_publicKey);
  }

  /**
   * @dev Set username of the user/app.
   * @param _username string Username of the user.
   */
  function setNewUsername(string _username) onlyValidUsername(_username) calculateGasCost public {
    username = _username;
    emit UsernameSet(msg.sender, _username);
  }

  /**
   * @dev Set user/app public key.
   * @param _publicKey string Public key of the user.
   */
  function setNewUserPublicKey(string _publicKey) onlyValidPublicKey(_publicKey) calculateGasCost public {
    userPublicKey = _publicKey;
    emit PublicKeySet(msg.sender, _publicKey);
  }

  /**
   * @dev Add session data and start session.
   * @param _dataId string Data id value.
   * @param _deviceId string Device id value.
   * @param _first string First key.
   * @param _second string Second key.
   * @param _hashed bytes32 Hashed value.
   * @param _subject string Description/subject value.
   * @param r bytes32 Signature r param.
   * @param s bytes32 Signature s param.
   * @param v uint8 Signature v param.
   * @param _startTime uint256 Session start time value.
   * @param _duration uint256 Session length value.
   */
  function startSession(string _dataId, address _deviceId, string _first, string _second, bytes32 _hashed, string _subject, bytes32 r, bytes32 s, uint8 v, uint256 _startTime, uint256 _duration) checkIfAddedUser isNotOneTimeTransaction(TransactionType.Session) calculateGasCost public {
    sessionData[_dataId] = Data(_deviceId, _first, _second, _subject, _hashed, r, s, v, Times(_startTime, _duration), SessionState.Active, TransactionType.Session);
    emit SessionEvent(_deviceId, _dataId, SessionState.Active);
  }

  /**
   * @dev Close session.
   * @param _dataId string Data id value.
   */
  function closeSession(string _dataId) checkIfAddedUser calculateGasCost public {
    require(sessionData[_dataId].deviceId != 0);
    if (checkSessionState(_dataId) == SessionState.Active) {
      address deviceId = sessionData[_dataId].deviceId;
      delete sessionData[_dataId];
      emit SessionEvent(deviceId, _dataId, SessionState.Closed);
    }
  }

  /**
   * @dev Check if session is active or closed.
   * @param _dataId string Data id value.
   * @return SessionState State of the session.
   */
  function checkSessionState(string _dataId) calculateGasCost public returns (SessionState) {
    require(sessionData[_dataId].state == SessionState.Active || sessionData[_dataId].state == SessionState.Closed);
    emit SessionEvent(sessionData[_dataId].deviceId, _dataId, sessionData[_dataId].state);
    return sessionData[_dataId].state;
  }

  /**
   * @dev Add a new administrator to the contract.
   * @param _admin address The address of the administrator to add.
   */
  function addAdministrator(address _admin) isOwner calculateGasCost public {
    require(!isAdministrator[_admin]);
    administrators.push(_admin);
    isAdministrator[_admin] = true;
    emit AdministratorAdded(_admin);
  }

  /**
   * @dev Get all administrator addresses.
   * @param _id uint256 Id of the administrator.
   * @return address Administrators address.
   */
  function getAdministrator(uint256 _id) onlyValidAdministrators(administrators) calculateGasCost public returns (address) {
    require(isAdministrator[administrators[_id]]);
    return administrators[_id];
  }

  /**
   * @dev Get all administrator addresses.
   * @return address[] List of all administrators.
   */
  function getAllAdministrators() calculateGasCost public returns (address[]) {
    return administrators;
  }

  /**
   * @dev Get all administrators length.
   * @return uint Number of all administrators.
   */
  function getAdministratorsCount() public constant returns (uint) {
    return administrators.length;
  }

  /**
   * @dev Get public key value from session data.
   * @param _dataId string Data id value used as index to find data from session.
   * @return string, string First and second key from session data.
   */
  function getPublicKeyFromSession(string _dataId) calculateGasCost public returns (string, string) {
    return (sessionData[_dataId].keyOne, sessionData[_dataId].keyTwo);
  }

  /**
   * @dev Get user stored public key of given address.
   * @return string User stored public key.
   */
  function getPublicKey() checkIfAddedUser calculateGasCost public returns (string) {
    return userPublicKey;
  }

  /**
   * @dev Get user stored username of given address.
   * @return string User stored username.
   */
  function getUsername() checkIfAddedUser calculateGasCost public returns (string) {
    return username;
  }

  /**
   * @dev Get signature value from session data.
   * @param _dataId string Data id value used as index to find data from session.
   * @return bytes32, bytes32, uint8 Signature data.
   */
  function getSignature(string _dataId) checkIfAddedUser calculateGasCost public returns (bytes32, bytes32, uint8)  {
    return (sessionData[_dataId].r, sessionData[_dataId].s, sessionData[_dataId].v);
  }

  /**
   * @dev Get other session data from session data.
   * @param _dataId string Data id value used as index to find data from session.
   * @return address, string, bytes32, uint256, uint256, SessionState, TransactionType Device id, subject, hashed data, start time, duration value, user data, session state and transaction type from session.
   */
  function getOtherSessionData(string _dataId) checkIfAddedUser calculateGasCost public returns (address, string, bytes32, uint256, uint256, SessionState, TransactionType)  {
    return (sessionData[_dataId].deviceId, sessionData[_dataId].subject, sessionData[_dataId].hashedData, sessionData[_dataId].times.startTime, sessionData[_dataId].times.duration, sessionData[_dataId].state, sessionData[_dataId].transactionType);
  }

  /**
   * @dev Get current total gas cost.
   * @return uint256 Current gas cost.
   */
  function getCurrentSpentGas() public view returns (uint256) {
    return gasCost;
  }

  /**
   * @dev Sign message address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be signed.
   * @return bytes32 Encoded message.
   */
  function signMessage(bytes32 _messageHash) calculateGasCost public returns (bytes32) {
    bytes32 result = _messageHash.toEthSignedMessageHash();
    emit SignedMessage(_messageHash, result);
    return result;
  }

  /**
   * @dev Recover address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be checked.
   * @param _sig bytes Signature hashed value.
   * @return address Returning address which signed the message.
   */
  function recoverAddress(bytes32 _messageHash, bytes _sig) calculateGasCost public returns (address) {
    address result = _messageHash.recover(_sig);
    emit RecoveredAddress(_messageHash, _sig, result);
    return result;
  }

  /**
   * @dev Check if the given address signed the message.
   * @param _address address Address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be checked.
   * @param _sig bytes Signature message.
   * @return bool True if the given address signed the message.
   */
  function isSignedMessage(address _address, bytes32 _messageHash, bytes _sig) calculateGasCost internal returns (bool) {
    return recoverAddress(_messageHash, _sig) == _address;
  }

  /**
   * @dev Get balance of the account.
   * @param _address address Address of account which balanced needs to be returned.
   * @return uint256 Balance of the account.
   */
  function getBalance(address _address) calculateGasCost public returns (uint256) {
    return address(_address).balance;
  }

  /**
   * @dev Check if the account has exact same balance like give balance.
   * @param _address address Account address.
   * @param _balance uint256 Give balance to compare with.
   * @return True if the account balance has the exact same balance like give balance.
   */
  function checkIfAccountHasExactBalance(address _address, uint256 _balance) calculateGasCost public returns (bool) {
    return getBalance(_address) == _balance;
  }

  /**
   * @dev Check if its one time transaction and execute transfer.
   * @param _to address The address to transfer to.
   * @param _value uint256 The amount to be transferred.
   * @return bool True if the function was executed successfully.
   */
  function executeOneTimeTransaction(address _to, uint256 _value) isOneTimeTransaction(TransactionType.OneTime) public returns (bool) {
    transfer(_to, _value);
  }

  /**
   * @dev Transfer funds for a specified address.
   * @param _to address The address to transfer to.
   * @param _value uint256 The amount to be transferred.
   * @return bool True if the function was executed successfully.
   */
  function transfer(address _to, uint256 _value) calculateGasCost public payable returns (bool) {
    require(owner != address(0));
    require(_to != address(0));
    require(_value <= getBalance(owner));
    _to.transfer(_value);
    emit Transfer(owner, _to, _value);
    return true;
  }

  /**
   * @dev Refund total cast costs to authorized admin address.
   * @param _admin address The address of admin.
   * @return bool True if the function was executed successfully.
   */
  function refundGasCosts(address _admin) isAuthorizedAdmin(_admin) public returns (bool) {
    transfer(_admin, gasCost);
    emit GasRefundEvent(owner, _admin, gasCost);
  }

  /**
   * @dev Destroy the contract.
   */
  function kill() isOwner public {
    emit ContractDestroyed(msg.sender);
    selfdestruct(msg.sender);
  }
}
