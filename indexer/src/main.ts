import { ethers } from "ethers";
import { MongoClient, Db } from "mongodb";
import * as dotenv from "dotenv";

dotenv.config();

// Configuration
const RPC_URL = process.env.POLYGON_RPC_URL || "https://rpc-amoy.polygon.technology";
const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017";
const FACTORY_ADDRESS = process.env.FACTORY_ADDRESS || "0x3f10025Ad4abddFa48eC05B63FFa84f71DA2d814";

if (!FACTORY_ADDRESS) {
    console.error("❌ FACTORY_ADDRESS is required! Please set it in your .env file");
    process.exit(1);
}

// ABIs (simplified)
const FACTORY_ABI = [
    "event AuctionCreated(address indexed auction, address indexed creator, address token, uint256 totalSupply, uint256 startPrice, uint256 endPrice, uint256 startTime)",
];

const AUCTION_ABI = [
    "event CommitmentMade(address indexed bidder, bytes32 commitmentHash, uint256 lockedAmount)",
    "event CommitmentRevealed(address indexed bidder, uint256 quantity)",
    "event AuctionCleared(uint256 clearingPrice, uint256 totalDemand, uint256 timestamp)",
    "event TokensClaimed(address indexed bidder, uint256 amount, uint256 refund)",
    "event RefundClaimed(address indexed bidder, uint256 amount)",
];

class ClearFallIndexer {
    private provider: ethers.JsonRpcProvider;
    private db: Db | null = null;
    private factoryContract: ethers.Contract;
    private auctionContracts: Map<string, ethers.Contract> = new Map();

    constructor() {
        try {
            this.provider = new ethers.JsonRpcProvider(RPC_URL);
            this.factoryContract = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, this.provider);
        } catch (error) {
            console.error("❌ Error initializing indexer:", error);
            throw error;
        }
    }

    async connect(): Promise<void> {
        console.log("🔌 Connecting to MongoDB...");
        const client = new MongoClient(MONGODB_URI);
        await client.connect();
        this.db = client.db("clearfall");
        console.log("✅ Connected to MongoDB");
    }

    async start(): Promise<void> {
        console.log("🚀 Starting ClearFall Indexer...");
        console.log(`📡 RPC: ${RPC_URL}`);
        console.log(`🏭 Factory: ${FACTORY_ADDRESS}`);

        // Listen for new auctions
        this.factoryContract.on(
            "AuctionCreated",
            async (auction, creator, token, totalSupply, startPrice, endPrice, startTime) => {
                console.log(`🎉 New auction created: ${auction}`);

                await this.saveAuction({
                    address: auction,
                    creator,
                    token,
                    totalSupply: totalSupply.toString(),
                    startPrice: startPrice.toString(),
                    endPrice: endPrice.toString(),
                    startTime: Number(startTime),
                    title: "", // Will be updated via API if provided
                    description: "", // Will be updated via API if provided
                    createdAt: new Date(),
                });

                // Start listening to this auction's events
                this.listenToAuction(auction);
            }
        );

        // Load existing auctions
        await this.loadExistingAuctions();

        console.log("✅ Indexer is running...");
    }

    private async loadExistingAuctions(): Promise<void> {
        if (!this.db) return;

        const auctions = await this.db.collection("auctions").find({}).toArray();
        console.log(`📦 Loading ${auctions.length} existing auctions...`);

        for (const auction of auctions) {
            this.listenToAuction(auction.address);
        }
    }

    private listenToAuction(auctionAddress: string): void {
        if (this.auctionContracts.has(auctionAddress)) return;

        const contract = new ethers.Contract(auctionAddress, AUCTION_ABI, this.provider);
        this.auctionContracts.set(auctionAddress, contract);

        // Commitment events
        contract.on("CommitmentMade", async (bidder, hash, amount) => {
            console.log(`🔒 Commitment from ${bidder} on ${auctionAddress}`);
            await this.saveBid({
                auction: auctionAddress,
                bidder,
                commitmentHash: hash,
                lockedAmount: amount.toString(),
                revealed: false,
                timestamp: new Date(),
            });
        });

        // Reveal events
        contract.on("CommitmentRevealed", async (bidder, quantity) => {
            console.log(`👁️ Reveal from ${bidder} on ${auctionAddress}`);
            await this.updateBidReveal(auctionAddress, bidder, quantity.toString());
        });

        // Clearing events
        contract.on("AuctionCleared", async (clearingPrice, totalDemand, timestamp) => {
            console.log(`✨ Auction cleared: ${auctionAddress}`);
            await this.updateAuctionCleared(auctionAddress, clearingPrice.toString(), totalDemand.toString());
            
            // Notify all bidders
            if (this.db) {
                const bids = await this.db.collection("bids").find({ auction: auctionAddress }).toArray();
                for (const bid of bids) {
                    await this.createNotification(auctionAddress, bid.bidder, `Auction cleared at ${clearingPrice.toString()} wei!`);
                }
            }
        });

        // Claim events
        contract.on("TokensClaimed", async (bidder, amount, refund) => {
            console.log(`🎁 Tokens claimed by ${bidder} on ${auctionAddress}`);
            await this.saveClaim({
                auction: auctionAddress,
                bidder,
                tokenAmount: amount.toString(),
                refundAmount: refund.toString(),
                type: "winner",
                timestamp: new Date(),
            });
            await this.createNotification(auctionAddress, bidder, "Tokens claimed successfully!");
        });

        contract.on("RefundClaimed", async (bidder, amount) => {
            console.log(`💰 Refund claimed by ${bidder} on ${auctionAddress}`);
            await this.saveClaim({
                auction: auctionAddress,
                bidder,
                refundAmount: amount.toString(),
                type: "refund",
                timestamp: new Date(),
            });
            await this.createNotification(auctionAddress, bidder, "Refund claimed successfully!");
        });
    }

    private async saveAuction(auction: object): Promise<void> {
        if (!this.db) return;
        await this.db.collection("auctions").insertOne(auction);
    }

    private async saveBid(bid: object): Promise<void> {
        if (!this.db) return;
        await this.db.collection("bids").insertOne(bid);
    }

    private async updateBidReveal(auction: string, bidder: string, quantity: string): Promise<void> {
        if (!this.db) return;
        await this.db.collection("bids").updateOne(
            { auction, bidder },
            { $set: { revealed: true, revealedQuantity: quantity, revealedAt: new Date() } }
        );
    }

    private async updateAuctionCleared(auction: string, clearingPrice: string, totalDemand: string): Promise<void> {
        if (!this.db) return;
        await this.db.collection("auctions").updateOne(
            { address: auction },
            { $set: { isCleared: true, clearingPrice, totalDemand, clearedAt: new Date() } }
        );
    }

    private async saveClaim(claim: object): Promise<void> {
        if (!this.db) return;
        await this.db.collection("claims").insertOne(claim);
    }

    private async createNotification(auction: string, user: string, message: string): Promise<void> {
        if (!this.db) return;
        await this.db.collection("notifications").insertOne({
            auction,
            user,
            message,
            read: false,
            timestamp: new Date(),
        });
    }
}

// Main entry point
async function main() {
    console.log(`
  ╔═══════════════════════════════════════╗
  ║     🌊 ClearFall Protocol Indexer     ║
  ╚═══════════════════════════════════════╝
  `);

    const indexer = new ClearFallIndexer();

    try {
        await indexer.connect();
        await indexer.start();
    } catch (error) {
        console.error("❌ Indexer error:", error);
        process.exit(1);
    }
}

main();
