pragma solidity ^0.4.24;

import './ENSRegistry.sol';

/**
 * @title Public Resolver Smart Contract.
 * @author Tap Trust
 * @dev Only allows the owner of a node to set its
 * address.
 */
contract PublicResolver {

  bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
  bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
  bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
  bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
  bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
  bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
  bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;
  bytes4 constant MULTIHASH_INTERFACE_ID = 0xe89401a1;

  event AddressChanged(bytes32 indexed node, address a);

  event ContentChanged(bytes32 indexed node, bytes32 hash);

  event NameChanged(bytes32 indexed node, string name);

  event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

  event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

  event TextChanged(bytes32 indexed node, string indexedKey, string key);

  event MultihashChanged(bytes32 indexed node, bytes hash);

  struct PublicKey {
    bytes32 x;
    bytes32 y;
  }

  struct AccountRecord {
    address addr;
    bytes32 content;
    string name;
    PublicKey pubkey;
    mapping(string => string) text;
    mapping(uint256 => bytes) abis;
    bytes multihash;
  }

  ENSRegistry ens;

  mapping(bytes32 => AccountRecord) accountRegistry;

  modifier only_owner(bytes32 node) {
    require(ens.getOwner(node) == msg.sender);
    _;
  }

  /**
   * @dev Public Resolver Constructor.
   * @param ensAddress ENS The ENS registrar contract.
   */
  constructor(ENSRegistry ensAddress) public {
    ens = ensAddress;
  }

  /**
   * @dev Sets the address associated with an ENS node.
   * May only be called by the owner of that node in the ENS registry.
   * @param node bytes32 The node to update.
   * @param addr address The address to set.
   */
  function setAddr(bytes32 node, address addr) public only_owner(node) {
    accountRegistry[node].addr = addr;
    emit AddressChanged(node, addr);
  }

  /**
   * @dev Sets the content hash associated with an ENS node.
   * May only be called by the owner of that node in the ENS registry.
   * Note that this resource type is not standardized, and will likely change
   * in future to a resource type based on multihash.
   * @param node bytes32 The node to update.
   * @param hash bytes32 The content hash to set.
   */
  function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
    accountRegistry[node].content = hash;
    emit ContentChanged(node, hash);
  }

  /**
   * @dev Sets the multihash associated with an ENS node.
   * May only be called by the owner of that node in the ENS registry.
   * @param node bytes32 The node to update.
   * @param hash bytes The multihash to set.
   */
  function setMultihash(bytes32 node, bytes hash) public only_owner(node) {
    accountRegistry[node].multihash = hash;
    emit MultihashChanged(node, hash);
  }

  /**
   * @dev Sets the name associated with an ENS node, for reverse records.
   * May only be called by the owner of that node in the ENS registry.
   * @param node bytes32 The node to update.
   * @param name string The name to set.
   */
  function setName(bytes32 node, string name) public only_owner(node) {
    accountRegistry[node].name = name;
    emit NameChanged(node, name);
  }

  /**
   * @dev Sets the ABI associated with an ENS node.
   * Nodes may have one ABI of each content type. To remove an ABI, set it to
   * the empty string.
   * @param node bytes32 The node to update.
   * @param contentType uint256 The content type of the ABI.
   * @param data bytes The ABI data.
   */
  function setABI(bytes32 node, uint256 contentType, bytes data) public only_owner(node) {
    // Content types must be powers of 2
    require(((contentType - 1) & contentType) == 0);

    accountRegistry[node].abis[contentType] = data;
    emit ABIChanged(node, contentType);
  }

  /**
   * @dev Sets the SECP256k1 public key associated with an ENS node.
   * @param node bytes32 The ENS node to query.
   * @param x bytes32 the X coordinate of the curve point for the public key.
   * @param y bytes32 the Y coordinate of the curve point for the public key.
   */
  function setPubkey(bytes32 node, bytes32 x, bytes32 y) public only_owner(node) {
    accountRegistry[node].pubkey = PublicKey(x, y);
    emit PubkeyChanged(node, x, y);
  }

  /**
   * @dev Sets the text data associated with an ENS node and key.
   * May only be called by the owner of that node in the ENS registry.
   * @param node bytes32 The node to update.
   * @param key string The key to set.
   * @param value string The text data value to set.
   */
  function setText(bytes32 node, string key, string value) public only_owner(node) {
    accountRegistry[node].text[key] = value;
    emit TextChanged(node, key, key);
  }

  /**
   * @dev Returns the text data associated with an ENS node and key.
   * @param node bytes32 The ENS node to query.
   * @param key string The text data key to query.
   * @return string The associated text data.
   */
  function text(bytes32 node, string key) public view returns (string) {
    return accountRegistry[node].text[key];
  }

  /**
   * @dev Returns the SECP256k1 public key associated with an ENS node.
   * Defined in EIP 619.
   * @param node bytes32 The ENS node to query.
   * @return x bytes32 the X coordinate of the curve point for the public key.
   * @return y bytes32 the Y coordinate of the curve point for the public key.
   */
  function pubkey(bytes32 node) public view returns (bytes32 x, bytes32 y) {
    return (accountRegistry[node].pubkey.x, accountRegistry[node].pubkey.y);
  }

  /**
   * @dev Returns the ABI associated with an ENS node.
   * Defined in EIP205.
   * @param node bytes32 The ENS node to query.
   * @param contentTypes uint256 A bitwise OR of the ABI formats accepted by the caller.
   * @return contentType uint256 The content type of the return value.
   * @return data bytes The ABI data.
   */
  function ABI(bytes32 node, uint256 contentTypes) public view returns (uint256 contentType, bytes data) {
    AccountRecord storage accountRecord = accountRegistry[node];
    for (contentType = 1; contentType <= contentTypes; contentType <<= 1) {
      if ((contentType & contentTypes) != 0 && accountRecord.abis[contentType].length > 0) {
        data = accountRecord.abis[contentType];
        return;
      }
    }
    contentType = 0;
  }

  /**
   * @dev Returns the name associated with an ENS node, for reverse records.
   * Defined in EIP181.
   * @param node bytes32 The ENS node to query.
   * @return string The associated name.
   */
  function name(bytes32 node) public view returns (string) {
    return accountRegistry[node].name;
  }

  /**
   * @dev Returns the content hash associated with an ENS node.
   * Note that this resource type is not standardized, and will likely change
   * in future to a resource type based on multihash.
   * @param node bytes32 The ENS node to query.
   * @return bytes32 The associated content hash.
   */
  function content(bytes32 node) public view returns (bytes32) {
    return accountRegistry[node].content;
  }

  /**
   * @dev Returns the multihash associated with an ENS node.
   * @param node bytes32 The ENS node to query.
   * @return bytes The associated multihash.
   */
  function multihash(bytes32 node) public view returns (bytes) {
    return accountRegistry[node].multihash;
  }

  /**
   * @dev Returns the address associated with an ENS node.
   * @param node bytes32 The ENS node to query.
   * @return address The associated address.
   */
  function addr(bytes32 node) public view returns (address) {
    return accountRegistry[node].addr;
  }

  /**
   * @dev Returns true if the resolver implements the interface specified by the provided hash.
   * @param interfaceID bytes4 The ID of the interface to check for.
   * @return bool True if the contract implements the requested interface.
   */
  function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
    return interfaceID == ADDR_INTERFACE_ID ||
    interfaceID == CONTENT_INTERFACE_ID ||
    interfaceID == NAME_INTERFACE_ID ||
    interfaceID == ABI_INTERFACE_ID ||
    interfaceID == PUBKEY_INTERFACE_ID ||
    interfaceID == TEXT_INTERFACE_ID ||
    interfaceID == MULTIHASH_INTERFACE_ID ||
    interfaceID == INTERFACE_META_ID;
  }
}
