// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
PackedUserOperation,
IEntryPointSimulations,
UserOperationDetails,
IStakeManager
} from "./lib/ERC4337.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {
snapshotState,
startMappingRecording,
startDebugTraceRecording,
stopMappingRecording,
stopAndReturnDebugTraceRecording,
revertToState,
expectRevert
} from "./lib/Vm.sol";
import {ERC4337SpecsParser} from "./SpecsParser.sol";

/**
 * @title Simulator
 * @author serezhaolshan
 * @dev Simulates a UserOperation and validates the ERC-4337 rules
 */
library Simulator {
  /**
   * Simulates a UserOperation and validates the ERC-4337 rules
   * @dev This function will revert if the UserOperation is invalid
     * @dev If the simulation fails, the rules might not be checked correctly so simulationSuccess
     * should be handled accordingly
     * @dev This function is used for v0.7 ERC-4337
     *
     * @param userOp The PackedUserOperation to simulate
     * @param onEntryPoint The address of the entry point to simulate the UserOperation on
     *
     * @return simulationSuccess True if the simulation was successful, false otherwise
     */
  function simulateUserOp(
    PackedUserOperation memory userOp,
    address onEntryPoint
  )
  internal
  returns (bool simulationSuccess)
  {
    // Pre-simulation setup
    _preSimulation();

    // Encode the call data
    bytes memory epCallData =
              abi.encodeCall(IEntryPointSimulations.simulateValidation, (userOp));

    // Simulate the UserOperation and exit on revert
    bytes memory returnData;
    (simulationSuccess, returnData) = address(onEntryPoint).call(epCallData);
    if (!simulationSuccess) {
      return simulationSuccess;
    }

    // Decode the return data
    IEntryPointSimulations.ValidationResult memory result =
              abi.decode(returnData, (IEntryPointSimulations.ValidationResult));

    // Ensure that the signature was valid
    if (result.returnInfo.accountValidationData != 0) {
      bool sigFailed = (result.returnInfo.accountValidationData & 1) == 1;
      if (sigFailed) {
        simulationSuccess = false;
      }
    }

    // Create a UserOperationDetails struct
    // This is to make it easier to maintain compatibility of the different UserOperation
    // versions
    UserOperationDetails memory userOpDetails = UserOperationDetails({
      entryPoint: onEntryPoint,
      sender: userOp.sender,
      initCode: userOp.initCode,
      paymasterAndData: userOp.paymasterAndData
    });

    // Post-simulation validation
    _postSimulation(userOpDetails);
  }

  /**
   * Pre-simulation setup
   */
  function _preSimulation() internal {
    // Create snapshot to revert to after simulation
    uint256 snapShotId = snapshotState();

    // Store the snapshot id so that it can be reverted to after simulation
    bytes32 snapShotSlot = keccak256(abi.encodePacked("Simulator.SnapshotId"));
    assembly {
      sstore(snapShotSlot, snapShotId)
    }

    // Start recording mapping accesses and debug trace
    startMappingRecording();
    startDebugTraceRecording();
  }

  /**
   * Post-simulation validation
   *
   * @param userOpDetails The UserOperationDetails to validate
     */
  function _postSimulation(UserOperationDetails memory userOpDetails) internal {
    // Get the recorded opcodes
    VmSafe.DebugStep[] memory debugTrace = stopAndReturnDebugTraceRecording();

    // Validate the ERC-4337 rules
    ERC4337SpecsParser.parseValidation(userOpDetails, debugTrace);

    // Stop (and remove) recording mapping accesses
    stopMappingRecording();

    // Get the snapshot id
    uint256 snapShotId;
    bytes32 snapShotSlot = keccak256(abi.encodePacked("Simulator.SnapshotId"));
    assembly {
      snapShotId := sload(snapShotSlot)
    }

    // Revert to snapshot
    revertToState(snapShotId);
  }
}
