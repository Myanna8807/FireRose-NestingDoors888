# LXFE.io — Fire Rose & The Nesting Doors

Static site. No build step.

## Deploy on Vercel
1. vercel.com → Add New → Project → drag this folder in (or push it to GitHub and import it).
2. Framework preset: **Other**. Build command: none. Output directory: `.`
3. Deploy, then Settings → Domains → add **lxfe.io** and www.lxfe.io and add the DNS records Vercel shows at your registrar.

## Pages
- `/` — Fire Rose (index.html)
- `/doors` — The Nesting Doors (doors.html)

## Smart contract — SovereignDoors v2 (contracts/SovereignDoors-v2.sol)
LIVE on Ethereum Mainnet: 0x67eb3572b5039b7a32ed48c0e8beb434642e96c3
https://etherscan.io/address/0x67eb3572b5039b7a32ed48c0e8beb434642e96c3

1. Test first on Sepolia. Then in Remix: compiler 0.8.24+, optimizer on (200), deploy to Ethereum Mainnet.
2. Constructor: `genesis1URI`, `genesis2URI` — ipfs:// metadata JSON for Genesis 1/2 and 2/2.
   Tokens #1 and #2 mint straight to the Founder Vault 0x2636943c3Be407A142D7ab3084F54aa7AE03b934.
3. Verify the source on Etherscan (Remix "Contract Verification" plugin, or Etherscan → Verify & Publish).
4. Put the new address into `doorsContractAddress` (settings at the bottom of doors.html). Until a v2 address is
   set, doors.html shows that minting is off — the old v1 address is rejected automatically.
5. Optional, from the vault wallet on Etherscan → Write Contract: `list(1, 8880000000000000000)` lists Genesis 1/2 at 8.88 ETH.

## How money moves (v2)
- Claim (default 0.88 ETH): 85% to the owner of the door it lives inside · 15% Founder Vault.
- Door sale via LXFE.io: 70% seller · 15% owner of the parent door · 15% Founder Vault.
- Genesis sale via LXFE.io: 85% seller · 15% Founder Vault.
- Everything is credited on-chain; each person presses Withdraw on /doors to collect.
- Sales on other marketplaces are not forced through the split.

Unaudited contract: get a professional audit before significant value flows through it.

## Sovereign Audit Log (doors.html → settings, "Transparency")
- `sourceVerified`: turn on once the contract source is verified on Etherscan.
- `auditUrl`: paste the link to a published audit report.
- `hiddenDoors`: doors hidden after a report, as universe:door, e.g. `1:4, 2:7`.
- Admin key status, solvency and lineage are read live from the contract; moving ownership to a Safe or renouncing it updates the panel automatically.
