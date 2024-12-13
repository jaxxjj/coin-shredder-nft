//SPDX-License-Identifier:MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployShredderNft} from "../../script/DeployShredderNft.s.sol";
import {ShredderNft} from "../../src/ShredderNft.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract ShredderNftTest is CodeConstants, Test {
    ShredderNft public shredderNft;
    HelperConfig public helperConfig;
    address public USER = makeAddr("user");
    address public vrfCoordinator;
    bytes32 public keyHash;
    uint256 public subscriptionId;
    address public owner;

    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(uint256 indexed tokenId, ShredderNft.Rarity indexed rarity, address indexed owner);

    function setUp() external {
        DeployShredderNft deployer = new DeployShredderNft();
        (shredderNft, helperConfig) = deployer.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinator = config.vrfCoordinator;
        keyHash = config.keyHash;
        subscriptionId = config.subscriptionId;
        owner = config.account;
        vm.deal(USER, 1000 ether);
    }

    function test_initial_state() external {
        assertEq(shredderNft.owner(), owner);
        assertEq(shredderNft.s_tokenCounter(), 0);
    }

    function test_requestNft() external {
        vm.prank(owner);
        uint256 requestId = shredderNft.requestNft(USER);
        assertGt(requestId, 0);
    }

    function test_requestNft_emitsEvent() external {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit NftRequested(1, USER);
        shredderNft.requestNft(USER);
    }

    function test_requestNft_onlyOwner() external {
        vm.prank(USER);
        vm.expectRevert();
        shredderNft.requestNft(USER);
    }

    function test_fulfillRandomWords() external {
        vm.startPrank(owner);
        uint256 requestId = shredderNft.requestNft(USER);
        vm.stopPrank();

        // vm.expectEmit(true, true, true, false);
        // emit NftMinted(0, ShredderNft.Rarity.UNCOMMON, USER);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(shredderNft));

        assertEq(shredderNft.s_tokenCounter(), 1);
        assertEq(shredderNft.ownerOf(0), USER);
    }

    function test_getRarityFromModdedRng() external {
        assertEq(uint256(shredderNft.getRarityFromModdedRng(0)), uint256(ShredderNft.Rarity.UNCOMMON));
        assertEq(uint256(shredderNft.getRarityFromModdedRng(6989)), uint256(ShredderNft.Rarity.UNCOMMON));
        assertEq(uint256(shredderNft.getRarityFromModdedRng(6990)), uint256(ShredderNft.Rarity.RARE));
        assertEq(uint256(shredderNft.getRarityFromModdedRng(9489)), uint256(ShredderNft.Rarity.RARE));
        assertEq(uint256(shredderNft.getRarityFromModdedRng(9490)), uint256(ShredderNft.Rarity.EPIC));
        assertEq(uint256(shredderNft.getRarityFromModdedRng(9989)), uint256(ShredderNft.Rarity.EPIC));
        assertEq(uint256(shredderNft.getRarityFromModdedRng(9990)), uint256(ShredderNft.Rarity.LEGENDARY));
        assertEq(uint256(shredderNft.getRarityFromModdedRng(9999)), uint256(ShredderNft.Rarity.LEGENDARY));
    }

    function test_getChanceArray() external {
        uint256[4] memory chanceArray = shredderNft.getChanceArray();
        assertEq(chanceArray[0], 6990);
        assertEq(chanceArray[1], 9490);
        assertEq(chanceArray[2], 9990);
        assertEq(chanceArray[3], 10000);
    }

    function test_getNftCountByRarity() external {
        vm.startPrank(owner);
        uint256 requestId = shredderNft.requestNft(USER);
        vm.stopPrank();

        vm.prank(vrfCoordinator);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(shredderNft));

        assertEq(shredderNft.getNftCountByRarity(USER, ShredderNft.Rarity.UNCOMMON), 1);
        assertEq(shredderNft.getNftCountByRarity(USER, ShredderNft.Rarity.RARE), 0);
        assertEq(shredderNft.getNftCountByRarity(USER, ShredderNft.Rarity.EPIC), 0);
        assertEq(shredderNft.getNftCountByRarity(USER, ShredderNft.Rarity.LEGENDARY), 0);
    }

    function test_getAllNftCounts() external {
        vm.startPrank(owner);
        uint256 requestId1 = shredderNft.requestNft(USER);
        uint256 requestId2 = shredderNft.requestNft(USER);
        vm.stopPrank();

        vm.startPrank(vrfCoordinator);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId1, address(shredderNft));
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId2, address(shredderNft));
        vm.stopPrank();

        uint256[4] memory nftCounts = shredderNft.getAllNftCounts(USER);
        assertEq(nftCounts[0] + nftCounts[1] + nftCounts[2] + nftCounts[3], 2); // Total should be 2
    }

    function test_tokenURI() external {
        vm.startPrank(owner);
        uint256 requestId = shredderNft.requestNft(USER);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123; // This will result in an UNCOMMON NFT

        vm.stopPrank();

        vm.prank(vrfCoordinator);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(shredderNft));

        string memory uri = shredderNft.tokenURI(0);
        assertEq(uri, shredderNft.s_shredderTokenURI(uint256(ShredderNft.Rarity.UNCOMMON)));
    }

    function test_supportsInterface() external {
        // ERC721 interface ID
        bytes4 erc721InterfaceId = 0x80ac58cd;
        // ERC721Metadata interface ID
        bytes4 erc721MetadataInterfaceId = 0x5b5e139f;

        assertTrue(shredderNft.supportsInterface(erc721InterfaceId));
        assertTrue(shredderNft.supportsInterface(erc721MetadataInterfaceId));
    }
}
