// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Datalake type.
enum DatalakeCode {
    BlockSampled,
    TransactionsInBlock
}

/// @notice Chain type.
enum ChainType {
    Ethereum,
    EthereumSepolia,
}