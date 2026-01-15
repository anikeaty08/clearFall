import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("🚀 Deploying ClearFall Protocol...");
    console.log("📍 Deployer address:", deployer.address);
    console.log("💰 Deployer balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "MATIC");
    console.log("");

    // Deploy AuctionFactory
    console.log("📦 Deploying AuctionFactory...");
    const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
    const factory = await AuctionFactory.deploy();
    await factory.waitForDeployment();
    const factoryAddress = await factory.getAddress();
    console.log("✅ AuctionFactory deployed to:", factoryAddress);
    console.log("");

    // Verification info
    console.log("============================================");
    console.log("🎉 ClearFall Protocol Deployment Complete!");
    console.log("============================================");
    console.log("");
    console.log("📋 Contract Addresses:");
    console.log("   AuctionFactory:", factoryAddress);
    console.log("");
    console.log("🔧 Next Steps:");
    console.log("   1. Update frontend/.env.local with NEXT_PUBLIC_FACTORY_ADDRESS");
    console.log("   2. Run: npx hardhat verify --network <network> " + factoryAddress);
    console.log("");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });
