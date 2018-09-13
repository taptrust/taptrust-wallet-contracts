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
    SessionState state;
    string username;
    string userPublicKey;
    TransactionType transactionType;
  }

  // Session data instance
  mapping(string => Data) private sessionData;

  // List of administrator addresses
  address[] public administrators;

  // List of administrator checks for each address
  mapping(address => bool) public isAdministrator;

  // Start gas value
  uint256 public startGas;

  // Spent gas value
  uint256 public spentGas;

  // Total gas costs
  uint256 public totalGasCosts;

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
      addAdministrator(administrators[i]);
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
   * @dev Refund used gas.
   */
  modifier refundGasCost() {
    uint256 remainingGasStart = gasleft();
    _;
    uint256 remainingGasEnd = gasleft();
    uint256 usedGas = remainingGasStart - remainingGasEnd;
    usedGas += 21000 + 9700;

    uint256 gasCost = usedGas * tx.gasprice;

    tx.origin.transfer(gasCost);
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
  event SessionEvent(address indexed deviceId, string indexed dataId, SessionState state);

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
    startGas = gasleft();

    owner = msg.sender;

    for (uint256 i = 0; i < _administrators.length; i++) {
      addAdministrator(_administrators[i]);
    }
    spentGas = startGas - gasleft();
    totalGasCosts += spentGas;
  }

  /**
   * @dev Set username of the user/app.
   * @param dataId Data id value.
   * @param _username string Username of the user.
   */
  function setUsername(string dataId, string _username) onlyValidUsername(_username) public {
    if (checkSessionState(dataId) == SessionState.Active) {
      sessionData[dataId].username = _username;
      emit UsernameSet(msg.sender, _username);
    }
  }

  /**
   * @dev Set user/app public key.
   * @param dataId Data id value.
   * @param _publicKey string Public key of the user.
   */
  function setUserPublicKey(string dataId, string _publicKey) onlyValidPublicKey(_publicKey) public {
    if (checkSessionState(dataId) == SessionState.Active) {
      sessionData[dataId].userPublicKey = _publicKey;
      emit UsernameSet(msg.sender, _publicKey);
    }
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
  function addSessionData(string dataId, address deviceId, bytes32 first, bytes32 second, bytes32 hashed, string subject, bytes32 r, bytes32 s, uint8 v, uint256 startTime, uint256 duration, TransactionType transactionType) isOwner isNotOneTimeTransaction(transactionType) public {
    startGas = gasleft();
    sessionData[dataId] = Data(deviceId, first, second, subject, hashed, r, s, v, startTime, duration, SessionState.Active, transactionType, '', '');
    spentGas = startGas - gasleft();
    totalGasCosts += spentGas;
    emit SessionEvent(deviceId, dataId, SessionState.Active);
  }

  /**
   * @dev Close session.
   * @param dataId string Data id value.
   */
  function closeSession(string dataId) isOwner public {
    startGas = gasleft();
    require(sessionData[dataId].deviceId != 0);
    address deviceId = sessionData[dataId].deviceId;
    delete sessionData[dataId];
    spentGas = startGas - gasleft();
    totalGasCosts += spentGas;
    emit SessionEvent(deviceId, dataId, SessionState.Closed);
  }

  /**
   * @dev Check if session is active or closed.
   * @param dataId string Data id value.
   * @return SessionState State of the session.
   */
  function checkSessionState(string dataId) public returns (SessionState) {
    startGas = gasleft();
    require(sessionData[dataId].state == SessionState.Active || sessionData[dataId].state == SessionState.Closed);
    spentGas = startGas - gasleft();
    totalGasCosts += spentGas;
    return sessionData[dataId].state;
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
   * @return address, string, bytes32, uint256, uint256 Device id, subject, hashed data, start time, duration values, session state and transaction type form session.
   */
  function getOtherSessionData(string dataId) public constant returns (address, string, bytes32, uint256, uint256, SessionState, TransactionType)  {
    return (sessionData[dataId].deviceId, sessionData[dataId].subject, sessionData[dataId].hashedData, sessionData[dataId].startTime, sessionData[dataId].duration, sessionData[dataId].state, sessionData[dataId].transactionType);
  }

  /**
   * @dev Sign message address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be signed.
   * @return bytes32 Encoded message.
   */
  function signMessage(bytes32 _messageHash) public pure returns (bytes32) {
    return _messageHash.toEthSignedMessageHash();
  }

  /**
   * @dev Recover address which signed the message.
   * @param _messageHash bytes32 Hashed message that needs to be checked.
   * @param _sig bytes Signature hashed value.
   * @return address Returning address which signed the message.
   */
  function recoverAddress(bytes32 _messageHash, bytes _sig) public pure returns (address) {
    return _messageHash.recover(_sig);
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
   * @dev Get balance of the account.
   * @param _address address Address of account which balanced needs to be returned.
   * @return uint256 Balance of the account.
   */
  function getBalance(address _address) public view returns (uint256) {
    return address(_address).balance;
  }

  /**
   * @dev Check if the account has exact same balance like give balance.
   * @param _address address Account address.
   * @param _balance uint256 Give balance to compare with.
   * @return True if the account balance has the exact same balance like give balance.
   */
  function checkIfAccountHasExactBalance(address _address, uint256 _balance) public view returns (bool) {
    return getBalance(_address) == _balance;
  }

  /**
   * @dev Check if its one time transaction and execute transfer.
   * @param _transactionType TransactionType Transaction type (one time transaction, session timed transaction)
   * @param _to address The address to transfer to.
   * @param _value uint256 The amount to be transferred.
   * @return bool True if the function was executed successfully.
   */
  function checkIfOneTimeTransaction(TransactionType _transactionType, address _to, uint256 _value) isOneTimeTransaction(_transactionType) public returns (bool) {
    transfer(_to, _value);
  }

  /**
   * @dev Transfer funds for a specified address.
   * @param _to address The address to transfer to.
   * @param _value uint256 The amount to be transferred.
   * @return bool True if the function was executed successfully.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    startGas = gasleft();
    require(_to != address(0));
    require(_value <= getBalance(msg.sender));
    uint256 ownerBalance = address(msg.sender).balance;
    uint256 receiverBalance = address(_to).balance;
    ownerBalance = ownerBalance.sub(_value);
    receiverBalance = receiverBalance.add(_value);
    spentGas = startGas - gasleft();
    totalGasCosts += spentGas;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Refund total cast costs to authorized admin address.
   * @param _admin address The address of admin.
   * @return bool True if the function was executed successfully.
   */
  function refundGasCosts(address _admin) isOwner isAuthorizedAdmin(_admin) public returns (bool) {
    transfer(_admin, totalGasCosts);
  }

  /**
   * @dev Refund gas cost function.
   */
  function refundGasCostFunction() external refundGasCost {
    emit GasRefundEvent(msg.sender);
  }


  /**
   * @dev Destroy the contract.
   */
  function kill() isOwner public {
    selfdestruct(msg.sender);
  }
}
