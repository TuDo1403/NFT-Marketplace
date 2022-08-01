import { ethers } from "hardhat"
import * as dotenv from "dotenv"
dotenv.config()


async function main() {
    console.log("Deploying ERC20Test contract...")
    const erc20Factory = await ethers.getContractFactory(
        "ERC20Test"
    )
    const erc20 = await erc20Factory.deploy("PaymentToken", "PMT")
    await erc20.deployed()
    console.log("ERC20 deployed to:", erc20.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})