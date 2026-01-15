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
  <img src="https://img.shields.io/badge/Audited-Security_First-yellow?style=flat-square" alt="Audited" />
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

**ClearFall** is a trustless, time-based Dutch auction protocol engineered for transparent price discovery and fair token distribution. Built on Polygon's high-performance infrastructure, it enables permissionless auction creation and participation with cryptographic guarantees:

- 🔒 **Commit-Reveal Mechanism** - Cryptographic bid hiding prevents front-running and MEV attacks
- 📉 **Dutch Price Curve** - Deterministic linear price decay mechanism
- ⚖️ **Uniform Clearing Price** - Single equilibrium price for all successful bidders
- 🛡️ **Zero Admin Privileges** - Immutable auction parameters after deployment
- ⚡ **Gas Optimized** - Efficient storage patterns and batch operations for Polygon
- 🔐 **Non-Custodial** - Vault contract ensures trustless fund management

---

## 🏗️ Technical Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         ClearFall Protocol                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐     ┌──────────────┐     ┌─────────────────┐    │
│   │  Client  │────▶│   Frontend   │────▶│ WalletConnect   │    │
│   │          │     │  (Next.js)   │     │   + RainbowKit  │    │
│   └──────────┘     └──────────────┘     └────────┬────────┘    │
│                            │                      │              │
│                            │              ┌───────▼────────┐    │
│                            │              │  Polygon Chain  │    │
│                            │              │                 │    │
│                            │              │ Smart Contracts │    │
│                            │              │  • Factory      │    │
│                            │              │  • Auction      │    │
│                            │              │  • Vault        │    │
│                            │              └─────────────────┘    │
│                            │                      │              │
│                    ┌───────▼──────────────────────▼────┐         │
│                    │      Event Indexer (Optional)     │         │
│                    │  • TheGraph / Ponder / Goldsky    │         │
│                    │  • Caches events for fast queries │         │
│                    │  • Never source of truth          │         │
│                    └──────────────────────────────────┘         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Principles:**
- **Trustless by Default**: No admin keys, no upgradeable proxies, no backdoors
- **On-Chain Verification**: All auction state verifiable directly from blockchain
- **Efficient State Management**: Minimal storage slots, optimized for L2 gas costs
- **Event-Driven Frontend**: Real-time updates via WebSocket subscriptions

---

## 🎯 Protocol Mechanics

### Phase 1: Auction Creation
The auction creator deposits ERC20 tokens into the Vault and sets immutable parameters:
- `startPrice` - Initial Dutch auction price
- `endPrice` - Reserve/floor price
- `commitDuration` - Time window for hidden bids
- `revealDuration` - Time window for bid reveals
- `penaltyRate` - Penalty for non-revealed commitments (prevents griefing)

### Phase 2: Commit Phase
Bidders submit cryptographic commitments without revealing bid amounts:
```solidity
bytes32 commitment = keccak256(abi.encodePacked(quantity, nonce, msg.sender));
```
Corresponding funds (at `startPrice`) are locked in Vault upon commitment.

### Phase 3: Reveal Phase
Bidders reveal their actual quantities for on-chain verification:
```solidity
require(keccak256(abi.encodePacked(quantity, nonce, msg.sender)) == storedCommitment);
```
Non-revealed commitments incur penalty deduction from refunds.

### Phase 4: Automatic Clearing
Protocol calculates clearing when total demand meets or exceeds supply:
```solidity
clearingPrice = currentPrice() // Linear interpolation based on block.timestamp
```
All successful bidders pay the same uniform clearing price. Excess funds automatically refunded.

### Price Calculation
```solidity
price(t) = startPrice - ((startPrice - endPrice) * (t - startTime)) / duration
```
Pure mathematical function - no oracle dependencies, no price manipulation vectors.

---

## 🚀 Quick Start

### Prerequisites

**Required:**
- Node.js >= 18.0.0 (LTS recommended)
- npm >= 9.0.0 or yarn >= 1.22.0
- Git
- MetaMask, Rainbow, or any WalletConnect v2 compatible wallet

