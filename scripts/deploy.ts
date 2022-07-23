// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import {ethers, upgrades} from "hardhat"
import * as dotenv from "dotenv"
dotenv.config()
import {Marketplace, NFTFactory} from "../typechain-types"

const TREASURY = process.env.TREASURY || ""
const VERIFIER = process.env.VERIFIER || ""
const SERVICE_FEE_RIGHT_SHIFT_BIT = 6

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    console.log("Deploying Governance contract...")
    const GovernanceFactory = await ethers.getContractFactory("Governance")
    const governance = await GovernanceFactory.deploy(TREASURY, VERIFIER)
    await governance.deployed()
    console.log("Governance deployed to:", governance.address)

    console.log("Deploying Collectible1155Base contract...")
    const collectible1155Factory = await ethers.getContractFactory(
        "Collectible1155"
    )
    const collectible1155Base = await collectible1155Factory.deploy()
    await collectible1155Base.deployed()
    console.log("Collectible1155Base deployed to:", collectible1155Base.address)

    console.log("Deploying Collectible721Base contract...")
    const Collectible721Factory = await ethers.getContractFactory(
        "Collectible721"
    )
    const collectible721Base = await Collectible721Factory.deploy()
    await collectible721Base.deployed()
    console.log("Collectible721Base deployed to:", collectible721Base.address)

    console.log("Deploying Marketplace contract...")
    const MarketplaceFactory = await ethers.getContractFactory("Marketplace")
    const marketplace = (await upgrades.deployProxy(
        MarketplaceFactory,
        [governance.address, SERVICE_FEE_RIGHT_SHIFT_BIT],
        {initializer: "initialize"}
    )) as Marketplace
    await marketplace.deployed()
    console.log("Marketplace deployed to: ", marketplace.address)

    console.log("Deploying NFTFactory contract...")
    const NFTFactoryFactory = await ethers.getContractFactory("NFTFactory")
    const nftFactory = (await upgrades.deployProxy(
        NFTFactoryFactory,
        [governance.address],
        {initializer: "initialize"}
    )) as NFTFactory
    await nftFactory.deployed()
    console.log("NFTFactory deployed to:", nftFactory.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
