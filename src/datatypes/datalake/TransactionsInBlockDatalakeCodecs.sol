// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DatalakeCode} from "./Datalake.sol";
import {TaskCode} from "../Task.sol";
import {Compute} from "./ComputeCodecs.sol";

/// @dev A TransactionsInBlockDatalake.
/// @param chainType The chain type of the datalake.
/// @param compute The compute for the datalake.
/// @param targetBlock The block to sample trnasactions from.
/// @param startIndex The start index of the transactions to sample.
/// @param endIndex The end index of the transactions to sample.
/// @param increment The transactions increment.
/// @param includedTypes The types of transactions to include. Each bytes represents a type of transaction to include/exclude.
/// @param sampledProperty The detail property to sample.
struct TransactionsInBlockDatalake {
    ChainType chainType;
    Compute compute;
    uint256 targetBlock;
    uint256 startIndex;
    uint256 endIndex;
    uint256 increment;
    uint256 includedTypes;
    bytes sampledProperty;
}

/// @notice Codecs for TransactionsInBlockDatalake.
/// @dev Represent a datalake that samples a property at a fixed block interval.
library TransactionsInBlockDatalakeCodecs {
    /// @dev Encodes a TransactionsInBlockDatalake.
    /// @param datalake The TransactionsInBlockDatalake to encode.
    function encode(
        TransactionsInBlockDatalake memory datalake
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                TaskCode.DatalakeCompute,
                DatalakeCode.TransactionsInBlock,
                datalake.chainType,
                datalake.targetBlock,
                datalake.startIndex,
                datalake.endIndex,
                datalake.increment,
                datalake.includedTypes,
                datalake.sampledProperty,
                datalake.compute.aggregateFnId,
                datalake.compute.operatorId,
                datalake.compute.valueToCompare
            );
    }

    /// @dev Get the commitment of a TransactionsInBlockDatalake.
    /// @param datalake The TransactionsInBlockDatalake to commit.
    function commit(
        TransactionsInBlockDatalake memory datalake
    ) internal pure returns (bytes32) {
        return keccak256(encode(datalake));
    }

    /// @dev Encodes a sampled property for a transaction property.
    /// @param txPropId The field from rlp decoded block tx.
    function encodeSampledPropertyForTxProp(
        uint8 txPropId
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(1), txPropId);
    }

    /// @dev Encodes a sampled property for an transaction receipt property.
    /// @param txReceiptPropId The field from rlp decoded block transaction receipt.
    function encodeSampledPropertyFortxReceipt(
        uint8 txReceiptPropId
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(2), txReceiptPropId);
    }

    /// @dev Decodes a TransactionsInBlockDatalake.
    /// @param data The encoded TransactionsInBlockDatalake.
    function decode(
        bytes memory data
    )
        internal
        pure
        returns (TransactionsInBlockDatalake memory, Compute memory)
    {
        (
            ,
            ,
            ChainType chainType,
            uint256 targetBlock,
            uint256 startIndex,
            uint256 endIndex,
            uint256 increment,
            uint256 includedTypes,
            bytes memory sampledProperty,
            uint8 aggregateFnId,
            uint8 operatorId,
            uint256 valueToCompare
        ) = abi.decode(
                data,
                (
                    TaskCode,
                    DatalakeCode,
                    ChainType,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    bytes,
                    uint8,
                    uint8,
                    uint256
                )
            );
        return (
            TransactionsInBlockDatalake({
                chainType: chainType,
                compute: Compute({
                    aggregateFnId: aggregateFnId,
                    operatorId: operatorId,
                    valueToCompare: valueToCompare
                }),
                targetBlock: targetBlock,
                startIndex: startIndex,
                endIndex: endIndex,
                increment: increment,
                includedTypes: includedTypes,
                sampledProperty: sampledProperty
            }),

        );
    }
}
