//SPDX-License-Identifier:MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../src/mock/LinkToken.sol";

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e16;
    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant LOCAL_CHAINID = 31337;
    uint256 public constant BASE_SEPOLIA_CHAINID = 84532;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address vrfCoordinator;
        uint256 subscriptionId;
        address account;
        bytes32 keyHash;
        address link;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public chainIdToConfig;

    constructor() {
        chainIdToConfig[SEPOLIA_CHAINID] = getSepoliaConfig();
        chainIdToConfig[BASE_SEPOLIA_CHAINID] = getBaseSepoliaConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainIdToConfig[chainId].vrfCoordinator != address(0)) {
            return chainIdToConfig[chainId];
        } else if (chainId == LOCAL_CHAINID) {
            return getAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subscriptionId: 62134482053146938108078996485586673472192970220768930190003844516570122596811,
            account: 0x39CA5312eF96cBF09c43ea7F2eAd639c539BF613,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            subscriptionId: 66547626488195135190420255868752105630630754363069754125527850746090028772110,
            account: 0x39CA5312eF96cBF09c43ea7F2eAd639c539BF613,
            keyHash: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71,
            link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            vrfCoordinator: address(vrfCoordinatorMock),
            subscriptionId: 0,
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38,
            keyHash: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            link: address(linkToken)
        });
        return localNetworkConfig;
    }
}
