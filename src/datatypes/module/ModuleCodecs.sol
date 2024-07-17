// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TaskCode} from "../Task.sol";

/// @dev A module.
/// @param classHash The class hash of the module.
/// @param inputs The inputs to the module.
struct Module {
    bytes32 classHash;
    bytes32[] inputs;
}

/// @notice Codecs for Module.
/// @dev Represent a computation perform by a module.
library ModuleCodecs {
    /// @dev Encodes a Module.
    /// @param module The Module to encode.
    function encode_task(
        Module memory module
    ) internal pure returns (bytes memory) {
        return abi.encode(TaskCode.Module, module.classHash, module.inputs);
    }

    /// @dev Get the commitment of a Module.
    /// @param module The Module to commit.
    function commit(Module memory module) internal pure returns (bytes32) {
        return keccak256(abi.encode(module.classHash, module.inputs));
    }

    /// @dev Decodes a Module.
    /// @param data The encoded Module.
    function decode(bytes memory data) internal pure returns (Module memory) {
        (, bytes32 classHash, bytes32[] memory inputs) = abi.decode(
            data,
            (TaskCode, bytes32, bytes32[])
        );
        return Module(classHash, inputs);
    }
}
