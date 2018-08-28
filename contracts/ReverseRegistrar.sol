pragma solidity ^0.4.24;

import './ENSRegistry.sol';
import './PublicResolver.sol';

/**
 * @title Reverse Registrar Smart Contract.
 * @author Tap Trust
 * @dev Implementation of a resolver for reverse records,
 * which permits only the owner to update it.
 */
contract ReverseRegistrar {

  // namehash('addr.reverse')
  bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

  ENSRegistry public ens;

  PublicResolver public defaultResolver;

  /**
   * @dev Constructor
   * @param ensAddr ENS The address of the ENS registry.
   * @param resolverAddr Resolver The address of the default reverse resolver.
   */
  constructor(ENSRegistry ensAddr, PublicResolver resolverAddr) public {
    ens = ensAddr;
    defaultResolver = resolverAddr;

    // Assign ownership of the reverse record to our deployer
    ReverseRegistrar oldRegistrar = ReverseRegistrar(ens.getOwner(ADDR_REVERSE_NODE));
    if (address(oldRegistrar) != 0) {
      oldRegistrar.claim(msg.sender);
    }
  }

  /**
   * @dev Transfers ownership of the reverse ENS record associated with the calling account.
   * @param owner address The address to set as the owner of the reverse record in ENS.
   * @return bytes32 The ENS node hash of the reverse record.
   */
  function claim(address owner) public returns (bytes32) {
    return claimWithResolver(owner, 0);
  }

  /**
   * @dev Transfers ownership of the reverse ENS record associated with the calling account.
   * @param owner address The address to set as the owner of the reverse record in ENS.
   * @param resolver address The address of the resolver to set; 0 to leave unchanged.
   * @return bytes32 The ENS node hash of the reverse record.
   */
  function claimWithResolver(address owner, address resolver) public returns (bytes32) {
    bytes32 label = sha3HexAddress(msg.sender);
    bytes32 node = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
    address currentOwner = ens.getOwner(node);

    // Update the resolver if required
    if (resolver != 0 && resolver != ens.getResolver(node)) {
      // Transfer the name to us first if it's not already
      if (currentOwner != address(this)) {
        ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, this);
        currentOwner = address(this);
      }
      ens.setResolver(node, resolver);
    }

    // Update the owner if required
    if (currentOwner != owner) {
      ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, owner);
    }

    return node;
  }

  /**
   * @dev Sets the `name()` record for the reverse ENS record associated with
   * the calling account. First updates the resolver to the default reverse
   * resolver if necessary.
   * @param name string The name to set for this address.
   * @return bytes32 The ENS node hash of the reverse record.
   */
  function setName(string name) public returns (bytes32) {
    bytes32 node = claimWithResolver(this, defaultResolver);
    defaultResolver.setName(node, name);
    return node;
  }

  /**
   * @dev Returns the node hash for a given account's reverse records.
   * @param addr address The address to hash.
   * @return bytes32 The ENS node hash.
   */
  function node(address addr) public returns (bytes32) {
    return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
  }

  /**
   * @dev An optimised function to compute the sha3 of the lower-case.
   * hexadecimal representation of an Ethereum address.
   * @param addr address The address to hash
   * @return bytes32 The SHA3 hash of the lower-case hexadecimal encoding of the input address.
   */
  function sha3HexAddress(address addr) private returns (bytes32 ret) {
    addr;
    ret;
    assembly {
      let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000
      let i := 40
      loop :
      i := sub(i, 1)
      mstore8(i, byte(and(addr, 0xf), lookup))
      addr := div(addr, 0x10)
      i := sub(i, 1)
      mstore8(i, byte(and(addr, 0xf), lookup))
      addr := div(addr, 0x10)
      jumpi(loop, i)
      ret := keccak256(0, 40)
    }
  }
}
