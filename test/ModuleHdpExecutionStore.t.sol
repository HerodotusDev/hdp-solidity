// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {HdpExecutionStore} from "../src/HdpExecutionStore.sol";
import {ModuleTask, ModuleCodecs} from "../src/datatypes/module/ModuleCodecs.sol";
import {IFactsRegistry} from "../src/interfaces/IFactsRegistry.sol";
import {ISharpFactsAggregator} from "../src/interfaces/ISharpFactsAggregator.sol";
import {IAggregatorsFactory} from "../src/interfaces/IAggregatorsFactory.sol";
import {Uint256Splitter} from "../src/lib/Uint256Splitter.sol";

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
    using ModuleCodecs for ModuleTask;

    address public proverAddress = address(12);

    HdpExecutionStore private hdp;
    IFactsRegistry private factsRegistry;
    IAggregatorsFactory private aggregatorsFactory;
    ISharpFactsAggregator private sharpFactsAggregator;

    // Cached fetched data from input
    bytes32 programHash;
    uint256[] fetchedMmrIds;
    uint256[] fetchedMmrSizes;
    bytes32[] fetchedMmrRoots;
    bytes32 fetchedResultsMerkleRoot;
    bytes32 fetchedTasksMerkleRoot;
    bytes32[][] fetchedResultsInclusionProofs;
    bytes32[][] fetchedTasksInclusionProofs;
    bytes32[] fetchedResults;
    bytes32[] fetchedTasksCommitments;

    function setUp() public {
        vm.chainId(11155111);

        // !! If want to fetch different input, modify helpers/target/bs_cached_input.json && helpers/target/bs_cached_output.json
        // !! And construct corresponding BlockSampledDatalake and ComputationalTask here
        bytes32[] memory moduleInputs = new bytes32[](2);
        moduleInputs[0] = bytes32(uint256(5382820));
        assertEq(moduleInputs[0], bytes32(0x00000000000000000000000000000000000000000000000000000000005222a4));
        moduleInputs[1] = bytes32(uint256(113007187165825507614120510246167695609561346261));
        assertEq(moduleInputs[1], bytes32(0x00000000000000000000000013cb6ae34a13a0977f4d7101ebc24b87bb23f0d5));

        ModuleTask memory moduleTask = ModuleTask({
            programHash: bytes32(0x064041a339b1edd10de83cf031cfa938645450f971d2527c90d4c2ce68d7d412),
            inputs: moduleInputs
        });

        // Registery for facts that has been processed through SHARP
        factsRegistry = new MockFactsRegistry();
        // Factory for creating SHARP facts aggregators
        aggregatorsFactory = new MockAggregatorsFactory();

        // bytes[] memory moduleEncodedCompare = new bytes[](1);
        // moduleEncodedCompare[0] = moduleTask.encode();

        // _callPreprocessCli(
        //     abi.encode(taskEncodedCompare),
        //     abi.encode(datalakeEncodedCompare)
        // );

        // Get program hash from compiled Cairo program
        programHash = _getProgramHash();
        hdp = new HdpExecutionStore(factsRegistry, aggregatorsFactory, programHash);

        // Parse from input file
        (
            fetchedMmrIds,
            fetchedMmrSizes,
            fetchedMmrRoots,
            fetchedTasksMerkleRoot,
            fetchedResultsMerkleRoot,
            fetchedTasksInclusionProofs,
            fetchedResultsInclusionProofs,
            fetchedTasksCommitments,
            fetchedResults
        ) = _fetchCairoInput();

        bytes32 moduleTaskCommitment = moduleTask.commit();

        assertEq(fetchedTasksCommitments[0], moduleTaskCommitment);

        // Mock SHARP facts aggregator
        sharpFactsAggregator = new MockSharpFactsAggregator(fetchedMmrRoots[0], fetchedMmrSizes[0]);

        // Create mock SHARP facts aggregator
        aggregatorsFactory.createAggregator(fetchedMmrIds[0], sharpFactsAggregator);
    }

    function testHdpExecutionFlow() public {
        (uint256 taskRootLow, uint256 taskRootHigh) = Uint256Splitter.split128(uint256(bytes32(fetchedTasksMerkleRoot)));

        (uint256 resultRootLow, uint256 resultRootHigh) =
            Uint256Splitter.split128(uint256(bytes32(fetchedResultsMerkleRoot)));

        // Cache MMR root
        for (uint256 i = 0; i < fetchedMmrIds.length; i++) {
            hdp.cacheMmrRoot(fetchedMmrIds[i]);
        }
        // Compute fact hash from PIE file
        bytes32 factHash = _computeFactHash();

        // Mark the fact as valid (Mocking SHARP behavior)
        factsRegistry.markValid(factHash);
        bool isValid = factsRegistry.isValid(factHash);
        assertEq(isValid, true);

        // Check if the request is valid in the SHARP Facts Registry
        // If valid, Store the task result
        vm.prank(proverAddress);
        hdp.authenticateTaskExecution(
            fetchedMmrIds,
            fetchedMmrSizes,
            taskRootLow,
            taskRootHigh,
            resultRootLow,
            resultRootHigh,
            fetchedTasksInclusionProofs,
            fetchedResultsInclusionProofs,
            fetchedTasksCommitments,
            fetchedResults
        );

        // Check if the task state is FINALIZED
        HdpExecutionStore.TaskStatus taskStatusAfter = hdp.getTaskStatus(fetchedTasksCommitments[0]);
        assertEq(uint256(taskStatusAfter), uint256(HdpExecutionStore.TaskStatus.FINALIZED));

        // Check if the task result is stored
        bytes32 taskResult = hdp.getFinalizedTaskResult(fetchedTasksCommitments[0]);
        assertEq(taskResult, fetchedResults[0]);
    }

    function _getProgramHash() internal returns (bytes32) {
        string[] memory inputs = new string[](5);
        inputs[0] = "python3";
        inputs[1] = "-m";
        inputs[2] = "helpers.hash_program";
        inputs[3] = "--program";
        inputs[4] = "build/hdp.json";
        bytes memory abiEncoded = vm.ffi(inputs);
        return abi.decode(abiEncoded, (bytes32));
    }

    function _callPreprocessCli(bytes memory encodedTask, bytes memory encodedDatalake) internal {
        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_cairo_input.js";
        inputs[2] = bytesToString(encodedTask);
        inputs[3] = bytesToString(encodedDatalake);
        vm.ffi(inputs);
    }

    function bytesToString(bytes memory _data) public pure returns (string memory) {
        bytes memory buffer = new bytes(_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            bytes1 b = _data[i];
            if (b == 0x00) {
                buffer[i] = "_";
            } else {
                buffer[i] = b;
            }
        }
        return string(buffer);
    }

    function _computeFactHash() internal returns (bytes32) {
        string[] memory inputs = new string[](5);
        inputs[0] = "python3";
        inputs[1] = "-m";
        inputs[2] = "helpers.compute_fact_hash";
        inputs[3] = "--cairo_pie";
        inputs[4] = "./helpers/target/md_hdp_pie.zip";
        bytes memory abiEncoded = vm.ffi(inputs);
        return abi.decode(abiEncoded, (bytes32));
    }

    function _fetchCairoInput()
        internal
        returns (
            uint256[] memory usedMmrIds,
            uint256[] memory usedMmrSizes,
            bytes32[] memory usedMmrRoots,
            bytes32 tasksMerkleRoot,
            bytes32 resultsMerkleRoot,
            bytes32[][] memory tasksInclusionProofs,
            bytes32[][] memory resultsInclusionProofs,
            bytes32[] memory tasksCommitments,
            bytes32[] memory taskResults
        )
    {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_cairo_input.js";
        inputs[2] = "md";
        bytes memory abiEncoded = vm.ffi(inputs);
        (
            usedMmrIds,
            usedMmrSizes,
            usedMmrRoots,
            tasksMerkleRoot,
            resultsMerkleRoot,
            tasksInclusionProofs,
            resultsInclusionProofs,
            tasksCommitments,
            taskResults
        ) = abi.decode(
            abiEncoded,
            (uint256[], uint256[], bytes32[], bytes32, bytes32, bytes32[][], bytes32[][], bytes32[], bytes32[])
        );
    }
}
