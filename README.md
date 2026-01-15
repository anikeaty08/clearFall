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
  <img src="https://img.shields.io/badge/🔒-Trustless-8b5cf6?style=flat-square" alt="Trustless" />
  <img src="https://img.shields.io/badge/⚡-Gas%20Efficient-06b6d4?style=flat-square" alt="Gas Efficient" />
  <img src="https://img.shields.io/badge/🛡️-No%20Admin-22c55e?style=flat-square" alt="No Admin" />
  <img src="https://img.shields.io/badge/🔗-Fully%20On--Chain-ec4899?style=flat-square" alt="On-Chain" />
</p>

---

## 📖 What is ClearFall?

**ClearFall** is a trustless, time-based Dutch auction protocol engineered for transparent price discovery and fair token distribution. Built on Polygon's high-performance infrastructure:

- 🔒 **Commit-Reveal Mechanism** - Cryptographic bid hiding prevents front-running and MEV attacks
- 📉 **Dutch Price Curve** - Deterministic linear price decay mechanism
- ⚖️ **Uniform Clearing Price** - Single equilibrium price for all successful bidders
- 🛡️ **Zero Admin Privileges** - Immutable auction parameters after deployment
- ⚡ **Gas Optimized** - Efficient storage patterns for Polygon
- 🔐 **Non-Custodial** - Vault contract ensures trustless fund management

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         ClearFall Protocol                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐     ┌──────────────┐     ┌─────────────────┐    │
│   │  Client  │────▶│   Frontend   │────▶│ WalletConnect   │    │
│   │          │     │  (Next.js)   │     │   + RainbowKit  │    │
│   └──────────┘     └──────────────┘     └────────┬────────┘    │
│                                                   │              │
│                                          ┌────────▼────────┐    │
│                                          │  Polygon Chain  │    │
│                                          │                 │    │
│                                          │ Smart Contracts │    │
│                                          │  • Factory      │    │
│                                          │  • Auction      │    │
│                                          │  • Vault        │    │
│                                          └─────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 How It Works

### 1️⃣ Create Auction
Deposit tokens and set immutable parameters: start/end prices, commit/reveal durations, penalty rate.

### 2️⃣ Commit Phase
Bidders submit cryptographic commitments:
```solidity
bytes32 commitment = keccak256(abi.encodePacked(quantity, nonce, msg.sender));
```
Funds locked in Vault at `startPrice`.

### 3️⃣ Reveal Phase
Bidders reveal quantities for verification:
```solidity
require(keccak256(abi.encodePacked(quantity, nonce, msg.sender)) == storedCommitment);
```

### 4️⃣ Automatic Clearing
When total demand ≥ supply:
```solidity
clearingPrice = startPrice - ((startPrice - endPrice) * elapsed) / duration
```
All winners pay the same uniform price. Excess refunded.

---

## 🚀 Quick Start

### Prerequisites
- Node.js >= 18.0.0
- npm or yarn
- MetaMask or WalletConnect wallet

### Installation

```bash
# Clone repository
git clone https://github.com/your-username/clearfall-protocol.git
cd clearfall-protocol

# Install dependencies
npm install

# Install frontend dependencies
cd frontend
npm install
```

### Environment Setup

**Root (.env):**
```bash
PRIVATE_KEY=your_deployer_private_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
AMOY_RPC_URL=https://rpc-amoy.polygon.technology
```

**Frontend (.env.local):**
```bash
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_walletconnect_project_id
NEXT_PUBLIC_FACTORY_ADDRESS=0x3f10025Ad4abddFa48eC05B63FFa84f71DA2d814
NEXT_PUBLIC_CHAIN_ID=80002
NEXT_PUBLIC_RPC_URL=https://rpc-amoy.polygon.technology
```

### Deploy & Run

```bash
# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to Amoy testnet
npx hardhat run scripts/deploy.ts --network amoy

# Start frontend
cd frontend
npm run dev
```

Visit `http://localhost:3000` 🎉

---

## 📁 Project Structure

```
clearfall-protocol/
├── 📂 contracts/              # Solidity smart contracts
│   ├── AuctionFactory.sol     # Factory for auction deployment
│   ├── DutchAuction.sol       # Core auction logic
│   ├── Vault.sol              # Asset management
│   └── mocks/                 # Test contracts
│
├── 📂 frontend/               # Next.js application
│   ├── src/
│   │   ├── app/               # App Router pages
│   │   ├── components/        # React components
│   │   ├── lib/               # Utilities & ABIs
│   │   └── hooks/             # Custom React hooks
│   └── public/                # Static assets
│
├── 📂 scripts/                # Deployment scripts
├── 📂 test/                   # Test suite
└── hardhat.config.ts          # Hardhat config
```

---

## 🔐 Security Features

| Feature | Implementation |
|---------|---------------|
| 🔒 **Trustless** | No admin keys or backdoors |
| 📝 **Immutable** | Parameters locked after creation |
| ⏰ **Deterministic** | Pure math pricing function |
| 💰 **Non-Custodial** | Vault segregation |
| ✅ **Verifiable** | Complete on-chain state |
| 🔐 **Commit-Reveal** | MEV/front-running resistant |

---

## 📜 Contract Addresses

### Polygon Amoy Testnet

| Contract | Address |
|----------|---------|
| AuctionFactory | [`0x3f10025Ad4abddFa48eC05B63FFa84f71DA2d814`](https://amoy.polygonscan.com/address/0x3f10025Ad4abddFa48eC05B63FFa84f71DA2d814) |

**Get Test Tokens:**
- MATIC faucet: https://faucet.polygon.technology/

---

## 🧪 Testing

```bash
# Run all tests
npx hardhat test

# Run with gas reporting
REPORT_GAS=true npx hardhat test

# Generate coverage
npx hardhat coverage
```

---

## 🛠️ Tech Stack

<table>
<tr>
<td align="center"><img src="https://img.shields.io/badge/-Solidity-363636?style=flat-square&logo=solidity" /><br/>Solidity</td>
<td align="center"><img src="https://img.shields.io/badge/-Hardhat-F7DF1E?style=flat-square" /><br/>Hardhat</td>
<td align="center"><img src="https://img.shields.io/badge/-OpenZeppelin-4E5EE4?style=flat-square" /><br/>OpenZeppelin</td>
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
- [x] ✅ Frontend with WalletConnect
- [x] ✅ Polygon Amoy deployment
- [ ] 🔄 Multi-token support
- [ ] 🔄 Mobile application
- [ ] 🔄 Cross-chain support

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) - Secure contract libraries
- [Polygon](https://polygon.technology/) - L2 infrastructure
- [WalletConnect](https://walletconnect.com/) - Wallet integration
- [Hardhat](https://hardhat.org/) - Development environment

---

<p align="center">
  <img src="https://img.shields.io/badge/Built%20for-Buildathons-8b5cf6?style=for-the-badge" alt="Built for Buildathons" />
  <img src="https://img.shields.io/badge/Powered%20by-Polygon-8247E5?style=for-the-badge&logo=polygon" alt="Powered by Polygon" />
</p>

<p align="center">
  <sub>Built with 💜 by the ClearFall Team</sub>
</p>

<p align="center">
  <a href="#top">⬆️ Back to Top</a>
</p>