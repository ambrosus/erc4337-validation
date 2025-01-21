//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Vm.sol";
import "./EnvManager.s.sol";
import "./InitializableScript.s.sol";
import { Upgrades } from "./LegacyUpgradesPlus.sol";

contract DeploymentsManager is EnvManager, InitializableScript {
  error InvalidAddress(address addr);
  error EmptyContractName(string name);
  error DeploymentNotFound(string name);

  string deploymentsPath;
  mapping(string => address) private deploymentAddresses;
  string[] private deploymentNames;

  function initDeployments() public {
    initChains();
    
    string memory root = vm.projectRoot();
    deploymentsPath = string.concat(root, "/deployments/");
    string memory chainIdStr = vm.toString(block.chainid);
    deploymentsPath = string.concat(deploymentsPath, string.concat(chainIdStr, ".json"));

    try vm.readFile(deploymentsPath) returns (string memory json) {
        string[] memory keys = vm.parseJsonKeys(json, "");
        
        for (uint i = 0; i < keys.length; i++) {
            // Skip networkName as it's not a contract deployment
            if (keccak256(bytes(keys[i])) == keccak256(bytes("networkName"))) continue;
            
            string memory addressKey = keys[i];
            bytes memory contractData = vm.parseJson(json, string.concat(".", addressKey));
            string memory contractName = abi.decode(contractData, (string));
            address addr = address(bytes20(vm.parseAddress(addressKey)));
            
            deploymentAddresses[contractName] = addr;
            deploymentNames.push(contractName);
        }
        console.log("Loaded contract names count: ", deploymentNames.length);
    } catch {
        console.log("No deployments file found, starting fresh at ", deploymentsPath);
    }
    
    initialized = true;
  }

  function isDeployed(string memory contractName) internal view initializedOnly returns (bool) {
    return deploymentAddresses[contractName] != address(0);
  }

  function getDeployment(string memory contractName) public view initializedOnly returns (address) {
    address addr = deploymentAddresses[contractName];
    if (addr == address(0)) revert DeploymentNotFound(contractName);
    return addr;
  }

  function deploy(string memory name, string memory artifactPath) internal returns (address deployedAddress) {
    if (bytes(name).length == 0) revert EmptyContractName(name);
    if (isDeployed(name)) {
      console.log("Contract already deployed: ", name, "loading address: ", getDeployment(name));
      return getDeployment(name);
    }
    deployedAddress = deployCode(artifactPath);
    deploymentAddresses[name] = deployedAddress;
    deploymentNames.push(name);
    console.log("Deployed contract: ", name, "at address: ", deployedAddress);
  }

  function deploy(string memory name, string memory artifactPath, bytes memory constructorArgs) internal returns (address deployedAddress) {
    if (bytes(name).length == 0) revert EmptyContractName(name);
    if (isDeployed(name)) {
      console.log("Contract already deployed: ", name, "loading address: ", getDeployment(name));
      return getDeployment(name);
    }
    deployedAddress = deployCode(artifactPath, constructorArgs);
    deploymentAddresses[name] = deployedAddress;
    deploymentNames.push(name);
    console.log("Deployed contract: ", name, "at address: ", deployedAddress);
  }

  function deployProxy(string memory name, string memory artifact, bytes memory initializerData) internal returns (address deployedAddress) {
    if (bytes(name).length == 0) revert EmptyContractName(name);
    if (isDeployed(name)) {
      console.log("Contract already deployed: ", name, "loading address: ", getDeployment(name));
      return getDeployment(name);
    }
    deployedAddress = Upgrades.deployUUPSProxy(artifact, initializerData);
    deploymentAddresses[name] = deployedAddress;
    deploymentNames.push(name);
    console.log("Deployed contract: ", name, "at address: ", deployedAddress);
  }

  function deployBeacon(string memory name, string memory artifact, address initialOwner) internal returns (address deployedAddress) {
    if (bytes(name).length == 0) revert EmptyContractName(name);
    if (isDeployed(name)) {
      return getDeployment(name);
    }
    deployedAddress = Upgrades.deployBeacon(artifact, initialOwner);
    deploymentAddresses[name] = deployedAddress;
    deploymentNames.push(name);
    console.log("Deployed contract: ", name, "at address: ", deployedAddress);
  }

  function exportDeployments() internal initializedOnly {
    string memory jsonWrite;
    
    // Create JSON entries for each deployment
    for (uint256 i = 0; i < deploymentNames.length; i++) {
        string memory name = deploymentNames[i];
        address addr = deploymentAddresses[name];
        vm.serializeString(jsonWrite, vm.toString(addr), name);
    }

    string memory chainName;
    try this.getChain() returns (Chain memory chain) {
      chainName = chain.name;
    } catch {
      chainName = findChainName();
    }
    jsonWrite = vm.serializeString(jsonWrite, "networkName", chainName);
    vm.writeJson(jsonWrite, deploymentsPath);
  }
}
