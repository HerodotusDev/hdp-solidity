// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import {TaskCode} from "../Task.sol";

/// @dev A ComputationalTask.
/// @param AggregateFnId The aggregate function id.
/// @param operator The operator to use (only COUNT).
/// @param valueToCompare The value to compare (COUNT/SLR).
/// The context is used to pass additional parameters to the aggregate function.
struct ComputationalTask {
    AggregateFn aggregateFnId;
    Operator operatorId;
    uint256 valueToCompare;
}

///@notice Aggregates functions.
enum AggregateFn {
    AVG,
    SUM,
    MIN,
    MAX,
    COUNT,
    MERKLE,
    SLR
}

///@notice Operators for COUNT.
enum Operator {
    NONE,
    EQ,
    NEQ,
    GT,
    GTE,
    LT,
    LTE
}

/// @notice Codecs for ComputationalTask.
/// @dev Represent a computational task with an aggregate function and context.
library ComputationalTaskCodecs {
    /// @dev Get the commitment of a ComputationalTask.
    /// @notice The commitment embeds the datalake commitment.
    /// @param task The ComputationalTask to commit.
    /// @param datalakeCommitment The commitment of the datalake.
    function commit(ComputationalTask memory task, bytes32 datalakeCommitment) internal pure returns (bytes32) {
        return keccak256(abi.encode(datalakeCommitment, task.aggregateFnId, task.operatorId, task.valueToCompare));
    }
}
