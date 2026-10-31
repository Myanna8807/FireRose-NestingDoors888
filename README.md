# Fire Rose // The Nesting Doors · LXFE

**An interactive DApp and sovereign web3 experience by Maya Harrington.**  
**Founder of The Sterling Method™.**  
Live at **[LXFE.io](https://lxfe.io)**

> "One door inside another, forever."

---

## The Architect’s Note

My mother, Dr. Diana R. Harrington, was a titan of institutional finance who wrote the foundational textbooks on corporate risk. My Papa, a veteran and an artist, possessed a forensic radar for truth, always catching the smoke and mirrors hidden in plain sight. 

Growing up between these two lenses, I saw the gap: the actual mechanics of wealth are kept strictly behind closed doors. Today, creators are fed those same smoke and mirrors by traditional platforms—hidden slippage, algorithmic manipulation, and extractive middlemen.

I built The Sterling Method™ because I refuse to launch my work on broken plumbing. 

By enforcing a strict 70/15/15 recursive split that settles instantly on the Ethereum blockchain, I took the opaque corporate box and collapsed it into a transparent foundation. The ledger sits in broad daylight before anyone signs. 

This is not built for a balance sheet. It is built for sovereignty. No triangulation. No middlemen. Just the truth.

*— Maya Harrington*

---

## The Architecture

**Two Genesis Apps.** Only two Master Genesis Apps exist (1/2 and 2/2). Each is the root of its own separate universe. Universes never share doors or royalties. They are two journeys that begin at the same origin.

**The Nesting Doors.** Inside each universe is an endless chain of doors. Claiming Door #N mints your NFT page and unlocks Door #N+1 *inside* it. Every door lives inside the one before it, so lineage is permanent and visible.

---

## How Web3 Closes the Gap

Fire Rose moves the rules out of a company's spreadsheet and into a public smart contract on Ethereum. Anyone can read it. Nobody, including the Founder, can quietly change how a sale is divided.

| | Traditional Platform | The Nesting Doors |
|---|---|---|
| **Who sets the split** | The platform, privately | Code, published and verified on Etherscan |
| **When creators are credited** | Weeks later, if at all | In the same transaction as the sale |
| **Who can see the books** | Only the platform | Everyone, live, at any time |
| **Can the terms change later?** | Yes, at will | The 70 / 15 / 15 split is fixed in the contract |
| **Proof of authorship** | A database row | An NFT minted to the creator's own wallet |

---

## How Every Wei Moves

| Action | Price | Where it goes |
|---|---|---|
| **Collect a Genesis App** | 8.88 ETH | 85% seller · 15% Founder Vault |
| **Claim an open door** | 0.04 ETH | 85% to the holder of the door it lives inside · 15% Founder Vault |
| **Collect a door** (resale on LXFE.io) | Set by its holder | **70%** seller (the creator, on the first sale) · **15%** holder of the door it lives inside · **15%** Founder Vault |

- **Creator Royalties follow the door.** Whoever holds a door holds its lineage seat, and receives 15% each time the door nested inside it changes hands.
- **Nothing is rounded away.** The Founder Vault receives the exact remainder of every split, so no wei is ever stranded.
- **Pull, not push.** Shares are credited inside the contract and each person collects their own with **Withdraw**. No wallet can block anyone else's sale or claim.
- **Re-listable forever.** Holders can list, re-price, or unlist any time. Any transfer cancels an old listing.

---

## What the Founder can and cannot do

The contract owner **can**: pause new claims and sales, adjust the claim fee (hard-capped at 8.88 ETH), and update collection-level metadata.

The contract owner **cannot**: move anyone's credited balance, change the 70 / 15 / 15 split, edit or remove a creator's minted NFT, mint extra Genesis Apps, or block withdrawals. The Founder Vault address is fixed in the code.

**Sovereign Audit Log.** The Nesting Doors page reads Ethereum directly and shows, live, the contract's ETH balance against everything owed (the Solvency Scale), who holds the admin key, who holds each Genesis App, and the current open door.

---

## Honest limits

- **The split is guaranteed on LXFE.io.** These are standard ERC-721 tokens, so they also work on OpenSea and other marketplaces. Sales made there are not forced through the 70 / 15 / 15 split.
- **Permanent media.** Creator artwork and audio must use IPFS or permanent https links so they stay with the NFT forever. Reported malicious doors can be hidden from the LXFE.io interface. The token itself remains on-chain.
- **Not yet professionally audited.** The source is public and verified. Review it, and start with small amounts.
- **Not a financial product.** Fire Rose is a collectible art and music experience. Creator Royalties reward the lineage of creators; they are not a promise of value.

---

## Contracts (Ethereum Mainnet)

| | Address |
|---|---|
| **SovereignDoors v2 (live)** | [`0x67eb3572b5039b7a32ed48c0e8beb434642e96c3`](https://etherscan.io/address/0x67eb3572b5039b7a32ed48c0e8beb434642e96c3#code) |
| **Founder Vault** | [`0x2636943c3be407a142d7ab3084f54aa7ae03b934`](https://etherscan.io/address/0x2636943c3be407a142d7ab3084f54aa7ae03b934) |

Source: `contracts/SovereignDoors-v2.sol` · OpenSea: [lxfe888](https://opensea.io/collection/lxfe888)

---

## For Developers

Static site, no build step.

- `index.html`: Fire Rose (entrance, player, Genesis details)
- `doors.html`: The Nesting Doors (tunnel, claim chain, page builder, Sovereign Audit Log)
- Wallet: MetaMask (open LXFE.io in the MetaMask app browser on mobile). Reads via public Ethereum RPC; writes via ethers v6.

**Deploy:** This repository is connected to Vercel. Commit to the main branch and LXFE.io updates automatically.

---

*Created by Maya Harrington · The Sterling Method™ · FREEDOM • PEACE • LEGACY*
