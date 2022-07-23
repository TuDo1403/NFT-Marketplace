import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {expect} from "chai"
import {ethers} from "hardhat"
import {Governance} from "../typechain-types"

describe("Governance", () => {
    let manager: SignerWithAddress
    let newManager: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let marketplace: SignerWithAddress
    let users: SignerWithAddress[]

    let governance: Governance

    it("Deploy governance contract", async () => {
        // 1. Assign signers
        ;[manager, newManager, treasury, verifier, marketplace, ...users] =
            await ethers.getSigners()

        // 2. Setup, just call the name of your contract (contract name), not the file name.
        const FactoryContract = await ethers.getContractFactory("Governance")

        // 3. Deploy our contract using deploy and deployed function from nomiclabs/hardhat-ethers
        governance = await FactoryContract.connect(manager).deploy(
            manager.address,
            treasury.address,
            verifier.address
        )
        await governance.deployed()
        expect(await governance.manager()).to.equal(manager.address)
    })

    it("Update treasury address by owner", async () => {
        // 4. Call our functions to test, signer is owner
        // 2. Setup, just call the name of your contract (contract name), not the file name.
        const OurContract = await ethers.getContractFactory("Governance")

        // 3. Deploy our contract using deploy and deployed function from nomiclabs/hardhat-ethers
        governance = await OurContract.connect(manager).deploy(
            manager.address,
            treasury.address,
            verifier.address
        )
        let newTreasuryAddr = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        await governance.connect(manager).updateTreasury(newTreasuryAddr)
        expect(await governance.treasury()).to.equal(newTreasuryAddr)
    })

    it("Update verifier address by owner", async () => {
        let newVerifierAddr = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
        await governance.connect(manager).updateVerifier(newVerifierAddr)
        expect(await governance.verifier()).to.equal(newVerifierAddr)
    })

    it("Update manager address by owner", async () => {
        await governance.connect(manager).updateManager(newManager.address)
        expect(await governance.manager()).to.equal(newManager.address)
        newManager = await ethers.getSigner(newManager.address)
    })

    it("Add payment token", async () => {
        const USDTAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
        await governance.connect(newManager).registerToken(USDTAddress)
        expect(await governance.acceptedPayments(USDTAddress)).to.equal(true)
    })

    it("Remove payment token", async () => {
        const USDTAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
        await governance.connect(newManager).unregisterToken(USDTAddress)
        expect(await governance.acceptedPayments(USDTAddress)).to.equal(false)
    })
})
