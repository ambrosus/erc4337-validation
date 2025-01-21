pragma solidity ^0.8.17;

contract InitializableScript {
  error NotInitialized();

  bool internal initialized;

  modifier initializedOnly() {
    if (!initialized) revert NotInitialized();
    _;
  }

}
