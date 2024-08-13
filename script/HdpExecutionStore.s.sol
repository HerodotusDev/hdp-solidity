// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAggregatorsFactory} from "../src/interfaces/IAggregatorsFactory.sol";
import {IFactsRegistry} from "../src/interfaces/IFactsRegistry.sol";
import {HdpExecutionStore} from "../src/HdpExecutionStore.sol";

contract HdpExecutionStoreDeployer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IFactsRegistry factsRegistry = IFactsRegistry(vm.envAddress("FACTS_REGISTRY_ADDRESS"));
        IAggregatorsFactory aggregatorsFactory = IAggregatorsFactory(vm.envAddress("SHARP_AGGREGATORS_FACTORY"));

        HdpExecutionStore hdp = new HdpExecutionStore();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(hdp),
            abi.encodeCall(
                HdpExecutionStore.initialize, (factsRegistry, aggregatorsFactory, vm.envBytes32("HDP_PROGRAM_HASH"))
            )
        );

        console2.log("HdpExecutionStore proxy deployed at: ", address(proxy));

        vm.stopBroadcast();
    }
}
