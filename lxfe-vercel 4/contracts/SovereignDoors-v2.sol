// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title  SovereignDoors v2 — Fire Rose & The Nesting Doors (LXFE · LXFE.io)
 * @author Maya Harrington — The Sterling Method™ · Conceived & created January 8
 *
 * GENESIS   Tokens #1 and #2 are the two Master Genesis Apps (1/2 and 2/2), minted to the Founder Vault
 *           at deployment. Each one is the root of its own universe; universes never share doors or revenue.
 *
 * NESTING   Claiming Door N in a universe mints it to its creator and unlocks Door N+1 inside it.
 *           Door #1's parent is that universe's Genesis token; Door N's parent is Door N-1.
 *
 * MONEY     Claim fee (default 0.88 ETH, owner-adjustable up to 8.88 ETH):
 *              85% to the owner of the parent door (the door you live inside) · 15% Founder Vault
 *           Door sale through `buy`:
 *              70% seller (the creator on the first sale) · 15% owner of the parent door · 15% Founder Vault
 *           Genesis sale through `buy`:
 *              85% seller · 15% Founder Vault (nothing sits above a Genesis App)
 *           The Founder Vault always receives the remainder, so rounding wei can never get stuck.
 *           Every revenue seat follows token ownership: whoever owns a door owns its upstream earnings.
 *
 * SAFETY    O(1) per action — no loops over the lineage, so the tunnel can grow forever without gas stalls.
 *           Pull payments — shares are credited, then each person calls withdraw(). No wallet or smart
 *           contract can block anyone else's claim or sale.
 *           Owners can list, re-price and unlist any number of times. Any transfer cancels a stale listing.
 *           Buyers must send exactly the listed price, so a last-second price change simply reverts.
 *           The owner can pause new claims/listings/sales, set the claim fee (max 8.88 ETH) and the
 *           collection metadata — and nothing else. Withdrawals and transfers always work. Credited
 *           funds can never be moved by anyone but their owner. The Founder Vault is a constant.
 *
 * LIMITS    Standard ERC-721: doors can also be transferred or sold on other marketplaces, and those
 *           sales cannot be forced through the 70 / 15 / 15 split. The split is guaranteed via `buy`.
 *           Unaudited. Have it professionally audited and test it on Sepolia before mainnet.
 *
 * DEPLOY    Remix · compiler 0.8.24+ · optimizer on (200 runs)
 *           constructor(genesis1URI, genesis2URI) — ipfs:// metadata JSON for Genesis 1/2 and 2/2.
 */
