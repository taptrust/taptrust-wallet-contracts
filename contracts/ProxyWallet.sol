pragma solidity ^0.4.24;

import './ECRecovery.sol';
import './SafeMath.sol';

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

  // Using SafeMath library for math expressions
  using SafeMath for uint256;

  // Hooking up bytes32 with ERRecovery library
  using ECRecovery for bytes32;

  // Owner of the contract
  address public owner;

  // Session state
  enum SessionState {Active, Closed}

  // Transaction type
  enum TransactionType {OneTime, Session}

  // User data structure
  struct UserData {
    string username;
    string userPublicKey;
  }

  // Times data structure
  struct Times {
    uint256 startTime;
    uint256 duration;
  }

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
    Times times;
    SessionState state;
    TransactionType transactionType;
  }

  // Users data mapping
  mapping(string => UserData) private users;

  // Session data mapping
  mapping(string => Data) private sessionData;

  // List of administrator addresses
  address[] public administrators;

  // List of administrator checks for each address
  mapping(address => bool) public isAdministrator;

  // Start gas value
  uint256 remainingGasStart;

  // Spent gas value
  uint256 remainingGasEnd;

  // Used gas calculation
  uint256 usedGas;

  // Total cost of gas for all methods
  uint256 gasCost;

  /**
   * @dev Requires a valid owner of the contract.
   */
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Checks if the admin is correct and belongs to list of administrators
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
   * @dev Check if user is not already added to users mapping.
   * @param dataId string Data id value.
   */
  modifier checkIfNotAddedUser(string dataId) {
    require(bytes(users[dataId].username).length == 0);
    _;
  }

  /**
   * @dev Check if user is already added to users mapping.
   * @param dataId string Data id value.
   */
  modifier checkIfAddedUser(string dataId) {
    require(bytes(users[dataId].username).length > 0);
    _;
  }

  /**
   * @dev Checks if account has funds.
   * @param _address address Address of the account which balance needs to be checked.
   */
  modifier hasFunds(address _address) {
    require(address(_address).balance > 0);
    _;
  }

  /**
   * @dev Checks if its one time transaction
   * @param _transactionType TransactionType Type of transaction
   */
  modifier isOneTimeTransaction(TransactionType _transactionType) {
    require(_transactionType == TransactionType.OneTime);
    _;
  }

  /**
   * @dev Checks if its not one time transaction
   * @param _transactionType TransactionType Type of transaction
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
   * used so far (including the current function being run)
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
   * Fired when session data is added/changed
   */
  event SessionEvent(address indexed deviceId, string dataId, SessionState state);

  /**
   * Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * Gas refund event
   */
  event GasRefundEvent(address sender);

  /**
   * @dev Proxy Wallet constructor.
   * @param _administrators address[] List of administrator addresses.
   */
  constructor(address[] _administrators) onlyValidAdministrators(_administrators) public {
    owner = msg.sender;
    for (uint256 i = 0; i < _administrators.length; i++) {
      addAdministrator(_administrators[i]);
    }
  }

  /**
   * @dev Set new user.
   * @param dataId Data id value.
   * @param _username string Username of the user.
   * @param _publicKey string Public key of the user.
   */
  function setNewUser(string dataId, string _username, string _publicKey) checkIfNotAddedUser(dataId) calculateGasCost public {
    setNewUsername(dataId, _username);
    setNewUserPublicKey(dataId, _publicKey);
  }

  /**
   * @dev Set username of the user/app.
   * @param dataId Data id value.
   * @param _username string Username of the user.
   */
  function setNewUsername(string dataId, string _username) onlyValidUsername(_username) calculateGasCost public {
    users[dataId].username = _username;
    emit UsernameSet(msg.sender, _username);
  }

  /**
   * @dev Set user/app public key.
   * @param dataId Data id value.
   * @param _publicKey string Public key of the user.
   */
  function setNewUserPublicKey(string dataId, string _publicKey) onlyValidPublicKey(_publicKey) calculateGasCost public {
    users[dataId].userPublicKey = _publicKey;
    emit PublicKeySet(msg.sender, _publicKey);
  }

  /**
   * @dev Add session data and start session
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
  function startSession(string dataId, address deviceId, bytes32 first, bytes32 second, bytes32 hashed, string subject, bytes32 r, bytes32 s, uint8 v, uint256 startTime, uint256 duration) checkIfAddedUser(dataId) isNotOneTimeTransaction(TransactionType.Session) calculateGasCost public {
    sessionData[dataId] = Data(deviceId, first, second, subject, hashed, r, s, v, Times(startTime, duration), SessionState.Active, TransactionType.Session);
    emit SessionEvent(deviceId, dataId, SessionState.Active);
  }

  /**
   * @dev Close session.
   * @param dataId string Data id value.
   */
  function closeSession(string dataId) checkIfAddedUser(dataId) calculateGasCost public {
    require(sessionData[dataId].deviceId != 0);
    address deviceId = sessionData[dataId].deviceId;
    delete sessionData[dataId];
    emit SessionEvent(deviceId, dataId, SessionState.Closed);
  }

  /**
   * @dev Check if session is active or closed.
   * @param dataId string Data id value.
   * @return SessionState State of the session.
   */
  function checkSessionState(string dataId) calculateGasCost public returns (SessionState) {
    require(sessionData[dataId].state == SessionState.Active || sessionData[dataId].state == SessionState.Closed);
    return sessionData[dataId].state;
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
   * @param dataId string Data id value used as index to find data from session.
   * @return bytes32, bytes32 First and second key from session data.
   */
  function getPublicKeyFromSession(string dataId) calculateGasCost public returns (bytes32, bytes32) {
    return (sessionData[dataId].keyOne, sessionData[dataId].keyTwo);
  }

  /**
   * @dev Get user stored public key of given address.
   * @param dataId string Data id value used as index to find data from list of users.
   * @return string User stored public key.
   */
  function getPublicKey(string dataId) checkIfAddedUser(dataId) calculateGasCost public returns (string) {
    return users[dataId].userPublicKey;
  }

  /**
   * @dev Get user stored username of given address.
   * @param dataId string Data id value used as index to find data from list of users.
   * @return string User stored username.
   */
  function getUsername(string dataId) checkIfAddedUser(dataId) calculateGasCost public returns (string) {
    return users[dataId].username;
  }

  /**
   * @dev Get signature value from session data.
   * @param dataId string Data id value used as index to find data from session.
   * @return bytes32, bytes32, uint8 Signature data.
   */
  function getSignature(string dataId) checkIfAddedUser(dataId) calculateGasCost public returns (bytes32, bytes32, uint8)  {
    return (sessionData[dataId].r, sessionData[dataId].s, sessionData[dataId].v);
  }

  /**
   * @dev Get other session data from session data.
   * @param dataId string Data id value used as index to find data from session.
   * @return address, string, bytes32, uint256, uint256, SessionState, TransactionType Device id, subject, hashed data, start time, duration value, user data, session state and transaction type from session.
   */
  function getOtherSessionData(string dataId) checkIfAddedUser(dataId) calculateGasCost public returns (address, string, bytes32, uint256, uint256, SessionState, TransactionType)  {
    return (sessionData[dataId].deviceId, sessionData[dataId].subject, sessionData[dataId].hashedData, sessionData[dataId].times.startTime, sessionData[dataId].times.duration, sessionData[dataId].state, sessionData[dataId].transactionType);
  }

  /**
   * @dev Sign message address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be signed.
   * @return bytes32 Encoded message.
   */
  function signMessage(bytes32 _messageHash) calculateGasCost public returns (bytes32) {
    return _messageHash.toEthSignedMessageHash();
  }

  /**
   * @dev Recover address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be checked.
   * @param _sig bytes Signature hashed value.
   * @return address Returning address which signed the message.
   */
  function recoverAddress(bytes32 _messageHash, bytes _sig) calculateGasCost public returns (address) {
    return _messageHash.recover(_sig);
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
  function transfer(address _to, uint256 _value) calculateGasCost public returns (bool) {
    require(_to != address(0));
    require(_value <= getBalance(msg.sender));
    uint256 ownerBalance = address(msg.sender).balance;
    uint256 receiverBalance = address(_to).balance;
    ownerBalance = ownerBalance.sub(_value);
    receiverBalance = receiverBalance.add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Refund total cast costs to authorized admin address.
   * @param _admin address The address of admin.
   * @return bool True if the function was executed successfully.
   */
  function refundGasCosts(address _admin) isAuthorizedAdmin(_admin) public returns (bool) {
    transfer(_admin, gasCost);
    emit GasRefundEvent(msg.sender);
  }

  /**
   * @dev Destroy the contract.
   */
  function kill() isOwner public {
    selfdestruct(msg.sender);
  }
}
