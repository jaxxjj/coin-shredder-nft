// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../src/ShredderNft.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployShredderNft is Script {
    function run() external returns (ShredderNft, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (config.subscriptionId == 0) {
            CreateSubscription createSubcription = new CreateSubscription();

            (config.subscriptionId, config.vrfCoordinator) =
                createSubcription.createSubscription(config.vrfCoordinator, config.account);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
        }

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        string[4] memory shredderTokenURIs = [
            "ipfs://QmaRtpW13fi8iZ983NKsbXjWwjWhUHcsXFRWDK5dMjZgef",
            "ipfs://QmTnxSifHARD9haHacxtC3EGvkrpSM9tPH6XzHMPZbkAyb",
            "ipfs://QmZG4Aag7tUQufzZBAbtwrfv6F4pod4LtYY1R952uNu2km",
            "ipfs://QmeQFBX21UHKjyygFcDGCSaVeVU31QzSaGJQoTgQqapLMG"
        ];

        ShredderNft shredderNft = new ShredderNft(config.subscriptionId, config.keyHash, shredderTokenURIs);

        vm.stopBroadcast();

        console.log("ShredderNft deployed at:", address(shredderNft));
        console.log("vrfCoordinator: ", config.vrfCoordinator);
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(shredderNft), config.vrfCoordinator, config.subscriptionId, config.account);
        return (shredderNft, helperConfig);
    }
}