**Recommended:**
- Docker (for local blockchain testing)
- Hardhat CLI (installed via npm)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/clearfall-protocol.git
cd clearfall-protocol

# Install dependencies
npm install

# Navigate to frontend
cd frontend
npm install
```

### Environment Configuration

**Root Directory (.env):**
```bash
# Copy template
cp .env.example .env

# Required variables
PRIVATE_KEY=your_deployer_private_key_here
POLYGONSCAN_API_KEY=your_polygonscan_api_key
POLYGON_RPC_URL=https://polygon-rpc.com
AMOY_RPC_URL=https://rpc-amoy.polygon.technology

# Optional for testing
ETHERSCAN_API_KEY=your_etherscan_key
COINMARKETCAP_API_KEY=your_cmc_key
```

**Frontend (.env.local):**
```bash
cd frontend
cp .env.example .env.local

# Required configuration
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_walletconnect_project_id
NEXT_PUBLIC_FACTORY_ADDRESS=0x3f10025Ad4abddFa48eC05B63FFa84f71DA2d814
NEXT_PUBLIC_CHAIN_ID=80002  # 80002 for Amoy, 137 for Polygon mainnet
NEXT_PUBLIC_RPC_URL=https://rpc-amoy.polygon.technology

# Optional indexer endpoint
NEXT_PUBLIC_INDEXER_URL=https://api.studio.thegraph.com/query/...
```

### Compile Smart Contracts

```bash
# Compile Solidity contracts
npx hardhat compile

# Run test suite
npx hardhat test

# Generate coverage report
npx hardhat coverage

# Gas usage report
REPORT_GAS=true npx hardhat test
```

### Deploy to Network

```bash
# Deploy to local Hardhat network (for development)
npx hardhat node
npx hardhat run scripts/deploy.ts --network localhost

# Deploy to Polygon Amoy testnet
npx hardhat run scripts/deploy.ts --network amoy

# Verify contracts on Polygonscan
npx hardhat verify --network amoy DEPLOYED_ADDRESS

# Deploy to Polygon mainnet (production)
npx hardhat run scripts/deploy.ts --network polygon
```

**Post-Deployment:**
1. Copy the deployed `AuctionFactory` address
2. Update `frontend/.env.local` with the address
3. Verify contract on Polygonscan for transparency

### Run Development Server

```bash
cd frontend

# Start Next.js dev server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

Access the application at `http://localhost:3000` 🎉

---

## 📁 Repository Structure

```
clearfall-protocol/
├── 📂 contracts/              # Solidity smart contracts
│   ├── AuctionFactory.sol     # Factory pattern for auction deployment
│   ├── DutchAuction.sol       # Core auction state machine
│   ├── Vault.sol              # Non-custodial asset vault
│   ├── interfaces/            # Contract interfaces
│   └── mocks/                 # Mock tokens for testing
│
├── 📂 test/                   # Hardhat test suite
│   ├── AuctionFactory.test.ts
│   ├── DutchAuction.test.ts
│   └── Vault.test.ts
│
├── 📂 scripts/                # Deployment & utility scripts
│   ├── deploy.ts              # Main deployment script
│   └── verify.ts              # Contract verification
│
├── 📂 frontend/               # Next.js application
│   ├── src/
│   │   ├── app/               # App Router pages
│   │   │   ├── page.tsx       # Landing page
│   │   │   ├── create/        # Create auction
│   │   │   ├── auctions/      # Browse auctions
│   │   │   └── auction/[id]/  # Auction detail
│   │   ├── components/        # React components
│   │   │   ├── ui/            # Reusable UI components
│   │   │   ├── auction/       # Auction-specific components
│   │   │   └── layout/        # Layout components
│   │   ├── lib/               # Utilities & helpers
│   │   │   ├── contracts/     # Contract ABIs & addresses
│   │   │   ├── wagmi.ts       # Wagmi configuration
│   │   │   └── utils.ts       # Helper functions
│   │   └── hooks/             # Custom React hooks
│   ├── public/                # Static assets
│   └── tailwind.config.ts     # Tailwind CSS config
│
├── 📂 indexer/                # Optional event indexer
│   ├── schema.graphql         # GraphQL schema (if using TheGraph)
│   ├── subgraph.yaml          # Subgraph manifest
│   └── src/                   # Indexer mapping functions
│
├── hardhat.config.ts          # Hardhat configuration
├── tsconfig.json              # TypeScript config (root)
├── package.json               # Root dependencies
└── README.md                  # This file
```

