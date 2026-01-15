// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Vault
 * @notice Secure asset management for ClearFall Dutch auctions
 * @dev Handles ERC20 deposits, bid fund locking, and secure withdrawals
 */
contract Vault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Structs ============
    struct LockedFunds {
        uint256 amount;
        bool isLocked;
    }

    // ============ State Variables ============
    address public immutable auction;
    IERC20 public immutable token;
    address public immutable creator;
    uint256 public totalDeposited;
    uint256 public totalLocked;
    
    mapping(address => LockedFunds) public bidderFunds;

    // ============ Events ============
    event TokensDeposited(address indexed from, uint256 amount);
    event FundsLocked(address indexed bidder, uint256 amount);
    event FundsUnlocked(address indexed bidder, uint256 amount);
    event FundsReleased(address indexed to, uint256 amount);
    event TokensWithdrawn(address indexed to, uint256 amount);
    event ProceedsWithdrawn(address indexed creator, uint256 amount);

    // ============ Errors ============
    error OnlyAuction();
    error OnlyCreator();
    error InsufficientDeposit();
    error FundsAlreadyLocked();
    error NoFundsLocked();
    error TransferFailed();

    // ============ Modifiers ============
    modifier onlyAuction() {
        if (msg.sender != auction) revert OnlyAuction();
        _;
    }

    modifier onlyCreator() {
        if (msg.sender != creator) revert OnlyCreator();
        _;
    }

    // ============ Constructor ============
    constructor(address _token, address _creator) {
        auction = msg.sender;
        token = IERC20(_token);
        creator = _creator;
    }

    // ============ Creator Functions ============

    /**
     * @notice Deposit tokens for auction
     * @param amount Amount of tokens to deposit
     */
    function depositTokens(uint256 amount) external onlyCreator nonReentrant {
        token.safeTransferFrom(msg.sender, address(this), amount);
        totalDeposited += amount;
        emit TokensDeposited(msg.sender, amount);
    }

    /**
     * @notice Withdraw unsold tokens after auction ends
     * @param amount Amount to withdraw
     */
    function withdrawTokens(uint256 amount) external onlyAuction nonReentrant {
        token.safeTransfer(creator, amount);
        emit TokensWithdrawn(creator, amount);
    }

    /**
     * @notice Withdraw auction proceeds (ETH/MATIC)
     * @param amount Amount of proceeds to withdraw
     */
    function withdrawProceeds(uint256 amount) external onlyAuction nonReentrant {
        (bool success, ) = payable(creator).call{value: amount}("");
        if (!success) revert TransferFailed();
        emit ProceedsWithdrawn(creator, amount);
    }

    // ============ Bidder Functions ============

    /**
     * @notice Lock funds for a bid commitment
     * @param bidder Address of the bidder
     */
    function lockFunds(address bidder) external payable onlyAuction nonReentrant {
        if (bidderFunds[bidder].isLocked) revert FundsAlreadyLocked();
        
        bidderFunds[bidder] = LockedFunds({
            amount: msg.value,
            isLocked: true
        });
        totalLocked += msg.value;
        
        emit FundsLocked(bidder, msg.value);
    }

    /**
     * @notice Unlock and refund funds to a bidder
     * @param bidder Address to refund
     */
    function unlockFunds(address bidder) external onlyAuction nonReentrant {
        LockedFunds storage funds = bidderFunds[bidder];
        if (!funds.isLocked) revert NoFundsLocked();
        
        uint256 amount = funds.amount;
        funds.amount = 0;
        funds.isLocked = false;
        totalLocked -= amount;
        
        (bool success, ) = payable(bidder).call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit FundsUnlocked(bidder, amount);
    }

    /**
     * @notice Release tokens to a winning bidder
     * @param bidder Address to receive tokens
     * @param tokenAmount Amount of tokens to release
     * @param refundAmount Amount of ETH to refund (excess payment)
     */
    function releaseToWinner(
        address bidder, 
        uint256 tokenAmount,
        uint256 refundAmount
    ) external onlyAuction nonReentrant {
        LockedFunds storage funds = bidderFunds[bidder];
        
        // Clear locked status
        funds.isLocked = false;
        totalLocked -= funds.amount;
        funds.amount = 0;
        
        // Transfer tokens to winner
        token.safeTransfer(bidder, tokenAmount);
        
        // Refund excess if any
        if (refundAmount > 0) {
            (bool success, ) = payable(bidder).call{value: refundAmount}("");
            if (!success) revert TransferFailed();
        }
        
        emit FundsReleased(bidder, tokenAmount);
    }

    // ============ View Functions ============

    /**
     * @notice Get locked funds for a bidder
     */
    function getLockedFunds(address bidder) external view returns (uint256 amount, bool isLocked) {
        LockedFunds memory funds = bidderFunds[bidder];
        return (funds.amount, funds.isLocked);
    }

    /**
     * @notice Get vault's token balance
     */
    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Get vault's ETH/MATIC balance
     */
    function getEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // ============ Receive ============
    receive() external payable {}
}
