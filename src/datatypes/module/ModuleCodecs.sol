// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TaskCode} from "../Task.sol";

/// @dev A module compute.
/// @param classHash The class hash of the module.
/// @param inputs The inputs to the module.
struct ModuleCompute {
    uint256 classHash;
    uint256[] inputs;
}

/// @notice Codecs for ModuleCompute.
/// @dev Represent a computation perform by a module.
library ModuleComputeCodecs {
    /// @dev Encodes a ModuleCompute.
    /// @param module The ModuleCompute to encode.
    function encode(ModuleCompute memory module) internal pure returns (bytes memory) {
        return abi.encode(TaskCode.Module, module.classHash, module.inputs);
    }

    /// @dev Get the commitment of a ModuleCompute.
    /// @param module The ModuleCompute to commit.
    function commit(ModuleCompute memory module) internal pure returns (bytes32) {
        return keccak256(encode(module));
    }

    /// @dev Decodes a ModuleCompute.
    /// @param data The encoded ModuleCompute.
    function decode(bytes memory data) internal pure returns (ModuleCompute memory) {
        (, uint256 classHash, uint256[] memory inputs) = abi.decode(data, (TaskCode, uint256, uint256[]));
        return ModuleCompute(classHash, inputs);
    }
}
