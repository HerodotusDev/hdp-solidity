pragma solidity 0.8.20;

contract MockedSharpFactsRegistry {
    mapping(bytes32 => bool) public isValid;

    function setValid(bytes32 fact) external {
        isValid[fact] = true;
    }

}