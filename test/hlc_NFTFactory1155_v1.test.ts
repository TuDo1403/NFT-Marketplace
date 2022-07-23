import {expect} from "chai"
import {ethers, upgrades} from "hardhat"
import * as crypto from "crypto"
import {Collectible1155, Governance, NFTFactory} from "../typechain-types"
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {BigNumber} from "ethers"

describe("NFTFactory1155", () => {
    let admin: SignerWithAddress
    // let manager: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let users: SignerWithAddress[]

    let governance: Governance
    let nftFactory: NFTFactory
    let collectible1155Base: Collectible1155

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

        const Collectible1155Factory = await ethers.getContractFactory(
            "Collectible1155",
            admin
        )
        collectible1155Base = await Collectible1155Factory.deploy()
        await collectible1155Base.deployed()
    })

    describe("constructor", () => {
        it("should initialize the governance address", async () => {
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
            // await expect(
            //     nftFactory.initialize(ethers.constants.AddressZero)
            // ).to.be.revertedWith("MPI__NonZeroAddress")
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

    describe("deployCollectibe1155", () => {
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

        it("Create new collectibe1155 contract as a clone of the implement", async () => {
            await nftFactory
                .connect(users[0])
                .deployCollectible(
                    collectible1155Base.address,
                    "TriCoin",
                    "TC",
                    ""
                )
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory_v1")
            )

            const salt = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ["bytes32", "string", "string", "string"],
                    [version, "TriCoin", "TC", ""]
                )
            )

            const newNftAddress = await nftFactory.deployedContracts(
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
                nftFactory.deployCollectible(
                    collectible1155Base.address,
                    "Apollo",
                    "AP",
                    ""
                )
            ).to.emit(nftFactory, "TokenDeployed")
        })
    })
})
