// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {HdpExecutionStore} from "../src/HdpExecutionStore.sol";
import {IFactsRegistry} from "../src/interfaces/IFactsRegistry.sol";
import {IAggregatorsFactory} from "../src/interfaces/IAggregatorsFactory.sol";
import {ISharpFactsAggregator} from "../src/interfaces/ISharpFactsAggregator.sol";

contract MockFactsRegistry is IFactsRegistry {
    mapping(bytes32 => bool) public isValid;

    function markValid(bytes32 fact) public {
        isValid[fact] = true;
    }
}

contract MockAggregatorsFactory is IAggregatorsFactory {
    mapping(uint256 => ISharpFactsAggregator) public aggregatorsById;

    function createAggregator(uint256 id, ISharpFactsAggregator aggregator) external {
        aggregatorsById[id] = aggregator;
    }
}

contract MockSharpFactsAggregator is ISharpFactsAggregator {
    uint256 public usedMmrSize;
    bytes32 public usedMmrRoot;

    constructor(bytes32 poseidonMmrRoot, uint256 mmrSize) {
        usedMmrRoot = poseidonMmrRoot;
        usedMmrSize = mmrSize;
    }

    function aggregatorState() external view returns (AggregatorState memory) {
        return AggregatorState({
            poseidonMmrRoot: usedMmrRoot,
            keccakMmrRoot: bytes32(0),
            mmrSize: usedMmrSize,
            continuableParentHash: bytes32(0)
        });
    }
}

contract HdpExecutionStoreTest is Test {
    ERC1967Proxy public proxy;
    HdpExecutionStore private hdpImplementation;
    HdpExecutionStore private hdp;
    IFactsRegistry private factsRegistry;
    IAggregatorsFactory private aggregatorsFactory;
    ISharpFactsAggregator private sharpFactsAggregator;

    function setUp() public {
        vm.chainId(11155111);

        // Registery for facts that has been processed through SHARP
        factsRegistry = new MockFactsRegistry();
        // Factory for creating SHARP facts aggregators
        aggregatorsFactory = new MockAggregatorsFactory();

        bytes32 oldProgramHash = bytes32(uint256(1));
        hdpImplementation = new HdpExecutionStore();
        proxy = new ERC1967Proxy(
            address(hdpImplementation),
            abi.encodeCall(HdpExecutionStore.initialize, (factsRegistry, aggregatorsFactory, oldProgramHash))
        );

        hdp = HdpExecutionStore(address(proxy));
    }

    function testSetProgramHash() public {
        bytes32 oldProgramHash = bytes32(uint256(1));
        assertEq(hdp.getProgramHash(), oldProgramHash);

        bytes32 newProgramHash = bytes32(uint256(2));

        hdp.setProgramHash(newProgramHash);
        assertEq(hdp.getProgramHash(), newProgramHash);

        vm.prank(address(1));
        bytes32 malProgramHash = bytes32(uint256(3));
        vm.expectRevert();
        hdp.setProgramHash(malProgramHash);
    }
}