---

## 🔐 Security Architecture

### Core Security Features

| Feature | Implementation | Benefit |
|---------|---------------|---------|
| 🔒 **Trustless** | No `onlyOwner` modifiers | Zero admin attack surface |
| 📝 **Immutable** | No UUPS/Transparent proxies | Parameters cannot be changed |
| ⏰ **Deterministic** | Pure math pricing function | No manipulation vectors |
| 💰 **Non-Custodial** | Vault segregation | Funds locked by cryptography |
| ✅ **Verifiable** | Complete on-chain state | Auditability via blockchain |
| 🔐 **Commit-Reveal** | Cryptographic commitments | MEV/front-running resistant |
| 🛡️ **Reentrancy Safe** | CEI pattern + ReentrancyGuard | Prevents reentrancy attacks |
| ⚡ **Gas Optimized** | Minimal storage operations | Cost-efficient for users |

### Audit Considerations

**Recommended Audits Before Mainnet:**
- Smart contract security audit (Certik, OpenZeppelin, etc.)
- Economic model review (mechanism design validation)
- Gas optimization analysis
- Integration testing with live tokens

**Self-Audit Checklist:**
- ✅ No delegatecall to untrusted contracts
- ✅ No tx.origin for authentication
- ✅ SafeERC20 for token transfers
- ✅ Proper access control patterns
- ✅ Integer overflow protection (Solidity 0.8+)
- ✅ Reentrancy guards on state-changing functions

---

## 🎨 Frontend Features

### Design System
- 🌑 **Dark Mode First** - Premium dark theme with high contrast
- 💎 **Glassmorphism** - Frosted glass effects with backdrop blur
- 🔲 **Neumorphism** - Soft shadows for tactile feel
- 🎭 **3D Transforms** - Interactive card tilts and depth
- ✨ **Micro-animations** - Smooth 60fps transitions
- 📱 **Fully Responsive** - Mobile-first design approach

### Technical Stack
- **Framework**: Next.js 14 (App Router)
- **Styling**: Tailwind CSS with custom design system
- **Web3**: Wagmi v2 + Viem for type-safe contract interactions
- **Wallet**: RainbowKit for beautiful wallet connection UX
- **State**: React Context + Custom hooks for global state
- **Forms**: React Hook Form with Zod validation
- **Charts**: Recharts for price curve visualization

---

## 📜 Contract Addresses

### Polygon Amoy Testnet

