# Shredder NFT Collection

The Shredder NFT Collection is the official NFT rewards system for [CoinShredder](https://coinshredder.org) - a crypto-themed Telegram game. These NFTs represent unique "Shredder" machines with varying abilities and rarity levels that enhance gameplay and token earning potential.

## Deployments

- **Sepolia**: `0xce546478945DA89C3aB4Dfbf28b07BB62e244041`

## Features

- **Rarity Tiers**: Four distinct rarity levels with unique attributes and benefits:

  - Uncommon (69.9%)
  - Rare (25%)
  - Epic (5%)
  - Legendary (0.1%)

- **Verifiable Randomness**: Uses Chainlink VRF (Verifiable Random Function) to ensure fair and transparent rarity distribution

- **Historical Ownership Tracking**: Uses OpenZeppelin's Checkpoints to maintain verifiable historical records of NFT ownership:

  - Track NFT counts by rarity at any point in time
  - Query historical ownership states
  - Verify past reward eligibility
  - Support time-based game mechanics

- **Limited Supply**: Maximum supply of 10,000 NFTs

- **Metadata**: Rich IPFS-hosted metadata including:
  - Rarity level
  - Shredding power
  - Energy efficiency
  - Blockchain compatibility
  - Special features
  - Visual attributes

## Technical Details

### Smart Contract

The NFT collection implements multiple standards and features:

- ERC721 base functionality
- ERC721URIStorage for metadata management
- ERC721Burnable for token burning
- Chainlink VRF for randomness
- Checkpoints for historical data tracking

### Rarity Distribution

Total supply: 10,000 NFTs

| Rarity Level | Range     | Percentage | Count |
| ------------ | --------- | ---------- | ----- |
| Uncommon     | 0-6989    | 69.9%      | 6,990 |
| Rare         | 6990-9489 | 25%        | 2,500 |
| Epic         | 9490-9989 | 5%         | 500   |
| Legendary    | 9990-9999 | 0.1%       | 10    |

## Development

This project uses the Foundry development framework.

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

```bash
forge script script/DeployShredderNft.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Integration

NFTs can be minted only by the contract owner and are distributed as rewards in the CoinShredder game. Each NFT provides unique benefits and boosts within the game ecosystem.

### Viewing Your NFTs

You can view your NFT collection and rarity distribution using the following methods:

```solidity
// Get count of NFTs by rarity
getNftCountByRarity(address owner, Rarity rarity)

// Get all NFT counts for an address
getAllNftCounts(address owner)

// Get historical NFT counts at a specific timestamp
getAllNftCountsAtTimestamp(address owner, uint256 timestamp)
```

### Viewing Historical Ownership

The contract maintains complete historical records of NFT ownership using OpenZeppelin's Checkpoints. You can query ownership status at any past timestamp:

```solidity
// Get historical NFT count for a single rarity
getNftCountAtTimestamp(address account, Rarity rarity, uint256 timestamp)

// Get historical counts for all rarities
getAllNftCountsAtTimestamp(address account, uint256 timestamp)

// Example usage:
// Check how many Legendary NFTs an address owned on January 1st, 2024
uint256 timestamp = 1704067200; // Jan 1, 2024 00:00:00 UTC
uint256 legendaryCount = nft.getNftCountAtTimestamp(userAddress, Rarity.LEGENDARY, timestamp);

// Get full rarity distribution at a past timestamp
uint256[4] memory historicalCounts = nft.getAllNftCountsAtTimestamp(userAddress, timestamp);
// Returns [uncommonCount, rareCount, epicCount, legendaryCount]
```

This feature enables:

- Verification of historical NFT ownership
- Time-based reward calculations
- Gameplay mechanics based on holding periods
- Accurate historical analytics

## Links

- Game: [coinshredder.org](https://coinshredder.org)
- Telegram: [t.me/LetShredderBot](https://t.me/LetShredderBot)

## License

MIT License
