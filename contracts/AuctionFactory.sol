// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DutchAuction.sol";

/**
 * @title AuctionFactory
 * @notice Factory for creating ClearFall Dutch auctions
 * @dev Deploys new DutchAuction instances with no admin privileges
 */
contract AuctionFactory {
    // ============ State ============
    address[] public auctions;
    mapping(address => address[]) public creatorAuctions;
    mapping(address => bool) public isValidAuction;

    // ============ Events ============
    event AuctionCreated(
        address indexed auction,
        address indexed creator,
        address token,
        uint256 totalSupply,
        uint256 startPrice,
        uint256 endPrice,
        uint256 startTime
    );

    // ============ Errors ============
    error InvalidToken();
    error InvalidSupply();
    error InvalidPriceRange();
    error InvalidTimeRange();

    // ============ Factory Functions ============

    /**
     * @notice Create a new Dutch auction
     * @param params Auction parameters struct
     * @return auctionAddress Address of the created auction
     */
    function createAuction(DutchAuction.AuctionParams memory params) 
        external 
        returns (address auctionAddress) 
    {
        // Validate inputs
        if (params.token == address(0)) revert InvalidToken();
        if (params.totalSupply == 0) revert InvalidSupply();
        if (params.startPrice <= params.endPrice) revert InvalidPriceRange();
        if (params.endTime <= params.startTime) revert InvalidTimeRange();
        
        // Deploy auction
        DutchAuction auction = new DutchAuction(params, msg.sender);
        auctionAddress = address(auction);
        
        // Register auction
        auctions.push(auctionAddress);
        creatorAuctions[msg.sender].push(auctionAddress);
        isValidAuction[auctionAddress] = true;
        
        emit AuctionCreated(
            auctionAddress,
            msg.sender,
            params.token,
            params.totalSupply,
            params.startPrice,
            params.endPrice,
            params.startTime
        );
    }

    // ============ View Functions ============

    /**
     * @notice Get total number of auctions created
     */
    function getAuctionCount() external view returns (uint256) {
        return auctions.length;
    }

    /**
     * @notice Get auctions created by a specific address
     */
    function getCreatorAuctions(address creator) external view returns (address[] memory) {
        return creatorAuctions[creator];
    }

    /**
     * @notice Get all auction addresses
     * @param offset Start index
     * @param limit Max number to return
     */
    function getAuctions(uint256 offset, uint256 limit) external view returns (address[] memory) {
        uint256 total = auctions.length;
        if (offset >= total) {
            return new address[](0);
        }
        
        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }
        
        address[] memory result = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = auctions[i];
        }
        
        return result;
    }

    /**
     * @notice Check if an address is a valid auction
     */
    function isAuctionValid(address auction) external view returns (bool) {
        return isValidAuction[auction];
    }
}
