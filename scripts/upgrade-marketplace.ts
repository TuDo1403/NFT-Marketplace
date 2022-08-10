import { ethers, upgrades } from "hardhat"
import * as dotenv from "dotenv"
dotenv.config()
import { Marketplace } from "../typechain-types"
import { Governance } from '../typechain-types/contracts/Governance';


const PRIVATE_KEY = process.env.PRIVATE_KEY || ""
const GOVERNANCE = process.env.TREASURY || ""
const SERVICE_FEE = 200

async function main() {
    // console.log("Deploying Collectible1155Base contract...")
    // const collectible1155Factory = await ethers.getContractFactory(
    //     "Collectible1155"
    // )
    // const collectible1155Base = await collectible1155Factory.deploy()
    // await collectible1155Base.deployed()
    // console.log("Collectible1155Base deployed to:", collectible1155Base.address)

    // console.log("Deploying Collectible721Base contract...")
    // const Collectible721Factory = await ethers.getContractFactory(
    //     "Collectible721"
    // )
    // const collectible721Base = await Collectible721Factory.deploy()
    // await collectible721Base.deployed()
    // console.log("Collectible721Base deployed to:", collectible721Base.address)

    console.log("Upgrading Marketplace contract...")
    const MarketplaceFactory = await ethers.getContractFactory("Marketplace")
    const marketplace = (await upgrades.upgradeProxy(
        "0x27363292b64362D5268EEf5f17f534E9A163B976",
        MarketplaceFactory
    )) as Marketplace
    await marketplace.deployed()
    console.log("Marketplace upgrades to: ", marketplace.address)

    // const signer = new ethers.Wallet(PRIVATE_KEY)
    // const governance = (await ethers.getContractAt("Governance", GOVERNANCE)) as Governance
    //     ; (await governance).connect(signer).updateMarketplace(marketplace.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})