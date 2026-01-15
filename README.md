<p align="center">
  <img src="https://img.shields.io/badge/ClearFall-Protocol-8b5cf6?style=for-the-badge&logo=ethereum&logoColor=white" alt="ClearFall Protocol" />
</p>

<h1 align="center">
  🌊 ClearFall Protocol
</h1>

<p align="center">
  <strong>Decentralized Dutch Auction Platform on Polygon</strong>
</p>

<p align="center">
  <a href="https://polygon.technology/">
    <img src="https://img.shields.io/badge/Polygon-8247E5?style=for-the-badge&logo=polygon&logoColor=white" alt="Polygon" />
  </a>
  <a href="https://soliditylang.org/">
    <img src="https://img.shields.io/badge/Solidity-363636?style=for-the-badge&logo=solidity&logoColor=white" alt="Solidity" />
  </a>
  <a href="https://nextjs.org/">
    <img src="https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white" alt="Next.js" />
  </a>
  <a href="https://www.typescriptlang.org/">
    <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-Production_Ready-22c55e?style=flat-square" alt="Status" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" />
  <img src="https://img.shields.io/badge/PRs-Welcome-ff69b4?style=flat-square" alt="PRs Welcome" />
  <img src="https://img.shields.io/badge/Made%20with-❤️-red?style=flat-square" alt="Made with Love" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/🔒-Trustless-8b5cf6?style=flat-square" alt="Trustless" />
  <img src="https://img.shields.io/badge/⚡-Gas%20Efficient-06b6d4?style=flat-square" alt="Gas Efficient" />
  <img src="https://img.shields.io/badge/🛡️-No%20Admin-22c55e?style=flat-square" alt="No Admin" />
  <img src="https://img.shields.io/badge/🔗-Fully%20On--Chain-ec4899?style=flat-square" alt="On-Chain" />
</p>

---

## 📖 What is ClearFall?

**ClearFall** is a trustless, time-based Dutch auction protocol with fair price discovery. Built on Polygon, it enables anyone to create and participate in transparent token auctions with:

- 🔒 **Commit-Reveal Mechanism** - Hidden bids prevent front-running
- 📉 **Dutch Price Curve** - Price decreases over time deterministically
- ⚖️ **Uniform Clearing Price** - All winners pay the same fair price
- 🛡️ **No Admin Privileges** - Fully decentralized after auction creation
- ⚡ **Gas Efficient** - Optimized for Polygon network

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         ClearFall Protocol                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐     ┌──────────────┐     ┌─────────────────┐    │
│   │  User    │────▶│   Frontend   │────▶│ WalletConnect   │    │
│   │          │     │  (Next.js)   │     │                 │    │
│   └──────────┘     └──────────────┘     └────────┬────────┘    │
│                                                   │              │
│                                          ┌────────▼────────┐    │
│                                          │  Polygon Chain  │    │
│                                          │                 │    │
│   ┌──────────────────────────────────────┤  Smart Contracts│    │
│   │                                      │                 │    │
│   │  ┌────────────────┐                  │  • AuctionFactory│   │
│   │  │    Indexer     │◀─── Events ─────│  • DutchAuction │    │
│   │  │   (Optional)   │                  │  • Vault        │    │
│   │  └───────┬────────┘                  └─────────────────┘    │
│   │          │                                                   │
│   │  ┌───────▼────────┐                                         │
│   │  │  MongoDB Atlas │  (Cache only - never trusted)           │
│   │  └────────────────┘                                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 How It Works

### 1️⃣ Create Auction
Deposit tokens and set immutable parameters:
- Start/End prices
- Commit/Reveal durations
- Non-reveal penalty

### 2️⃣ Commit Phase
Bidders submit hidden commitments:
```
hash = keccak256(quantity, nonce, address)
```
Funds are locked in the vault.

### 3️⃣ Reveal Phase
Bidders reveal their quantities for verification.

### 4️⃣ Automatic Clearing
When `totalDemand ≥ totalSupply`:
```
clearingPrice = priceAt(currentTime)
```
All winners pay this uniform price.

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- npm or yarn
- MetaMask or WalletConnect-compatible wallet

### Installation

```bash
# Clone the repository
git clone https://github.com/your-repo/clearfall.git
cd clearfall

# Install root dependencies (Hardhat)
npm install

# Install frontend dependencies
cd frontend
npm install
```

### Configuration

1. Copy environment files:
```bash
cp .env.example .env
cp frontend/.env.example frontend/.env.local
```

2. Add your configuration:
```env
# .env (root)
PRIVATE_KEY=your_private_key
POLYGONSCAN_API_KEY=your_api_key

# frontend/.env.local
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
NEXT_PUBLIC_FACTORY_ADDRESS=deployed_address
NEXT_PUBLIC_CHAIN_ID=80002
```

### Compile & Deploy

