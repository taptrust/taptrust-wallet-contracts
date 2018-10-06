pragma solidity ^0.4.24;

contract ENSRegistry {

  struct AccountRecord {
    address owner;
    address resolver;
    uint64 ttl;
  }

  // Account registry mapping.
  mapping(bytes32 => AccountRecord) accountRegistry;

  /*
   * @dev Permits modifications only by the owner of the specified node.
   * @param _node bytes32 Node param.
   */
  modifier only_owner(bytes32 _node) {
    require(accountRegistry[_node].owner == msg.sender);
    _;
  }

  /**
   * @dev ENS Registry constructor.
   * @param _administrator address Administrator address.
   */
  constructor(address _administrator) public {
    accountRegistry['admin'].owner = _administrator;
  }
}
