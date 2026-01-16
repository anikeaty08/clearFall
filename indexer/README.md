# ClearFall Indexer

Event indexer for the ClearFall Protocol that listens to blockchain events and stores them in MongoDB.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file:
```env
POLYGON_RPC_URL=https://rpc-amoy.polygon.technology
MONGODB_URI=mongodb://localhost:27017
FACTORY_ADDRESS=0x3f10025Ad4abddFa48eC05B63FFa84f71DA2d814
```

3. Make sure MongoDB is running:
```bash
# If using local MongoDB
mongod

# Or use MongoDB Atlas connection string in MONGODB_URI
```

## Running

Development mode:
```bash
npm run dev
```

Production mode:
```bash
npm run build
npm start
```

## What it does

- Listens for `AuctionCreated` events from the Factory contract
- Indexes all auction events (commitments, reveals, clearing, claims)
- Stores data in MongoDB collections:
  - `auctions` - Auction metadata
  - `bids` - Bid commitments and reveals
  - `claims` - Token claims and refunds
  - `notifications` - User notifications

## Database Collections

- **auctions**: Auction information (address, creator, token, prices, etc.)
- **bids**: Bid commitments and reveals
- **claims**: Claimed tokens and refunds
- **notifications**: User notifications for auction events
