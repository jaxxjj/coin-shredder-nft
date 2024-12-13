// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Checkpoints} from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract ShredderNft is ERC721, VRFConsumerBaseV2Plus, ERC721URIStorage, ERC721Burnable {
    using Checkpoints for Checkpoints.Trace208;

    struct NFTCountSnapshot {
        uint256 timestamp;
        uint256[4] counts;
    }

    enum Rarity {
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }

    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint256[] public requestIds;
    string[] public s_shredderTokenURI;

    mapping(uint256 requestId => address sender) private s_requestIdToSender;
    mapping(uint256 => Rarity) private s_tokenRarity;
    mapping(address => mapping(Rarity => uint256)) private s_nftCountByOwnerAndRarity;
    mapping(address => mapping(Rarity => Checkpoints.Trace208)) private s_rarityCheckpoints;

    uint256 public s_tokenCounter;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant UNCOMMON_MAX = 6990;
    uint256 public constant RARE_MAX = 9490;
    uint256 public constant EPIC_MAX = 9990;

    error ShredderNft__RangeOutOfBound();
    error ShredderNft__NotEnoughToMint();
    error ShredderNft__TransferFailed();
    error ShredderNft__MaxSupplyReached();

    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(uint256 indexed tokenId, Rarity indexed rarity, address indexed owner);

    constructor(uint256 subscriptionId, bytes32 keyHash, string[4] memory shredderTokenURI)
        VRFConsumerBaseV2Plus(0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE) // vrfCoordinator
        ERC721("Shredder NFT", "SHRDNFT")
    {
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        s_shredderTokenURI = shredderTokenURI;
    }

    function _createSnapshot(address owner, Rarity rarity, uint256 newValue) private {
        s_rarityCheckpoints[owner][rarity].push(uint48(block.timestamp), SafeCast.toUint208(newValue));
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 newTokenId = s_tokenCounter;
        if (newTokenId >= MAX_SUPPLY) {
            revert ShredderNft__MaxSupplyReached();
        }
        address nftOwner = s_requestIdToSender[requestId];
        uint256 moddedRng = randomWords[0] % MAX_SUPPLY;
        Rarity rarity = getRarityFromModdedRng(moddedRng);
        s_tokenCounter += 1;
        s_tokenRarity[newTokenId] = rarity;

        _safeMint(nftOwner, newTokenId);
        _setTokenURI(newTokenId, s_shredderTokenURI[uint256(rarity)]);

        emit NftMinted(newTokenId, rarity, nftOwner);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        address from = super._update(to, tokenId, auth);

        if (from != to) {
            Rarity rarity = s_tokenRarity[tokenId];
            if (from != address(0)) {
                uint256 newValue = s_nftCountByOwnerAndRarity[from][rarity] - 1;
                s_nftCountByOwnerAndRarity[from][rarity] = newValue;
                _createSnapshot(from, rarity, newValue);
            }
            if (to != address(0)) {
                uint256 newValue = s_nftCountByOwnerAndRarity[to][rarity] + 1;
                s_nftCountByOwnerAndRarity[to][rarity] = newValue;
                _createSnapshot(to, rarity, newValue);
            } else {
                // burn operation
                delete s_tokenRarity[tokenId];
            }
        }
        return from;
    }

    function requestNft(address nftOwner) public onlyOwner returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: 3,
                callbackGasLimit: 500000,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        s_requestIdToSender[requestId] = nftOwner;
        emit NftRequested(requestId, nftOwner);
    }

    function getRarityFromModdedRng(uint256 moddedRng) public pure returns (Rarity) {
        if (moddedRng < UNCOMMON_MAX) {
            return Rarity.UNCOMMON;
        } else if (moddedRng < RARE_MAX) {
            return Rarity.RARE;
        } else if (moddedRng < EPIC_MAX) {
            return Rarity.EPIC;
        } else {
            return Rarity.LEGENDARY;
        }
    }

    function getChanceArray() public pure returns (uint256[4] memory) {
        return [UNCOMMON_MAX, RARE_MAX, EPIC_MAX, MAX_SUPPLY];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getNftCountByRarity(address nftOwner, Rarity rarity) public view returns (uint256) {
        return s_nftCountByOwnerAndRarity[nftOwner][rarity];
    }

    function getTokenRarity(uint256 tokenId) public view returns (Rarity) {
        return s_tokenRarity[tokenId];
    }

    function getAllNftCounts(address nftOwner) public view returns (uint256[4] memory) {
        return [
            s_nftCountByOwnerAndRarity[nftOwner][Rarity.UNCOMMON],
            s_nftCountByOwnerAndRarity[nftOwner][Rarity.RARE],
            s_nftCountByOwnerAndRarity[nftOwner][Rarity.EPIC],
            s_nftCountByOwnerAndRarity[nftOwner][Rarity.LEGENDARY]
        ];
    }

    function getNftCountAtTimestamp(address account, Rarity rarity, uint256 timestamp) public view returns (uint256) {
        return s_rarityCheckpoints[account][rarity].upperLookupRecent(SafeCast.toUint48(timestamp));
    }

    function getAllNftCountsAtTimestamp(address account, uint256 timestamp) public view returns (uint256[4] memory) {
        return [
            getNftCountAtTimestamp(account, Rarity.UNCOMMON, timestamp),
            getNftCountAtTimestamp(account, Rarity.RARE, timestamp),
            getNftCountAtTimestamp(account, Rarity.EPIC, timestamp),
            getNftCountAtTimestamp(account, Rarity.LEGENDARY, timestamp)
        ];
    }
}
