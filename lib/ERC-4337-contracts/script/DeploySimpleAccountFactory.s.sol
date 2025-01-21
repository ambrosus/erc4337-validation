//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IEntryPoint.sol";
import "../samples/SimpleAccountFactory.sol";
import "../utils/DeploymentsManager.s.sol";

contract DeployScript is DeploymentsManager {

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address entryPointAddress = vm.envAddress("ENTRY_POINT_ADDRESS");
    initDeployments();
    vm.startBroadcast(deployerPrivateKey);

    // Deploy SimpleAccountFactory
    SimpleAccountFactory simpleAccountFactory = new SimpleAccountFactory(IEntryPoint(entryPointAddress));
    console.log("SimpleAccountFactory deployed to:", address(simpleAccountFactory));

    vm.stopBroadcast();

    /**
     * This function generates the file containing the contracts Abi definitions.
     * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
     * This function should be called last.
    */
    exportDeployments();
  }
}
