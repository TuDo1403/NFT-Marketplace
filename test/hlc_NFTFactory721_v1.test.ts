import {expect} from "chai"
import {ethers, upgrades} from "hardhat"
import * as crypto from "crypto"
import {Collectible721, Governance, NFTFactory} from "../typechain-types"
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {BigNumber} from "ethers"

describe("NFTFactory721", () => {
    let admin: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let users: SignerWithAddress[]
    let governance: Governance
    let nftFactory: NFTFactory
    let collectible721Base: Collectible721

    beforeEach(async () => {
        ;[admin, treasury, verifier, ...users] = await ethers.getSigners()
        const GovernanceFactory = await ethers.getContractFactory(
            "Governance",
            admin
        )
        governance = await GovernanceFactory.deploy(
            treasury.address,
            verifier.address
        )
        await governance.deployed()

        const Collectible721Factory = await ethers.getContractFactory(
            "Collectible721",
            admin
        )

        collectible721Base = await Collectible721Factory.deploy()
        await collectible721Base.deployed()
    })

    describe("constructor", () => {
        it("should initialize the governace address", async () => {
            const NFTFactoryFactory = await ethers.getContractFactory(
                "NFTFactory",
                admin
            )
            nftFactory = (await upgrades.deployProxy(
                NFTFactoryFactory,
                [governance.address],
                {initializer: "initialize"}
            )) as NFTFactory
            await nftFactory.deployed()
            const governanceAddress = await nftFactory.admin()
            expect(governanceAddress).to.equal(governance.address)
        })

        it("should revert when governance address is invalid", async () => {
            const NFTFactoryFactory = await ethers.getContractFactory(
                "NFTFactory",
                admin
            )
            expect(
                upgrades.deployProxy(NFTFactoryFactory, [governance.address], {
                    initializer: "initialize",
                })
            ).to.be.revertedWith("MPI__NonZeroAddress")
        })
    })

    describe("setGovernance", () => {
        beforeEach(async () => {
            const NFTFactoryFactory = await ethers.getContractFactory(
                "NFTFactory",
                admin
            )
            nftFactory = (await upgrades.deployProxy(
                NFTFactoryFactory,
                [governance.address],
                {initializer: "initialize"}
            )) as NFTFactory
            await nftFactory.deployed()
        })

        it("set new governance address successfully when all the modifier is passed", async () => {
            const privateKey = "0x" + crypto.randomBytes(32).toString("hex")
            const newGovernance = new ethers.Wallet(privateKey)
            await nftFactory.updateGovernance(newGovernance.address)
            expect((await nftFactory.admin()).toString()).to.equal(
                newGovernance.address
            )
        })

        it("should revert when new governance address is invalid", async () => {
            await expect(
                nftFactory.updateGovernance(ethers.constants.AddressZero)
            ).to.be.revertedWith("MPI__NonZeroAddress")
        })

        it("should revert when the address calling the function is not the owner address", async () => {
            const privateKey = "0x" + crypto.randomBytes(32).toString("hex")
            const newGovernance = new ethers.Wallet(privateKey)
            await expect(
                nftFactory
                    .connect(users[0])
                    .updateGovernance(newGovernance.address)
            ).to.be.revertedWith("MPI__Unauthorized")
        })
    })

    describe("deployCollectible721", () => {
        beforeEach(async () => {
            const NFTFactoryFactory = await ethers.getContractFactory(
                "NFTFactory",
                admin
            )
            nftFactory = (await upgrades.deployProxy(
                NFTFactoryFactory,
                [governance.address],
                {initializer: "initialize"}
            )) as NFTFactory
            await nftFactory.deployed()
        })

        it("Create new collectible721 successfully when all the modifier is passed", async () => {
            await nftFactory.deployCollectible(
                collectible721Base.address,
                "HoangCoin",
                "HLC",
                ""
            )
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory_v1")
            )

            const salt = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ["bytes32", "string", "string", "string"],
                    [version, "HoangCoin", "HLC", ""]
                )
            )

            const clone721Address = await nftFactory.deployedContracts(
                BigNumber.from(salt)
            )

            const clone721Contract = await ethers.getContractAt(
                "Collectible721",
                clone721Address
            )
            console.log(`new collectible721 address: ${clone721Address}`)
            console.log(await clone721Contract.name())
            console.log(await clone721Contract.symbol())
            expect(await clone721Contract.name()).to.equal("HoangCoin")
            expect(await clone721Contract.symbol()).to.equal("HLC")
        })

        it("should emit an TokenDeployed event when deploy successfully", async () => {
            await expect(
                nftFactory.deployCollectible(
                    collectible721Base.address,
                    "Apollo",
                    "AP",
                    ""
                )
            ).to.emit(nftFactory, "TokenDeployed")
        })
    })
})