contract SovereignDoors is ERC721, Ownable, Pausable, ReentrancyGuard {
    string public constant VERSION = "SovereignDoors-2";
    address payable public constant FOUNDER_VAULT = payable(0x2636943c3Be407A142D7ab3084F54aa7AE03b934);

    uint256 public constant BPS = 10_000;
    uint256 public constant SELLER_BPS = 7_000;
    uint256 public constant UPSTREAM_BPS = 1_500;
    uint256 public constant GENESIS_SELLER_BPS = 8_500;
    uint256 public constant CLAIM_UPSTREAM_BPS = 8_500;
    uint256 public constant MAX_CLAIM_FEE = 8.88 ether;

    struct Door {
        uint8 universe;   // 1 or 2
        uint64 number;    // 0 = Genesis App, then 1, 2, 3, ...
        uint256 parentId; // token id of the door this one lives inside (0 for Genesis)
        address creator;
    }

    mapping(uint256 => Door) public doors;                            // tokenId => door
    mapping(uint8 => mapping(uint64 => uint256)) public doorTokenId; // universe => number => tokenId ([u][0] = Genesis)
    mapping(uint8 => uint64) public nextDoor;                         // universe => next open door number
    mapping(uint256 => uint256) public listingPrice;                  // tokenId => price in wei (0 = not listed)
    mapping(address => uint256) public pendingWithdrawals;            // credited, withdrawable balances

    uint256 public claimFee = 0.88 ether;
    uint256 public totalOwed;
    string public contractURI;

    mapping(uint256 => string) private _uris;
    uint256 private _nextTokenId = 3;

    event GenesisMinted(uint8 indexed universe, address indexed to, string uri);
    event DoorClaimed(uint8 indexed universe, uint64 indexed number, uint256 indexed tokenId, uint256 parentId, address creator, string uri);
    event DoorUnlocked(uint8 indexed universe, uint64 indexed number, uint256 insideTokenId);
    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Unlisted(uint256 indexed tokenId);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, address upstream);
    event Credited(address indexed payee, uint256 amount);
    event Withdrawn(address indexed payee, address to, uint256 amount);
    event ClaimFeeSet(uint256 fee);
    event ContractURISet(string uri);

    error BadUniverse();
    error DoorAlreadyClaimed(uint64 openDoor);
    error EmptyURI();
    error WrongPayment(uint256 required);
    error NotTokenOwner();
    error NotListed();
    error ZeroPrice();
    error SelfPurchase();
    error NothingToWithdraw();
    error TransferFailed();
    error ZeroAddress();
    error FeeTooHigh(uint256 max);

    constructor(string memory genesis1URI, string memory genesis2URI)
        ERC721("Fire Rose - The Nesting Doors", "LXFEDOOR")
        Ownable(msg.sender)
    {
        _mintGenesis(1, genesis1URI);
        _mintGenesis(2, genesis2URI);
    }

    // ───────────────────────── Nesting ─────────────────────────

    /// @notice Claim the open door in `universe`. Mints it to you and unlocks the next door inside it.
    /// @param expectedNumber The door you intend to claim; reverts cleanly if someone claimed it first.
    /// @param uri            Metadata URI (ipfs://… or data:application/json;base64,…).
    /// @param price          Optional sale price in wei (0 = list later).
    function claimDoor(uint8 universe, uint64 expectedNumber, string calldata uri, uint256 price)
        external
        payable
        whenNotPaused
        nonReentrant
        returns (uint256 tokenId)
    {
        if (universe != 1 && universe != 2) revert BadUniverse();
        uint64 n = nextDoor[universe];
        if (expectedNumber != n) revert DoorAlreadyClaimed(n);
        if (bytes(uri).length == 0) revert EmptyURI();
        if (msg.value != claimFee) revert WrongPayment(claimFee);

        uint256 parentId = doorTokenId[universe][n - 1];
        tokenId = _nextTokenId++;

        doors[tokenId] = Door(universe, n, parentId, msg.sender);
        doorTokenId[universe][n] = tokenId;
        nextDoor[universe] = n + 1;
        _uris[tokenId] = uri;

        if (msg.value > 0) {
            uint256 up = (msg.value * CLAIM_UPSTREAM_BPS) / BPS;
            _credit(ownerOf(parentId), up);
            _credit(FOUNDER_VAULT, msg.value - up);
        }

        _safeMint(msg.sender, tokenId);
        if (price > 0) {
            listingPrice[tokenId] = price;
            emit Listed(tokenId, msg.sender, price);
        }

        emit DoorClaimed(universe, n, tokenId, parentId, msg.sender, uri);
        emit DoorUnlocked(universe, n + 1, tokenId);
    }

    // ───────────────────────── Marketplace (split enforced) ─────────────────────────

    /// @notice List or re-price a door (or a Genesis App) you own. Call again any time to change the price.
    function list(uint256 tokenId, uint256 price) external whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (price == 0) revert ZeroPrice();
        listingPrice[tokenId] = price;
        emit Listed(tokenId, msg.sender, price);
    }

    function unlist(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        delete listingPrice[tokenId];
        emit Unlisted(tokenId);
    }

    /// @notice Buy a listed token. Send exactly the listed price; the split is credited atomically.
    function buy(uint256 tokenId) external payable whenNotPaused nonReentrant {
        uint256 price = listingPrice[tokenId];
        if (price == 0) revert NotListed();
        if (msg.value != price) revert WrongPayment(price);
        address seller = ownerOf(tokenId);
        if (seller == msg.sender) revert SelfPurchase();

        delete listingPrice[tokenId];

        Door storage d = doors[tokenId];
        address upstream;
        uint256 sellerShare;
        uint256 upstreamShare;
        if (d.number == 0) {
            sellerShare = (price * GENESIS_SELLER_BPS) / BPS;
        } else {
            sellerShare = (price * SELLER_BPS) / BPS;
            upstreamShare = (price * UPSTREAM_BPS) / BPS;
            upstream = ownerOf(d.parentId);
            _credit(upstream, upstreamShare);
        }
        _credit(seller, sellerShare);
        _credit(FOUNDER_VAULT, price - sellerShare - upstreamShare);

        _safeTransfer(seller, msg.sender, tokenId);
        emit Sold(tokenId, seller, msg.sender, price, upstream);
    }

    // ───────────────────────── Payouts (pull) ─────────────────────────

    function withdraw() external {
        withdrawTo(payable(msg.sender));
    }

    /// @notice Withdraw your balance to any address (useful if your wallet cannot receive ETH directly).
    function withdrawTo(address payable to) public nonReentrant {
        if (to == address(0)) revert ZeroAddress();
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert NothingToWithdraw();
        pendingWithdrawals[msg.sender] = 0;
        totalOwed -= amount;
        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit Withdrawn(msg.sender, to, amount);
    }

    // ───────────────────────── Views ─────────────────────────

    /// @notice Who receives the 15% upstream share when `tokenId` sells (address(0) for a Genesis App).
    function upstreamPayee(uint256 tokenId) external view returns (address) {
        Door storage d = doors[tokenId];
        if (d.number == 0) return address(0);
        return ownerOf(d.parentId);
    }

    function isGenesis(uint256 tokenId) external pure returns (bool) {
        return tokenId == 1 || tokenId == 2;
    }

    function totalMinted() external view returns (uint256) {
        return _nextTokenId - 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _uris[tokenId];
    }

    // ───────────────────────── Admin (cannot touch credited funds, splits or tokens) ─────────────────────────

    function setClaimFee(uint256 fee) external onlyOwner {
        if (fee > MAX_CLAIM_FEE) revert FeeTooHigh(MAX_CLAIM_FEE);
        claimFee = fee;
        emit ClaimFeeSet(fee);
    }

    function setContractURI(string calldata uri) external onlyOwner {
        contractURI = uri;
        emit ContractURISet(uri);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /// @notice Credits ETH that arrived outside normal flows to the vault. Never touches owed funds.
    function sweepSurplus() external onlyOwner {
        uint256 surplus = address(this).balance - totalOwed;
        if (surplus > 0) _credit(FOUNDER_VAULT, surplus);
    }

    // ───────────────────────── Internals ─────────────────────────

    function _mintGenesis(uint8 u, string memory uri) private {
        doors[u] = Door(u, 0, 0, FOUNDER_VAULT);
        doorTokenId[u][0] = u;
        nextDoor[u] = 1;
        _uris[u] = uri;
        _mint(FOUNDER_VAULT, u);
        emit GenesisMinted(u, FOUNDER_VAULT, uri);
    }

    function _credit(address payee, uint256 amount) internal {
        if (amount == 0) return;
        pendingWithdrawals[payee] += amount;
        totalOwed += amount;
        emit Credited(payee, amount);
    }

    /// @dev Any transfer (including on other marketplaces) cancels the previous owner's listing.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address from) {
        from = super._update(to, tokenId, auth);
        if (from != address(0) && listingPrice[tokenId] != 0) {
            delete listingPrice[tokenId];
            emit Unlisted(tokenId);
        }
    }
}
