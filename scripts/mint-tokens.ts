import { ethers } from "hardhat";

/**
 * Helper script to mint MockERC20 tokens for testing
 * Usage: npx hardhat run scripts/mint-tokens.ts --network amoy
 */
async function main() {
    const [deployer] = await ethers.getSigners();
    
    // MockERC20 address from deployment
    const MOCK_TOKEN_ADDRESS = "0x0A6a78F42002754ae3F14915A57a069e7f9f2CF8";
    
    console.log("🪙 Minting MockERC20 tokens...");
    console.log("📍 Deployer address:", deployer.address);
    console.log("💰 Deployer balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "MATIC");
    console.log("");
    
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockToken = MockERC20.attach(MOCK_TOKEN_ADDRESS);
    
    // Mint 1,000,000 tokens (18 decimals)
    const amount = ethers.parseEther("1000000");
    
    console.log("📝 Minting", ethers.formatEther(amount), "tokens to", deployer.address);
    const tx = await mockToken.mint(deployer.address, amount);
    await tx.wait();
    
    const balance = await mockToken.balanceOf(deployer.address);
    console.log("✅ Mint successful!");
    console.log("💰 New balance:", ethers.formatEther(balance), "tokens");
    console.log("");
    console.log("📋 Token Info:");
    console.log("   Name:", await mockToken.name());
    console.log("   Symbol:", await mockToken.symbol());
    console.log("   Decimals:", await mockToken.decimals());
    console.log("   Address:", MOCK_TOKEN_ADDRESS);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Minting failed:", error);
        process.exit(1);
    });
