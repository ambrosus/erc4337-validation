// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {IEntryPointSimulations} from "account-abstraction/interfaces/IEntryPointSimulations.sol";
import {IStakeManager} from "account-abstraction/interfaces/IStakeManager.sol";
import {EntryPointSimulations} from "account-abstraction/core/EntryPointSimulations.sol";
import {SenderCreator} from "account-abstraction/core/EntryPoint.sol";


  struct UserOperationDetails {
    address entryPoint;
    address sender;
    bytes initCode;
    bytes paymasterAndData;
  }

import {etch} from "./Vm.sol";

address constant ENTRYPOINT_ADDR = 0x16fD82fA245BBE7FE14B1a419f41c545B46DC571;

/**
 * Creates a new EntryPointSimulations and etches it to the ENTRYPOINT_ADDR
 */
  function etchEntrypoint() returns (IEntryPoint) {
    // Create and etch a new EntryPointSimulations
    address payable entryPoint = payable(address(new EntryPointSimulations()));
    etch(ENTRYPOINT_ADDR, entryPoint.code);

    // Create and etch a new SenderCreator
    SenderCreator senderCreator = new SenderCreator();
    address senderCreatorAddr =
            address(uint160(uint256(keccak256(abi.encodePacked(hex"d694", ENTRYPOINT_ADDR, hex"01")))));
    etch(senderCreatorAddr, address(senderCreator).code);

    return IEntryPoint(ENTRYPOINT_ADDR);
  }
