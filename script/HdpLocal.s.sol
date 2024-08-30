// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAggregatorsFactory} from "../src/interfaces/IAggregatorsFactory.sol";
import {IFactsRegistry} from "../src/interfaces/IFactsRegistry.sol";
import {MockedSharpFactsRegistry} from "../src/MockedSharpFactsRegistry.sol";
import {HdpExecutionStore} from "../src/HdpExecutionStore.sol";

contract HdpLocalDeployer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the FactRegistry to the local network
        MockedSharpFactsRegistry factsRegistry = new MockedSharpFactsRegistry();
        address factsRegistryAddress = address(factsRegistry);

        IFactsRegistry iFactsRegistry = IFactsRegistry(address(factsRegistry));
        IAggregatorsFactory aggregatorsFactory = IAggregatorsFactory(vm.envAddress("SHARP_AGGREGATORS_FACTORY"));
        HdpExecutionStore hdp = new HdpExecutionStore();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(hdp),
            abi.encodeCall(
                HdpExecutionStore.initialize, (iFactsRegistry, aggregatorsFactory, vm.envBytes32("HDP_PROGRAM_HASH"))
            )
        );

        // Please dont remove. These are used to parse the contract addresses in hdp-server scripts
        console2.log("MockedSharpFactsRegistry: ", factsRegistryAddress);
        console2.log("HdpExecutionStore: ", address(proxy));

        vm.stopBroadcast();
    }
}