```bash
# Compile contracts
npm run compile

# Deploy to Polygon Amoy (testnet)
npm run deploy:amoy

# Deploy to Polygon mainnet
npm run deploy:polygon
```

### Run Frontend

```bash
cd frontend
npm run dev
```

Visit `http://localhost:3000` 🎉

---

## 📁 Project Structure

```
clearfall/
├── 📂 contracts/           # Solidity smart contracts
│   ├── AuctionFactory.sol  # Factory for creating auctions
│   ├── DutchAuction.sol    # Core auction logic
│   ├── Vault.sol           # Asset management
│   └── mocks/              # Test contracts
│
├── 📂 frontend/            # Next.js application
│   ├── src/
│   │   ├── app/            # Pages (App Router)
│   │   ├── components/     # React components
│   │   └── lib/            # Utilities & ABIs
│   └── public/             # Static assets
│
├── 📂 indexer/             # Optional event indexer
│   └── src/                # Event listeners
│
├── 📂 scripts/             # Deployment scripts
│   └── deploy.ts           # Main deploy script
│
├── hardhat.config.ts       # Hardhat configuration
├── package.json            # Root dependencies
└── README.md               # You are here! 👋
```

---

## 🔐 Security Features

| Feature | Description |
|---------|-------------|
| 🔒 **No Admin** | No owner functions or backdoors |
| 📝 **Immutable Params** | Cannot be changed after creation |
| ⏰ **Time-based Pricing** | Pure math, no manipulation |
| 💰 **Locked Funds** | Secured at commit time |
| ✅ **Deterministic Clearing** | Fully verifiable on-chain |
| 🔐 **Commit-Reveal** | Prevents front-running |

---

## 🎨 UI Features

- 🌑 **Dark Minimalism** - Premium dark theme
- 💎 **Glassmorphism** - Frosted glass effects
- 🔲 **Neumorphism** - Soft shadow UI elements
- 🎭 **3D Transforms** - Interactive card effects
- ✨ **Micro-animations** - Smooth transitions

---

## 📜 Smart Contract Addresses

### Polygon Amoy (Testnet)
| Contract | Address |
|----------|---------|
| AuctionFactory | `TBD after deployment` |

### Polygon Mainnet
| Contract | Address |
|----------|---------|
| AuctionFactory | `TBD after deployment` |

---

## 🧪 Testing

```bash
# Run Hardhat tests
npm run test

# Run with coverage
npm run coverage
```

---

## 🛠️ Tech Stack

<table>
<tr>
<td align="center"><img src="https://img.shields.io/badge/-Solidity-363636?style=flat-square&logo=solidity" /><br/>Solidity</td>
<td align="center"><img src="https://img.shields.io/badge/-Hardhat-F7DF1E?style=flat-square&logo=hardhat" /><br/>Hardhat</td>
<td align="center"><img src="https://img.shields.io/badge/-OpenZeppelin-4E5EE4?style=flat-square&logo=openzeppelin" /><br/>OpenZeppelin</td>
<td align="center"><img src="https://img.shields.io/badge/-Next.js-000000?style=flat-square&logo=nextdotjs" /><br/>Next.js</td>
</tr>
<tr>
<td align="center"><img src="https://img.shields.io/badge/-TypeScript-3178C6?style=flat-square&logo=typescript" /><br/>TypeScript</td>
<td align="center"><img src="https://img.shields.io/badge/-Tailwind-06B6D4?style=flat-square&logo=tailwindcss" /><br/>Tailwind</td>
<td align="center"><img src="https://img.shields.io/badge/-Wagmi-000000?style=flat-square" /><br/>Wagmi</td>
<td align="center"><img src="https://img.shields.io/badge/-Viem-646CFF?style=flat-square" /><br/>Viem</td>
</tr>
</table>

---

## 🗺️ Roadmap

- [x] ✅ Core smart contracts
- [x] ✅ Frontend with 3D effects
- [x] ✅ WalletConnect integration
- [ ] 🔄 ZK-proof integration (upgradeable)
- [ ] 🔄 Multi-token support
- [ ] 🔄 Governance module

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

```bash
# Fork the repo
# Create your feature branch
git checkout -b feature/amazing-feature

# Commit your changes
git commit -m "Add amazing feature"

# Push to the branch
git push origin feature/amazing-feature

# Open a Pull Request
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) for secure contract libraries
- [Polygon](https://polygon.technology/) for the awesome L2
- [WalletConnect](https://walletconnect.com/) for wallet integration

---

<p align="center">
  <img src="https://img.shields.io/badge/Built%20for-Hackathons-8b5cf6?style=for-the-badge" alt="Built for Hackathons" />
  <img src="https://img.shields.io/badge/Powered%20by-Polygon-8247E5?style=for-the-badge&logo=polygon" alt="Powered by Polygon" />
</p>

<p align="center">
  <sub>Made with 💜 by the ClearFall Team</sub>
</p>

<p align="center">
  <a href="#top">⬆️ Back to Top</a>
</p>
