import {expect} from "chai"
import {ethers} from "hardhat"
import * as crypto from "crypto"
import {Collectible721, Governance, NFTFactory721} from "../typechain"
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {BigNumber} from "ethers"

describe("NFTFactory721", () => {
    let manager: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let users: SignerWithAddress[]
    let governance: Governance
    let nftFactory721: NFTFactory721
    let collectible721: Collectible721

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
    })

    describe("constructor", () => {
        it("should initialize the governace address", async () => {
            const NFTFactory721Factory = await ethers.getContractFactory(
                "NFTFactory721",
                manager
            )
            nftFactory721 = await NFTFactory721Factory.deploy(
                governance.address
            )
            await nftFactory721.deployed()
            const governanceAddress = await nftFactory721.governance()
            expect(governanceAddress).to.equal(governance.address)
        })

        it("should revert when governance address is invalid", async () => {
            const NFTFactory721Factory = await ethers.getContractFactory(
                "NFTFactory721",
                manager
            )
            await expect(
                NFTFactory721Factory.deploy(ethers.constants.AddressZero)
            ).to.be.revertedWith("Factory__InvalidAddress")
        })
    })

    describe("setGovernance", () => {
        beforeEach(async () => {
            const NFTFactory721Factory = await ethers.getContractFactory(
                "NFTFactory721",
                manager
            )
            nftFactory721 = await NFTFactory721Factory.deploy(
                governance.address
            )
            await nftFactory721.deployed()
        })

        it("set new governance address successfully when all the modifier is passed", async () => {
            const privateKey = "0x" + crypto.randomBytes(32).toString("hex")
            const newGovernance = new ethers.Wallet(privateKey)
            await nftFactory721.setGovernance(newGovernance.address)
            expect((await nftFactory721.governance()).toString()).to.equal(
                newGovernance.address
            )
        })

        it("should revert when new governance address is invalid", async () => {
            await expect(
                nftFactory721.setGovernance(ethers.constants.AddressZero)
            ).to.be.revertedWith("Factory__InvalidAddress")
        })

        it("should revert when the address calling the function is not the owner address", async () => {
            const privateKey = "0x" + crypto.randomBytes(32).toString("hex")
            const newGovernance = new ethers.Wallet(privateKey)
            await expect(
                nftFactory721
                    .connect(users[0])
                    .setGovernance(newGovernance.address)
            ).to.be.revertedWith("Factory__Unauthorized")
        })
    })

    describe("deployCollectible721", () => {
        beforeEach(async () => {
            const NFTFactory721Factory = await ethers.getContractFactory(
                "NFTFactory721",
                manager
            )
            nftFactory721 = await NFTFactory721Factory.deploy(
                governance.address
            )
            await nftFactory721.deployed()
        })

        it("Create new collectible721 successfully when all the modifier is passed", async () => {
            await nftFactory721.deployCollectible721("HoangCoin", "HLC", "")
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory721_v1")
            )

            const salt = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ["bytes32", "string", "string", "string"],
                    [version, "HoangCoin", "HLC", ""]
                )
            )

            const newNftAddress = await nftFactory721.deployedContracts(
                BigNumber.from(salt)
            )

            const newCollectible721 = await ethers.getContractAt(
                "Collectible721",
                newNftAddress
            )
            console.log(`new collectible721 address: ${newNftAddress}`)
            expect(await newCollectible721.name()).to.equal("HoangCoin")
            expect(await newCollectible721.symbol()).to.equal("HLC")
        })

        it("should emit an TokenDeployed event when deploy successfully", async () => {
            await expect(
                nftFactory721.deployCollectible721("Apollo", "AP", "")
            ).to.emit(nftFactory721, "TokenDeployed")
        })
    })
})
