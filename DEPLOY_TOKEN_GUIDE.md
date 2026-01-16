# How to Create/Deploy an ERC20 Token for ClearFall Auctions

## Quick Overview

To create an auction, you need an ERC20 token address. You have 3 options:

1. **Use Pre-Deployed Test Token** (Easiest for testing)
2. **Deploy Your Own Token** (Recommended for production)
3. **Use Existing Token** (If you already have one)

---

## Option 1: Use Pre-Deployed Test Token

If a MockERC20 token is already deployed, you can use its address directly:

1. Check the frontend `.env.local` for `NEXT_PUBLIC_MOCK_TOKEN_ADDRESS`
2. Copy the address and paste it in the "Token Address" field
3. Make sure you have tokens minted to your address

---

## Option 2: Deploy Your Own Token

### Step 1: Deploy MockERC20

```bash
# Navigate to project root
cd clearfall

# Deploy to Polygon Amoy testnet
npx hardhat run scripts/deploy.ts --network amoy
```

This will output:
- MockERC20 address
- AuctionFactory address

### Step 2: Mint Tokens to Your Address

```bash
# Update scripts/mint-tokens.ts with your MockERC20 address
# Then run:
npx hardhat run scripts/mint-tokens.ts --network amoy
```

### Step 3: Use the Token Address

Copy the MockERC20 address from the deployment output and use it in the auction creation form.

---

## Option 3: Create Custom Deploy Script

Create `scripts/deploy-my-token.ts`:

```typescript
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying token with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "MATIC");

  // Deploy MockERC20
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const token = await MockERC20.deploy(
    "My Auction Token",  // Name
    "MAT",                // Symbol
    18                    // Decimals (standard is 18)
  );

  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  
  console.log("✅ Token deployed to:", tokenAddress);
  console.log("📋 Token Info:");
  console.log("   Name:", await token.name());
  console.log("   Symbol:", await token.symbol());
  console.log("   Decimals:", await token.decimals());

  // Mint tokens to deployer
  const mintAmount = ethers.parseEther("1000000"); // 1M tokens
  await token.mint(deployer.address, mintAmount);
  console.log("✅ Minted", ethers.formatEther(mintAmount), "tokens to", deployer.address);

  // Check balance
  const balance = await token.balanceOf(deployer.address);
  console.log("💰 Your balance:", ethers.formatEther(balance), "tokens");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Run it:
```bash
npx hardhat run scripts/deploy-my-token.ts --network amoy
```

---

## Using the Token in Auction

1. **Copy the token address** from deployment output
2. **Paste it** in the "Token Address" field when creating an auction
3. **Set Total Supply** - This is how many tokens you want to auction (must be ≤ your balance)
4. **Approve the Vault** - When you create the auction, you'll need to approve the Vault contract to spend your tokens

---

## Important Notes

- **Testnet**: Polygon Amoy uses test MATIC (not real money)
- **Token Balance**: Make sure you have enough tokens to cover the total supply
- **Approval**: The auction will automatically create a Vault that needs approval to transfer your tokens
- **Decimals**: Most tokens use 18 decimals (1 token = 10^18 wei)

---

## Troubleshooting

**"Insufficient token balance"**
- Mint more tokens to your address
- Check you're using the correct token address

**"Token approval failed"**
- Approve the Vault contract address to spend your tokens
- The Vault address is created when the auction is created

**"Invalid token address"**
- Make sure the address starts with `0x`
- Verify it's a valid ERC20 contract on Polygon Amoy
- Check on [PolygonScan Amoy](https://amoy.polygonscan.com)

---

## Next Steps

After deploying your token:
1. ✅ Copy the token address
2. ✅ Mint tokens to your wallet
3. ✅ Create an auction using that token address
4. ✅ Set your desired auction parameters
5. ✅ Start the auction!
