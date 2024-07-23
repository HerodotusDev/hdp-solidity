// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TaskCode} from "../Task.sol";

/// @dev A module.
/// @param programHash The program hash of the module contract.
/// @param inputs The inputs to the module.
struct Module {
    bytes32 programHash;
    bytes32[] inputs;
}

/// @notice Codecs for Module.
/// @dev Represent a computation perform by a module.
library ModuleCodecs {
    /// @dev Get the commitment of a Module.
    /// @param module The Module to commit.
    function commit(Module memory module) internal pure returns (bytes32) {
        return keccak256(abi.encode(module.programHash, module.inputs));
    }
}
