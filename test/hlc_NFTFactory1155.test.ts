import {expect} from "chai"
import {ethers} from "hardhat"
import * as crypto from "crypto"
import {Collectible1155, Governance, NFTFactory1155} from "../typechain"
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {BigNumber} from "ethers"

describe("NFTFactory1155", () => {
    let manager: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let users: SignerWithAddress[]

    let governance: Governance
    let nftFactory1155: NFTFactory1155
    let collectible1155: Collectible1155

    beforeEach(async () => {
        ;[manager, treasury, verifier, ...users] = await ethers.getSigners()

        const GovernanceFactory = await ethers.getContractFactory(
            "Governance",
            manager
        )
        governance = await GovernanceFactory.deploy(
            manager.address,
            treasury.address,
            verifier.address
        )
        await governance.deployed()

        const Collectible1155Factory = await ethers.getContractFactory(
            "Collectible1155",
            manager
        )

        collectible1155 = await Collectible1155Factory.deploy(manager.address)
        await collectible1155.deployed()
    })

    describe("constructor", () => {
        it("should initialize the governace address", async () => {
            const NFTFactory1155Factory = await ethers.getContractFactory(
                "NFTFactory1155",
                manager
            )
            nftFactory1155 = await NFTFactory1155Factory.deploy(
                governance.address
            )
            await nftFactory1155.deployed()
            const governanceAddress = await nftFactory1155.governance()
            expect(governanceAddress).to.equal(governance.address)
        })

        it("should revert when governance address is invalid", async () => {
            const NFTFactory1155Factory = await ethers.getContractFactory(
                "NFTFactory1155",
                manager
            )
            await expect(
                NFTFactory1155Factory.deploy(ethers.constants.AddressZero)
            ).to.be.revertedWith("Factory__InvalidAddress")
        })
    })

    describe("setGovernance", () => {
        beforeEach(async () => {
            const Collectible1155Factory = await ethers.getContractFactory(
                "Collectible1155",
                manager
            )

            collectible1155 = await Collectible1155Factory.deploy(
                manager.address
            )
            await collectible1155.deployed()
            const NFTFactory1155Factory = await ethers.getContractFactory(
                "NFTFactory1155",
                manager
            )
            nftFactory1155 = await NFTFactory1155Factory.deploy(
                governance.address
            )
            await nftFactory1155.deployed()
        })

        it("set new governance address successfully when all the modifier is passed", async () => {
            const privateKey = "0x" + crypto.randomBytes(32).toString("hex")
            const newGovernance = new ethers.Wallet(privateKey)
            await nftFactory1155.setGovernance(newGovernance.address)
            expect((await nftFactory1155.governance()).toString()).to.equal(
                newGovernance.address
            )
        })

        it("should revert when new governance address is invalid", async () => {
            await expect(
                nftFactory1155.setGovernance(ethers.constants.AddressZero)
            ).to.be.revertedWith("Factory__InvalidAddress")
        })

        it("should revert when the address calling the function is not the owner address", async () => {
            const privateKey = "0x" + crypto.randomBytes(32).toString("hex")
            const newGovernance = new ethers.Wallet(privateKey)
            await expect(
                nftFactory1155
                    .connect(users[0])
                    .setGovernance(newGovernance.address)
            ).to.be.revertedWith("Factory__Unauthorized")
        })
    })

    describe("deployCollectibe1155", () => {
        beforeEach(async () => {
            const Collectible1155Factory = await ethers.getContractFactory(
                "Collectible1155",
                manager
            )

            collectible1155 = await Collectible1155Factory.deploy(
                manager.address
            )
            await collectible1155.deployed()
            const NFTFactory1155Factory = await ethers.getContractFactory(
                "NFTFactory1155",
                manager
            )
            nftFactory1155 = await NFTFactory1155Factory.deploy(
                governance.address
            )
            await nftFactory1155.deployed()
        })

        it("Create new collectibe1155 contract as a clone of the implement", async () => {
            await nftFactory1155.deployCollectible1155(
                collectible1155.address,
                "TriCoin",
                "TC",
                ""
            )
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory1155_v1")
            )

            const salt = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ["bytes32", "string", "string", "string"],
                    [version, "TriCoin", "TC", ""]
                )
            )

            const newNftAddress = await nftFactory1155.deployedContracts(
                BigNumber.from(salt)
            )

            const newCollectible1155 = await ethers.getContractAt(
                "Collectible1155",
                newNftAddress
            )
            console.log(`new collectible1155 address: ${newNftAddress}`)
            expect(await newCollectible1155.name()).to.equal("TriCoin")
            expect(await newCollectible1155.symbol()).to.equal("TC")
        })

        it("should emit an TokenDeployed event when deploy successfully", async () => {
            await expect(
                nftFactory1155.deployCollectible1155(
                    collectible1155.address,
                    "Apollo",
                    "AP",
                    ""
                )
            ).to.emit(nftFactory1155, "TokenDeployed")
        })
    })
})
