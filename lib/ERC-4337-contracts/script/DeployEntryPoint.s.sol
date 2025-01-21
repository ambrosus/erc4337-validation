//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IEntryPoint.sol";
import "../core/EntryPoint.sol";
import "../utils/DeploymentsManager.s.sol";

contract DeployScript is DeploymentsManager {

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    initDeployments();
    vm.startBroadcast(deployerPrivateKey);

    // Deploy EntryPoint
    IEntryPoint entryPoint = new EntryPoint();
    console.log("EntryPoint deployed to:", address(entryPoint));

    vm.stopBroadcast();

    /**
     * This function generates the file containing the contracts Abi definitions.
     * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
     * This function should be called last.
    */
    exportDeployments();
  }
}
