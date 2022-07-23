import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {expect, use} from "chai"
import {BigNumber} from "ethers"
import {ethers} from "hardhat"
import {Collectible721, Governance, NFTFactory721, TokenId} from "../typechain-types"

describe("Collectible721", () => {
    let governance: Governance
    let nftFactory721: NFTFactory721
    let collectible721: Collectible721

    let manager: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let users: SignerWithAddress[]

    let myCollectible721: Collectible721
    let tokenIdGenerator: TokenId

    before(async () => {
        ;[manager, treasury, verifier, ...users] = await ethers.getSigners()

        const GovernanceContract = await ethers.getContractFactory(
            "Governance",
            manager
        )
        governance = await GovernanceContract.deploy(
            manager.address,
            treasury.address,
            verifier.address
        )
        await governance.deployed()

        const NFTFactory721Contract = await ethers.getContractFactory(
            "NFTFactory721",
            manager
        )
        nftFactory721 = await NFTFactory721Contract.deploy(governance.address)
        await nftFactory721.deployed()

        const TokenIdGeneratorContract = await ethers.getContractFactory(
            "TokenId",
            manager
        )
        tokenIdGenerator = await TokenIdGeneratorContract.deploy()
        await tokenIdGenerator.deployed()
    })

    it("Create new collectible721", async () => {
        let newTokenName = "DEMOERC721"
        let newSymbol = "DERC"
        let newBaseUri = ""

        await nftFactory721.deployCollectible721(
            newTokenName,
            newSymbol,
            newBaseUri
        )

        const version = ethers.utils.keccak256(
            ethers.utils.toUtf8Bytes("NFTFactory721_v1")
        )
        let salt = ethers.utils.keccak256(
            ethers.utils.solidityPack(
                ["bytes", "string", "string", "string"],
                [version, newTokenName, newSymbol, newBaseUri]
            )
        )

        let deployedAddr = await nftFactory721
            .connect(manager)
            .deployedContracts(BigNumber.from(salt))
        myCollectible721 = await ethers.getContractAt(
            "Collectible721",
            deployedAddr
        )

        expect(await myCollectible721.name()).to.equal(newTokenName)
    })

    it("Test collection721 functions", async () => {
        let newTokenName = "DEMOERC721_2"
        let newSymbol = "DERC2"
        let newBaseUri = ""

        await nftFactory721.deployCollectible721(
            newTokenName,
            newSymbol,
            newBaseUri
        )

        const version = ethers.utils.keccak256(
            ethers.utils.toUtf8Bytes("NFTFactory721_v1")
        )
        let salt = ethers.utils.keccak256(
            ethers.utils.solidityPack(
                ["bytes", "string", "string", "string"],
                [version, newTokenName, newSymbol, newBaseUri]
            )
        )

        let deployedAddr = await nftFactory721
            .connect(manager)
            .deployedContracts(BigNumber.from(salt))
        myCollectible721 = await ethers.getContractAt(
            "Collectible721",
            deployedAddr
        )

        let tokenInfo = {
            _fee: 1,
            _type: 721,
            _supply: 1,
            _index: 1,
            _creator: users[0].address,
        }
        let tokenId1 = await tokenIdGenerator.createTokenId(tokenInfo)
        await myCollectible721
            .connect(manager)
            .mint(users[0].address, tokenId1, 1, "")

        tokenInfo = {
            _fee: 1,
            _type: 721,
            _supply: 1,
            _index: 2,
            _creator: users[1].address,
        }
        let tokenId2 = await tokenIdGenerator.createTokenId(tokenInfo)
        await myCollectible721
            .connect(manager)
            .mint(users[1].address, tokenId2, 1, "")

        await myCollectible721
            .connect(users[0])
            .transferFrom(users[0].address, users[1].address, tokenId1)

        expect(await myCollectible721.balanceOf(users[1].address)).to.equal(2)
    })
})
