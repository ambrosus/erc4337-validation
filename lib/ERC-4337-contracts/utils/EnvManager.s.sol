pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";

contract EnvManager is Script {
  error InvalidChain();

  function initChains() internal {
    // Init airdao chains
    Chain memory mainnet = Chain({name: "mainnet", chainId: 16718, chainAlias: "mainnet", rpcUrl: "https://network.ambrosus.io"});
    Chain memory testnet = Chain({name: "testnet", chainId: 22040, chainAlias: "testnet", rpcUrl: "https://network.ambrosus-test.io"});
    Chain memory devnet = Chain({name: "devnet", chainId: 30746, chainAlias: "devnet", rpcUrl: "https://network.ambrosus-dev.io"});
    setChain("mainnet", mainnet);
    setChain("testnet", testnet);
    setChain("devnet", devnet);
  }

  function setupDeployer() internal view returns (uint256 privateKey) {
    if (block.chainid == 31337) {
      string memory root = vm.projectRoot();
      string memory path = string.concat(root, "/localhost.json");
      string memory json = vm.readFile(path);
      bytes memory mnemonicBytes = vm.parseJson(json, ".wallet.mnemonic");
      string memory mnemonic = abi.decode(mnemonicBytes, (string));
      return vm.deriveKey(mnemonic, 0);
    } else {
      return vm.envUint("DEPLOYER_PRIVATE_KEY");
    }
  }

  function findChainName() public returns (string memory) {
    uint256 thisChainId = block.chainid;
    string[2][] memory allRpcUrls = vm.rpcUrls();
    for (uint256 i = 0; i < allRpcUrls.length; i++) {
      try vm.createSelectFork(allRpcUrls[i][1]) {
        if (block.chainid == thisChainId) {
          return allRpcUrls[i][0];
        }
      } catch {
        continue;
      }
    }
    revert InvalidChain();
  }

  function getChain() public returns (Chain memory) {
    return getChain(block.chainid);
  }

}