| Contract | Address | Explorer |
|----------|---------|----------|
| AuctionFactory | `0x3f10025Ad4abddFa48eC05B63FFa84f71DA2d814` | [View on PolygonScan](https://amoy.polygonscan.com/address/0x3f10025Ad4abddFa48eC05B63FFa84f71DA2d814) |

**Get Test Tokens:**
- MATIC faucet: https://faucet.polygon.technology/
- Test ERC20: Deploy mock token or use existing testnet tokens

### Polygon Mainnet

| Contract | Address | Explorer |
|----------|---------|----------|
| AuctionFactory | `Coming Soon` | [View on PolygonScan](https://polygonscan.com/) |

**Note**: Mainnet deployment pending security audit completion.

---

## 🧪 Testing & Development

### Running Tests

```bash
# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/DutchAuction.test.ts

# Run with gas reporting
REPORT_GAS=true npx hardhat test

# Generate coverage report
npx hardhat coverage

# Run tests with verbose logging
npx hardhat test --verbose
```

### Local Development Setup

```bash
# Terminal 1: Start local Hardhat node
npx hardhat node

# Terminal 2: Deploy contracts to local network
npx hardhat run scripts/deploy.ts --network localhost

# Terminal 3: Start frontend
cd frontend && npm run dev
```

### Test Network Setup

**Add Polygon Amoy to MetaMask:**
- Network Name: Polygon Amoy
- RPC URL: https://rpc-amoy.polygon.technology
- Chain ID: 80002
- Currency Symbol: MATIC
- Block Explorer: https://amoy.polygonscan.com

---

## 🛠️ Technology Stack

<table>
<tr>
<th colspan="4">Blockchain Layer</th>
</tr>
<tr>
<td align="center"><img src="https://img.shields.io/badge/-Solidity_0.8.20-363636?style=flat-square&logo=solidity" /><br/>Solidity</td>
<td align="center"><img src="https://img.shields.io/badge/-Hardhat-F7DF1E?style=flat-square" /><br/>Hardhat</td>
<td align="center"><img src="https://img.shields.io/badge/-OpenZeppelin_5.0-4E5EE4?style=flat-square" /><br/>OpenZeppelin</td>
<td align="center"><img src="https://img.shields.io/badge/-Polygon_PoS-8247E5?style=flat-square&logo=polygon" /><br/>Polygon</td>
</tr>
<tr>
<th colspan="4">Frontend Layer</th>
</tr>
<tr>
<td align="center"><img src="https://img.shields.io/badge/-Next.js_14-000000?style=flat-square&logo=nextdotjs" /><br/>Next.js</td>
<td align="center"><img src="https://img.shields.io/badge/-TypeScript_5-3178C6?style=flat-square&logo=typescript" /><br/>TypeScript</td>
<td align="center"><img src="https://img.shields.io/badge/-Tailwind_CSS-06B6D4?style=flat-square&logo=tailwindcss" /><br/>Tailwind</td>
<td align="center"><img src="https://img.shields.io/badge/-React_18-61DAFB?style=flat-square&logo=react" /><br/>React</td>
</tr>
<tr>
<th colspan="4">Web3 Integration</th>
</tr>
<tr>
<td align="center"><img src="https://img.shields.io/badge/-Wagmi_v2-000000?style=flat-square" /><br/>Wagmi</td>
<td align="center"><img src="https://img.shields.io/badge/-Viem-646CFF?style=flat-square" /><br/>Viem</td>
<td align="center"><img src="https://img.shields.io/badge/-RainbowKit-FF4785?style=flat-square" /><br/>RainbowKit</td>
<td align="center"><img src="https://img.shields.io/badge/-WalletConnect_v2-3B99FC?style=flat-square&logo=walletconnect" /><br/>WalletConnect</td>
</tr>
</table>

---

## 🗺️ Development Roadmap

### ✅ Phase 1: Core Protocol (Completed)
- [x] Smart contract architecture
- [x] Commit-reveal mechanism
- [x] Dutch auction pricing logic
- [x] Non-custodial vault system
- [x] Comprehensive test suite
- [x] Gas optimization

### ✅ Phase 2: Frontend & UX (Completed)
- [x] Next.js application with App Router
- [x] WalletConnect integration
- [x] Responsive design system
- [x] Real-time auction monitoring
- [x] Interactive price visualization
- [x] Transaction management UI

### 🔄 Phase 3: Advanced Features (In Progress)
- [ ] Multi-token auction support (ERC20, ERC721, ERC1155)
- [ ] Batch auction creation
- [ ] Advanced analytics dashboard
- [ ] Mobile native application (React Native)
- [ ] TheGraph subgraph indexing
- [ ] Email/push notifications

### 🔮 Phase 4: Protocol Extensions (Planned)
- [ ] ZK-SNARK privacy layer for bid amounts
- [ ] Cross-chain auction support (Polygon zkEVM, Arbitrum)
- [ ] DAO governance module
- [ ] Reputation system for auctioneers
- [ ] Auction insurance mechanism
- [ ] SDK for third-party integrations

### 🔬 Research & Innovation
- [ ] MEV resistance analysis and improvements
- [ ] Gas cost optimization for L1 deployment
- [ ] Alternative auction mechanisms (Vickrey, English)
- [ ] Formal verification of critical contracts

---

## 🤝 Contributing

We welcome contributions from the community! ClearFall is an open-source project built for builders.

### How to Contribute

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-username/clearfall-protocol.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-new-feature
   ```

3. **Make your changes**
   - Write clean, documented code
   - Add tests for new functionality
   - Update documentation as needed

4. **Run tests and linting**
   ```bash
   npm run test
   npm run lint
   ```

5. **Commit with clear messages**
   ```bash
   git commit -m "feat: add amazing new feature"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/amazing-new-feature
   ```

7. **Open a Pull Request**
   - Describe your changes clearly
   - Reference any related issues
   - Wait for review and feedback

### Contribution Guidelines

**Code Style:**
- Follow existing code conventions
- Use TypeScript for type safety
- Write self-documenting code with comments for complex logic
- Format with Prettier before committing

**Testing:**
- Maintain test coverage above 90%
- Write unit tests for new functions
- Add integration tests for user flows
- Test gas consumption for contract changes

**Documentation:**
- Update README for user-facing changes
- Add inline code documentation
- Update API documentation if applicable

### Areas for Contribution

- 🐛 Bug fixes and optimizations
- ✨ New features and enhancements
- 📝 Documentation improvements
- 🎨 UI/UX design refinements
- 🧪 Additional test coverage
- 🌐 Internationalization (i18n)
- ♿ Accessibility improvements

---

## 📞 Community & Support

- 💬 **Discord**: [Join our community](https://discord.gg/clearfall)
- 🐦 **Twitter**: [@ClearFallProtocol](https://twitter.com/clearfall)
- 📧 **Email**: support@clearfall.xyz
- 📖 **Documentation**: [docs.clearfall.xyz](https://docs.clearfall.xyz)
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/clearfall/protocol/issues)

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

**Important Notice:**

This software is provided "as is" without warranty of any kind. The ClearFall Protocol is experimental software and may contain bugs or vulnerabilities. Users should:

- Conduct their own security audits
- Test thoroughly on testnets before mainnet deployment
- Understand the risks of smart contract interactions
- Never invest more than they can afford to lose
- Comply with local laws and regulations regarding token sales

The developers are not responsible for any losses incurred through the use of this protocol.

---

## 🙏 Acknowledgments

Built with amazing open-source tools and inspired by industry leaders:

- **[OpenZeppelin](https://openzeppelin.com/)** - Secure smart contract library standards
- **[Polygon Technology](https://polygon.technology/)** - High-performance L2 infrastructure
- **[WalletConnect](https://walletconnect.com/)** - Open protocol for wallet connections
- **[Vercel](https://vercel.com/)** - Deployment and hosting platform
- **[Hardhat](https://hardhat.org/)** - Ethereum development environment
- **[Wagmi](https://wagmi.sh/)** - React hooks for Ethereum

Special thanks to the Ethereum and DeFi communities for pioneering decentralized finance.

---

## 🎯 Built For

<p align="center">
  <img src="https://img.shields.io/badge/Built%20for-Buildathons-8b5cf6?style=for-the-badge" alt="Built for Buildathons" />
  <img src="https://img.shields.io/badge/Powered%20by-Polygon-8247E5?style=for-the-badge&logo=polygon" alt="Powered by Polygon" />
  <img src="https://img.shields.io/badge/Open%20Source-Forever-22c55e?style=for-the-badge" alt="Open Source" />
</p>

<p align="center">
  <sub>Built with 💜 by the ClearFall Team</sub>
</p>

<p align="center">
  <sub>Empowering transparent, fair, and trustless token distribution</sub>
</p>

---

<p align="center">
  <a href="#top">⬆️ Back to Top</a>
</p>