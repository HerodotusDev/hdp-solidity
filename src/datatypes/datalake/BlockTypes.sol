// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Header field.
enum HeaderField {
    ParentHash,
    OmmerHash,
    Beneficiary,
    StateRoot,
    TransactionsRoot,
    ReceiptsRoot,
    LogsBloom,
    Difficulty,
    Number,
    GasLimit,
    GasUsed,
    Timestamp,
    ExtraData,
    MixHash,
    Nonce,
    BaseFeePerGas,
    WithdrawalsRoot,
    BlobGasUsed,
    ExcessBlobGas,
    ParentBeaconBlockRoot
}

/// @notice account field.
enum AccountField {
    Nonce,
    Balance,
    CodeHash,
    StorageRoot
}
