import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {expect} from "chai"
import {ethers} from "hardhat"
import {BigNumber} from "ethers"
import {
    Collectible1155,
    Governance,
    NFTFactory1155,
    TokenId,
} from "../typechain"

describe("Collectible1155", () => {
    let manager: SignerWithAddress
    let verifier: SignerWithAddress
    let treasury: SignerWithAddress
    let users: SignerWithAddress[]

    let nftFactory1155: NFTFactory1155
    let collectible1155Base: Collectible1155
    let Collectible1155: Collectible1155
    beforeEach(async () => {
        ;[manager, verifier, treasury, ...users] = await ethers.getSigners()
        // deploy nftfactory721
        const NFTFactory1155 = await ethers.getContractFactory(
            "NFTFactory1155",
            manager
        )
        nftFactory1155 = await NFTFactory1155.deploy(manager.address)
        await nftFactory1155.deployed()
        const Collectible1155BaseFactory = await ethers.getContractFactory(
            "Collectible1155",
            manager
        )
        collectible1155Base = await Collectible1155BaseFactory.deploy(
            manager.address
        )
        await collectible1155Base.deployed()
    })

    describe("constructor, initialize", () => {
        it.only("should deploy a clone of Collectible1155 contract and initialzie", async () => {
            const name = "HoangCoin"
            const symbol = "HLC"
            const URI = ""
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory1155_v1")
            )
            await nftFactory1155
                .connect(users[0])
                .deployCollectible1155(
                    collectible1155Base.address,
                    name,
                    symbol,
                    URI
                )
            const salt = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ["bytes32", "string", "string", "string"],
                    [version, name, symbol, URI]
                )
            )
            const new1555ContractAddress =
                await nftFactory1155.deployedContracts(BigNumber.from(salt))
            const new1155Contract = await ethers.getContractAt(
                "Collectible1155",
                new1555ContractAddress
            )

            expect(await new1155Contract.name()).to.equal("HoangCoin")
            expect(await new1155Contract.symbol()).to.equal("HLC")
            expect(
                await new1155Contract.hasRole(
                    ethers.utils.keccak256(
                        ethers.utils.toUtf8Bytes("MINTER_ROLE")
                    ),
                    users[0].address
                )
            ).to.true
            expect(
                await new1155Contract.hasRole(
                    ethers.utils.keccak256(
                        ethers.utils.toUtf8Bytes("URI_SETTER_ROLE")
                    ),
                    users[0].address
                )
            ).to.true
        })

        it("")
    })
})
