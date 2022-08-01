import { ethers } from "hardhat"
import * as dotenv from "dotenv"
dotenv.config()


async function main() {
    console.log("Deploying TokenUtil contract...")
    const tokenUtilFactory = await ethers.getContractFactory(
        "TokenUtil"
    )
    const tokenUtil = await tokenUtilFactory.deploy()
    await tokenUtil.deployed()
    console.log("TokenUtil deployed to:", tokenUtil.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})