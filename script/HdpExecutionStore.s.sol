// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {IAggregatorsFactory} from "../src/interfaces/IAggregatorsFactory.sol";
import {IFactsRegistry} from "../src/interfaces/IFactsRegistry.sol";
import {HdpExecutionStore} from "../src/HdpExecutionStore.sol";

contract HdpExecutionStoreDeployer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IFactsRegistry factsRegistry = IFactsRegistry(
            vm.envAddress("FACTS_REGISTRY_ADDRESS")
        );
        IAggregatorsFactory aggregatorsFactory = IAggregatorsFactory(
            vm.envAddress("SHARP_AGGREGATORS_FACTORY")
        );

        // Deploy the HdpExecutionStore
        HdpExecutionStore hdpExecutionStore = new HdpExecutionStore(
            factsRegistry,
            aggregatorsFactory,
            vm.envBytes32("HDP_PROGRAM_HASH")
        );

        console2.log(
            "HdpExecutionStore deployed at: ",
            address(hdpExecutionStore)
        );

        vm.stopBroadcast();
    }
}
