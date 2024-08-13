// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {HdpExecutionStore} from "../src/HdpExecutionStore.sol";
import {IFactsRegistry} from "../src/interfaces/IFactsRegistry.sol";
import {IAggregatorsFactory} from "../src/interfaces/IAggregatorsFactory.sol";
import {ISharpFactsAggregator} from "../src/interfaces/ISharpFactsAggregator.sol";

// Mock contracts (as defined in your previous test)
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

contract HdpExecutionStoreV2 is HdpExecutionStore {
    function version() public pure returns (string memory) {
        return "V2";
    }
}

contract HdpExecutionStoreV3 is HdpExecutionStore {
    function version() public pure returns (string memory) {
        return "V3";
    }
}

contract UpgradeableHdpExecutionStoreTest is Test {
    ERC1967Proxy public proxy;
    HdpExecutionStore private hdpImplementation;
    HdpExecutionStore private hdp;
    HdpExecutionStoreV2 private hdpV2;
    HdpExecutionStoreV3 private hdpV3;
    IFactsRegistry private factsRegistry;
    IAggregatorsFactory private aggregatorsFactory;
    ISharpFactsAggregator private sharpFactsAggregator;

    address public owner;
    address public user;
    bytes32 oldProgramHash;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        vm.chainId(11155111);

        factsRegistry = new MockFactsRegistry();
        aggregatorsFactory = new MockAggregatorsFactory();

        oldProgramHash = bytes32(uint256(1));
        hdpImplementation = new HdpExecutionStore();
        proxy = new ERC1967Proxy(
            address(hdpImplementation),
            abi.encodeCall(HdpExecutionStore.initialize, (factsRegistry, aggregatorsFactory, oldProgramHash))
        );

        hdp = HdpExecutionStore(address(proxy));
    }

    function testUpgrade() public {
        // Deploy V2
        hdpV2 = new HdpExecutionStoreV2();

        // owner can upgrade to V2
        vm.prank(owner);
        HdpExecutionStore(address(proxy)).upgradeToAndCall(address(hdpV2), "");

        hdpV2 = HdpExecutionStoreV2(address(proxy));

        // Test that state is preserved
        assertEq(hdpV2.PROGRAM_HASH(), bytes32(uint256(1)));
        assertEq(hdpV2.owner(), owner);

        // Ensure only owner can call new function
        hdpV3 = HdpExecutionStoreV3(address(proxy));
        vm.prank(user);
        vm.expectRevert();
        HdpExecutionStore(address(proxy)).upgradeToAndCall(address(hdpV3), "");

        // test version is still V2
        assertEq(hdpV2.version(), "V2");
    }

    function testSetProgramHash() public {
        assertEq(hdp.PROGRAM_HASH(), oldProgramHash);

        bytes32 newProgramHash = bytes32(uint256(2));
        // successfully set new program hash
        hdp.setProgramHash(newProgramHash);
        assertEq(hdp.PROGRAM_HASH(), newProgramHash);

        // only owner can call `setProgramHash`
        vm.prank(user);
        bytes32 malProgramHash = bytes32(uint256(3));
        vm.expectRevert();
        hdp.setProgramHash(malProgramHash);

        // ensure same prorogram hash
        assertEq(hdp.PROGRAM_HASH(), newProgramHash);
    }
}
