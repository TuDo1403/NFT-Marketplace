import {expect} from "chai"
import {ethers} from "hardhat"
import {Governance} from "../typechain"
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {BigNumber} from "ethers"

const GLMR = "0x017bE64db48dfc962221c984b9A6937A5d09E81A"

describe("Governance", () => {
    let manager: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let marketplace: SignerWithAddress
    let users: SignerWithAddress[]
    let governance: Governance
    beforeEach(async () => {
        ;[manager, treasury, verifier, marketplace, ...users] =
            await ethers.getSigners()
    })

    describe("constructor", () => {
        it("should initialize manager, treasury, verifier when all modifier is passed", async () => {
            const GovernanceFactory = await ethers.getContractFactory(
                "Governance",
                manager
            )
            const governance = await GovernanceFactory.deploy(
                manager.address,
                treasury.address,
                verifier.address
            )
            await governance.deployed()
            expect(await governance.manager()).to.equal(manager.address)
            expect(await governance.treasury()).to.equal(treasury.address)
            expect(await governance.verifier()).to.equal(verifier.address)
        })
        it("should revert when manager address is invalid", async () => {
            const GovernanceFactory = await ethers.getContractFactory(
                "Governance",
                manager
            )
            await expect(
                GovernanceFactory.deploy(
                    ethers.constants.AddressZero,
                    treasury.address,
                    verifier.address
                )
            ).to.be.revertedWith("Governance__InvalidAddress")
        })

        it("should revert when treasury address is invalid", async () => {
            const GovernanceFactory = await ethers.getContractFactory(
                "Governance",
                manager
            )
            await expect(
                GovernanceFactory.deploy(
                    manager.address,
                    ethers.constants.AddressZero,
                    verifier.address
                )
            ).to.be.revertedWith("Governance__InvalidAddress")
        })

        it("should revert when verifier address is invalid", async () => {
            const GovernanceFactory = await ethers.getContractFactory(
                "Governance",
                manager
            )
            await expect(
                GovernanceFactory.deploy(
                    manager.address,
                    treasury.address,
                    ethers.constants.AddressZero
                )
            ).to.be.revertedWith("Governance__InvalidAddress")
        })
    })

    describe("updateTreasury", () => {
        beforeEach(async () => {
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

        it("update treasury address", async () => {
            await governance.updateTreasury(users[0].address)
            expect(await governance.treasury()).to.equal(users[0].address)
        })

        it("should revert when the address calling the function is not owner of the contract", async () => {
            await expect(
                governance.connect(users[1]).updateTreasury(users[0].address)
            ).to.be.revertedWith("Governance__Unauthorized")
        })

        it("should revert when new treasury address is invalid", async () => {
            await expect(
                governance.updateTreasury(ethers.constants.AddressZero)
            ).to.be.revertedWith("Governance__InvalidAddress")
        })

        it("should emit an event when update successfully", async () => {
            await expect(governance.updateTreasury(users[0].address)).to.emit(
                governance,
                "TreasuryUpdated"
            )
        })
    })

    describe("updateVerifier", () => {
        beforeEach(async () => {
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

        it("update verifier address", async () => {
            await governance.updateVerifier(users[0].address)
            expect(await governance.verifier()).to.equal(users[0].address)
        })

        it("should revert when the address calling the function is not owner of the contract", async () => {
            await expect(
                governance.connect(users[1]).updateVerifier(users[0].address)
            ).to.be.revertedWith("Governance__Unauthorized")
        })

        it("should revert when new verifier address is invalid", async () => {
            await expect(
                governance.updateVerifier(ethers.constants.AddressZero)
            ).to.be.revertedWith("Governance__InvalidAddress")
        })
    })

    describe("updateManager", () => {
        beforeEach(async () => {
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

        it("update manager address", async () => {
            await governance.updateManager(users[0].address)
            expect(await governance.manager()).to.equal(users[0].address)
        })

        it("should revert when the address calling the function is not owner of the contract", async () => {
            await expect(
                governance.connect(users[1]).updateManager(users[0].address)
            ).to.be.revertedWith("Governance__Unauthorized")
        })

        it("should revert when new manager address is invalid", async () => {
            await expect(
                governance.updateManager(ethers.constants.AddressZero)
            ).to.be.revertedWith("Governance__InvalidAddress")
        })
    })

    describe("updateMarketplace", () => {
        beforeEach(async () => {
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

        it("update marketplace address", async () => {
            await governance.updateMarketplace(users[0].address)
            expect(await governance.marketplace()).to.equal(users[0].address)
        })

        it("should revert when the address calling the function is not owner of the contract", async () => {
            await expect(
                governance.connect(users[1]).updateMarketplace(users[0].address)
            ).to.be.revertedWith("Governance__Unauthorized")
        })

        it("should revert when new marketplace address is invalid", async () => {
            await expect(
                governance.updateMarketplace(ethers.constants.AddressZero)
            ).to.be.revertedWith("Governance__InvalidAddress")
        })
    })

    describe("registerToken", () => {
        beforeEach(async () => {
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

        it("register new token successfully", async () => {
            await governance.registerToken(GLMR)
            expect(await governance.acceptedPayments(GLMR)).to.true
        })

        it("should emit an event when register succesffully", async () => {
            await expect(governance.registerToken(GLMR)).to.emit(
                governance,
                "PaymentUpdated"
            )
        })

        it("should revert when the address calling the function is not owner of the contract", async () => {
            await expect(
                governance.connect(users[1]).registerToken(GLMR)
            ).to.be.revertedWith("Governance__Unauthorized")
        })

        it("should revert when new token address is invalid", async () => {
            await expect(
                governance.registerToken(ethers.constants.AddressZero)
            ).to.be.revertedWith("Governance__InvalidAddress")
        })
    })

    describe("unregisterToken", () => {
        beforeEach(async () => {
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

        it("unregister successfully", async () => {
            await governance.registerToken(GLMR)
            await governance.unregisterToken(GLMR)
            expect(await governance.acceptedPayments(GLMR)).to.false
        })

        it("revert when unregister non accepted token", async () => {
            await expect(governance.unregisterToken(GLMR)).to.be.revertedWith(
                "Governance__UnregisteredToken"
            )
        })

        it("should revert when the address calling the function is not owner of the contract", async () => {
            await expect(
                governance.connect(users[0]).unregisterToken(GLMR)
            ).to.be.revertedWith("Governance__Unauthorized")
        })
    })
})
