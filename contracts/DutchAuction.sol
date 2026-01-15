// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vault.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DutchAuction
 * @notice Trustless Dutch auction with commit-reveal mechanism
 * @dev Price decreases over time, clears when demand >= supply
 */
contract DutchAuction is ReentrancyGuard {
    // ============ Enums ============
    enum AuctionPhase {
        Pending,
        Commit,
        Reveal,
        Cleared,
        Settled
    }

    // ============ Structs ============
    struct AuctionParams {
        address token;
        uint256 totalSupply;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 commitDuration;
        uint256 revealDuration;
        uint256 nonRevealPenalty; // Basis points (e.g., 1000 = 10%)
    }

    struct Commitment {
        bytes32 hash;
        uint256 lockedAmount;
        bool revealed;
        uint256 revealedQuantity;
    }

    // ============ Immutable State ============
    address public immutable factory;
    address public immutable creator;
    Vault public immutable vault;
    
    // Auction parameters (immutable after creation)
    address public token;
    uint256 public totalSupply;
    uint256 public startPrice;
    uint256 public endPrice;
    uint256 public startTime;
    uint256 public commitEndTime;
    uint256 public revealEndTime;
    uint256 public nonRevealPenalty;

    // ============ Mutable State ============
    uint256 public totalRevealedDemand;
    uint256 public clearingPrice;
    uint256 public clearingTime;
    bool public isCleared;
    bool public isSettled;
    
    mapping(address => Commitment) public commitments;
    address[] public bidders;
    mapping(address => bool) public hasClaimed;

    // ============ Events ============
    event AuctionCreated(
        address indexed auction,
        address indexed creator,
        address token,
        uint256 totalSupply,
        uint256 startPrice,
        uint256 endPrice
    );
    event CommitmentMade(address indexed bidder, bytes32 commitmentHash, uint256 lockedAmount);
    event CommitmentRevealed(address indexed bidder, uint256 quantity);
    event AuctionCleared(uint256 clearingPrice, uint256 totalDemand, uint256 timestamp);
    event TokensClaimed(address indexed bidder, uint256 amount, uint256 refund);
    event RefundClaimed(address indexed bidder, uint256 amount);
    event ProceedsWithdrawn(address indexed creator, uint256 amount);
    event UnsoldTokensWithdrawn(address indexed creator, uint256 amount);

    // ============ Errors ============
    error InvalidPhase();
    error InvalidParameters();
    error AlreadyCommitted();
    error InsufficientFunds();
    error InvalidCommitment();
    error AlreadyRevealed();
    error AlreadyClaimed();
    error AuctionNotCleared();
    error AuctionNotSettled();
    error NotAWinner();
    error NothingToRefund();

    // ============ Constructor ============
    constructor(AuctionParams memory params, address _creator) {
        // Validate parameters
        if (params.startPrice <= params.endPrice) revert InvalidParameters();
        if (params.startTime < block.timestamp) revert InvalidParameters();
        if (params.endTime <= params.startTime) revert InvalidParameters();
        if (params.totalSupply == 0) revert InvalidParameters();
        if (params.nonRevealPenalty > 10000) revert InvalidParameters();

        factory = msg.sender;
        creator = _creator;
        
        // Set immutable auction parameters
        token = params.token;
        totalSupply = params.totalSupply;
        startPrice = params.startPrice;
        endPrice = params.endPrice;
        startTime = params.startTime;
        commitEndTime = params.startTime + params.commitDuration;
        revealEndTime = commitEndTime + params.revealDuration;
        nonRevealPenalty = params.nonRevealPenalty;

        // Deploy vault
        vault = new Vault(params.token, _creator);
        
        emit AuctionCreated(
            address(this),
            _creator,
            params.token,
            params.totalSupply,
            params.startPrice,
            params.endPrice
        );
    }

    // ============ Phase Functions ============

    /**
     * @notice Get current auction phase
     */
    function getCurrentPhase() public view returns (AuctionPhase) {
        if (isSettled) return AuctionPhase.Settled;
        if (isCleared) return AuctionPhase.Cleared;
        if (block.timestamp < startTime) return AuctionPhase.Pending;
        if (block.timestamp < commitEndTime) return AuctionPhase.Commit;
        if (block.timestamp < revealEndTime) return AuctionPhase.Reveal;
        return AuctionPhase.Cleared; // Auto-clear after reveal phase
    }

    /**
     * @notice Get current price based on time
     * @dev Linear decrease from startPrice to endPrice
     */
    function getCurrentPrice() public view returns (uint256) {
        if (block.timestamp <= startTime) return startPrice;
        if (block.timestamp >= revealEndTime) return endPrice;
        
        uint256 elapsed = block.timestamp - startTime;
        uint256 duration = revealEndTime - startTime;
        uint256 priceRange = startPrice - endPrice;
        
        return startPrice - (priceRange * elapsed / duration);
    }

    /**
     * @notice Get price at a specific timestamp
     */
    function getPriceAt(uint256 timestamp) public view returns (uint256) {
        if (timestamp <= startTime) return startPrice;
        if (timestamp >= revealEndTime) return endPrice;
        
        uint256 elapsed = timestamp - startTime;
        uint256 duration = revealEndTime - startTime;
        uint256 priceRange = startPrice - endPrice;
        
        return startPrice - (priceRange * elapsed / duration);
    }

    // ============ Commit Phase ============

    /**
     * @notice Commit to a bid (hash of quantity + nonce + address)
     * @param commitmentHash keccak256(abi.encodePacked(quantity, nonce, msg.sender))
     */
    function commit(bytes32 commitmentHash) external payable nonReentrant {
        if (getCurrentPhase() != AuctionPhase.Commit) revert InvalidPhase();
        if (commitments[msg.sender].hash != bytes32(0)) revert AlreadyCommitted();
        if (msg.value == 0) revert InsufficientFunds();

        commitments[msg.sender] = Commitment({
            hash: commitmentHash,
            lockedAmount: msg.value,
            revealed: false,
            revealedQuantity: 0
        });
        
        bidders.push(msg.sender);
        
        // Lock funds in vault
        vault.lockFunds{value: msg.value}(msg.sender);
        
        emit CommitmentMade(msg.sender, commitmentHash, msg.value);
    }

    // ============ Reveal Phase ============

    /**
     * @notice Reveal your bid
     * @param quantity The quantity you bid for
     * @param nonce The random nonce used in commitment
     */
    function reveal(uint256 quantity, uint256 nonce) external nonReentrant {
        AuctionPhase phase = getCurrentPhase();
        if (phase != AuctionPhase.Reveal && !isCleared) revert InvalidPhase();
        
        Commitment storage commitment = commitments[msg.sender];
        if (commitment.hash == bytes32(0)) revert InvalidCommitment();
        if (commitment.revealed) revert AlreadyRevealed();
        
        // Verify commitment
        bytes32 expectedHash = keccak256(abi.encodePacked(quantity, nonce, msg.sender));
        if (commitment.hash != expectedHash) revert InvalidCommitment();
        
        commitment.revealed = true;
        commitment.revealedQuantity = quantity;
        totalRevealedDemand += quantity;
        
        emit CommitmentRevealed(msg.sender, quantity);
        
        // Check if auction should clear
        _checkAndClear();
    }

    /**
     * @notice Check if demand >= supply and clear auction
     */
    function _checkAndClear() internal {
        if (isCleared) return;
        
        if (totalRevealedDemand >= totalSupply) {
            isCleared = true;
            clearingTime = block.timestamp;
            clearingPrice = getCurrentPrice();
            
            emit AuctionCleared(clearingPrice, totalRevealedDemand, clearingTime);
        }
    }

    /**
     * @notice Force clear after reveal phase ends
     */
    function forceClear() external {
        if (getCurrentPhase() != AuctionPhase.Reveal && !isCleared) {
            if (block.timestamp >= revealEndTime) {
                isCleared = true;
                clearingTime = revealEndTime;
                clearingPrice = endPrice;
                
                emit AuctionCleared(clearingPrice, totalRevealedDemand, clearingTime);
            }
        }
    }

    // ============ Claims & Settlement ============

    /**
     * @notice Claim tokens as a winner
     */
    function claimTokens() external nonReentrant {
        if (!isCleared) revert AuctionNotCleared();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        
        Commitment storage commitment = commitments[msg.sender];
        if (!commitment.revealed) revert NotAWinner();
        if (commitment.revealedQuantity == 0) revert NotAWinner();
        
        hasClaimed[msg.sender] = true;
        
        // Calculate allocation (pro-rata if oversubscribed)
        uint256 allocation;
        if (totalRevealedDemand <= totalSupply) {
            allocation = commitment.revealedQuantity;
        } else {
            allocation = (commitment.revealedQuantity * totalSupply) / totalRevealedDemand;
        }
        
        // Calculate payment and refund
        uint256 payment = allocation * clearingPrice;
        uint256 refund = commitment.lockedAmount > payment ? commitment.lockedAmount - payment : 0;
        
        // Release tokens and refund through vault
        vault.releaseToWinner(msg.sender, allocation, refund);
        
        emit TokensClaimed(msg.sender, allocation, refund);
    }

    /**
     * @notice Claim refund for non-revealed or losing bid
     */
    function claimRefund() external nonReentrant {
        if (!isCleared) revert AuctionNotCleared();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        
        Commitment storage commitment = commitments[msg.sender];
        if (commitment.hash == bytes32(0)) revert NothingToRefund();
        
        hasClaimed[msg.sender] = true;
        
        uint256 refundAmount = commitment.lockedAmount;
        
        // Apply penalty for non-reveal
        if (!commitment.revealed && nonRevealPenalty > 0) {
            uint256 penalty = (refundAmount * nonRevealPenalty) / 10000;
            refundAmount -= penalty;
        }
        
        if (refundAmount > 0) {
            vault.unlockFunds(msg.sender);
        }
        
        emit RefundClaimed(msg.sender, refundAmount);
    }

    /**
     * @notice Creator withdraws proceeds after auction clears
     */
    function withdrawProceeds() external nonReentrant {
        if (!isCleared) revert AuctionNotCleared();
        if (msg.sender != creator) revert InvalidParameters();
        
        uint256 sold = totalRevealedDemand < totalSupply ? totalRevealedDemand : totalSupply;
        uint256 proceeds = sold * clearingPrice;
        
        vault.withdrawProceeds(proceeds);
        
        emit ProceedsWithdrawn(creator, proceeds);
    }

    /**
     * @notice Creator withdraws unsold tokens
     */
    function withdrawUnsoldTokens() external nonReentrant {
        if (!isCleared) revert AuctionNotCleared();
        if (msg.sender != creator) revert InvalidParameters();
        
        if (totalRevealedDemand < totalSupply) {
            uint256 unsold = totalSupply - totalRevealedDemand;
            vault.withdrawTokens(unsold);
            
            emit UnsoldTokensWithdrawn(creator, unsold);
        }
    }

    // ============ View Functions ============

    /**
     * @notice Get auction info
     */
    function getAuctionInfo() external view returns (
        address _token,
        uint256 _totalSupply,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _startTime,
        uint256 _commitEndTime,
        uint256 _revealEndTime,
        AuctionPhase _phase,
        uint256 _currentPrice,
        uint256 _totalDemand,
        bool _isCleared,
        uint256 _clearingPrice
    ) {
        return (
            token,
            totalSupply,
            startPrice,
            endPrice,
            startTime,
            commitEndTime,
            revealEndTime,
            getCurrentPhase(),
            getCurrentPrice(),
            totalRevealedDemand,
            isCleared,
            clearingPrice
        );
    }

    /**
     * @notice Get commitment for an address
     */
    function getCommitment(address bidder) external view returns (
        bytes32 hash,
        uint256 lockedAmount,
        bool revealed,
        uint256 revealedQuantity
    ) {
        Commitment memory c = commitments[bidder];
        return (c.hash, c.lockedAmount, c.revealed, c.revealedQuantity);
    }

    /**
     * @notice Get total number of bidders
     */
    function getBidderCount() external view returns (uint256) {
        return bidders.length;
    }

    /**
     * @notice Get time remaining in current phase
     */
    function getTimeRemaining() external view returns (uint256) {
        AuctionPhase phase = getCurrentPhase();
        
        if (phase == AuctionPhase.Pending) {
            return startTime - block.timestamp;
        } else if (phase == AuctionPhase.Commit) {
            return commitEndTime - block.timestamp;
        } else if (phase == AuctionPhase.Reveal) {
            return revealEndTime - block.timestamp;
        }
        
        return 0;
    }
}
