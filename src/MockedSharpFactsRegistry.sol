// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract MockedSharpFactsRegistry {
    mapping(bytes32 => bool) public isValid;

    function setValid(bytes32 fact) external {
        isValid[fact] = true;
    }
}
