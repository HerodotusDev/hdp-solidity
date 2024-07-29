// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IFactsRegistry} from "../src/interfaces/IFactsRegistry.sol";
import {IAggregatorsFactory} from "../src/interfaces/IAggregatorsFactory.sol";
import {MockedSharpFactsRegistry} from "../src/MockedSharpFactsRegistry.sol";
import {HdpExecutionStore} from "../src/HdpExecutionStore.sol";

contract HdpLocalDeployer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        bytes32 salt = "1337";

        // Deploy the FactRegistry to the local network
        MockedSharpFactsRegistry factsRegistry = new MockedSharpFactsRegistry{
            salt: salt
        }();
        address factsRegistryAddress = address(factsRegistry);

        IFactsRegistry iFactsRegistry = IFactsRegistry(address(factsRegistry));

        IAggregatorsFactory aggregatorsFactory = IAggregatorsFactory(
            vm.envAddress("SHARP_AGGREGATORS_FACTORY")
        );

        // Deploy the HdpExecutionStore
        HdpExecutionStore hdpExecutionStore = new HdpExecutionStore{salt: salt}(
            iFactsRegistry,
            aggregatorsFactory,
            vm.envBytes32("HDP_PROGRAM_HASH")
        );
        console2.log("MockedSharpFactsRegistry: ", factsRegistryAddress);
        console2.log("HdpExecutionStore: ", address(hdpExecutionStore));
        vm.stopBroadcast();
    }
}
