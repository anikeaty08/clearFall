import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("🚀 Deploying ClearFall Protocol...");
    console.log("📍 Deployer address:", deployer.address);
    console.log("💰 Deployer balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "MATIC");
    console.log("");

    // Deploy MockERC20 (for testing)
    console.log("📦 Deploying MockERC20...");
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockToken = await MockERC20.deploy(
        "ClearFall Test Token",
        "CFT",
        18 // decimals
    );
    await mockToken.waitForDeployment();
    const mockTokenAddress = await mockToken.getAddress();
    console.log("✅ MockERC20 deployed to:", mockTokenAddress);
    console.log("");

    // Deploy AuctionFactory
    console.log("📦 Deploying AuctionFactory...");
    const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
    const factory = await AuctionFactory.deploy();
    await factory.waitForDeployment();
    const factoryAddress = await factory.getAddress();
    console.log("✅ AuctionFactory deployed to:", factoryAddress);
    console.log("");

    // Note: Vault and DutchAuction are deployed automatically
    // - Vault is deployed by DutchAuction when an auction is created
    // - DutchAuction is deployed by AuctionFactory when createAuction() is called
    console.log("ℹ️  Note: Vault and DutchAuction contracts are deployed automatically:");
    console.log("   - DutchAuction: Created by AuctionFactory.createAuction()");
    console.log("   - Vault: Created by each DutchAuction instance");
    console.log("");

    // Verification info
    console.log("============================================");
    console.log("🎉 ClearFall Protocol Deployment Complete!");
    console.log("============================================");
    console.log("");
    console.log("📋 Contract Addresses:");
    console.log("   MockERC20:", mockTokenAddress);
    console.log("   AuctionFactory:", factoryAddress);
    console.log("");
    console.log("🔧 Next Steps:");
    console.log("   1. Update frontend/.env.local with:");
    console.log("      NEXT_PUBLIC_AUCTION_FACTORY_ADDRESS=" + factoryAddress);
    console.log("      NEXT_PUBLIC_MOCK_TOKEN_ADDRESS=" + mockTokenAddress);
    console.log("   2. Mint some test tokens: mockToken.mint(deployer, amount)");
    console.log("   3. Create an auction using AuctionFactory.createAuction()");
    console.log("   4. Verify contracts: npx hardhat verify --network amoy <address>");
    console.log("");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });
