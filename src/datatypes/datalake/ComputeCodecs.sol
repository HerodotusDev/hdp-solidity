// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev A Compute for datalake.
/// @param AggregateFnId The aggregate function id.
/// @param operator The operator to use (only COUNT).
/// @param valueToCompare The value to compare (COUNT/SLR).
/// The context is used to pass additional parameters to the aggregate function.
struct Compute {
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

/// @notice Codecs for Compute.
/// @dev Represent a computational task with an aggregate function and context.
library ComputeCodecs {
    /// @dev Encodes a Compute.
    /// @param task The Compute to encode.
    function encode(Compute memory task) internal pure returns (bytes memory) {
        return abi.encode(task.aggregateFnId, task.operatorId, task.valueToCompare);
    }

    /// @dev Get the commitment of a Compute.
    /// @notice The commitment embeds the datalake commitment.
    /// @param task The Compute to commit.
    /// @param datalakeCommitment The commitment of the datalake.
    function commit(Compute memory task, bytes32 datalakeCommitment) internal pure returns (bytes32) {
        return keccak256(abi.encode(datalakeCommitment, task.aggregateFnId, task.operatorId, task.valueToCompare));
    }

    /// @dev Decodes a Compute.
    /// @param data The encoded Compute.
    function decode(bytes memory data) internal pure returns (Compute memory) {
        (uint8 aggregateFnId, uint8 operator, uint256 valueToCompare) = abi.decode(data, (uint8, uint8, uint256));
        return Compute({
            aggregateFnId: AggregateFn(aggregateFnId),
            operatorId: Operator(operator),
            valueToCompare: valueToCompare
        });
    }
}
