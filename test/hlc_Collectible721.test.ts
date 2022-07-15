import {ethers} from "hardhat"
import {expect} from "chai"
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {
    Governance,
    NFTFactory721,
    TokenId,
    Collectible721,
    TokenIdGenerator,
    ERC721,
} from "../typechain"
import {BigNumber} from "ethers"

describe("Collectible721", () => {
    let manager: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let users: SignerWithAddress[]

    let governance: Governance
    let nftFactory721: NFTFactory721
    let collectible721: Collectible721
    let tokenIdGenerator: TokenId
    beforeEach(async () => {
        ;[manager, treasury, verifier, ...users] = await ethers.getSigners()
        // deploy nftfactory721
        const NFTFactory721 = await ethers.getContractFactory(
            "NFTFactory721",
            manager
        )
        nftFactory721 = await NFTFactory721.deploy(manager.address)
        await nftFactory721.deployed()

        const TokenIdFactory = await ethers.getContractFactory(
            "TokenId",
            manager
        )
        tokenIdGenerator = await TokenIdFactory.deploy()
        await tokenIdGenerator.deployed()
    })
    describe("constructor", () => {
        let newNftContract: Collectible721
        const version = ethers.utils.keccak256(
            ethers.utils.toUtf8Bytes("NFTFactory721_v1")
        )
        let name, symbol, URI

        it("users[0] create nft successfully", async () => {
            name = "HoangCoin"
            symbol = "HLC"
            URI = ""
            await nftFactory721
                .connect(users[0])
                .deployCollectible721(name, symbol, URI)
            const salt = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ["bytes32", "string", "string", "string"],
                    [version, name, symbol, URI]
                )
            )
            const newNftContractAddress = await nftFactory721.deployedContracts(
                BigNumber.from(salt)
            )
            newNftContract = await ethers.getContractAt(
                "Collectible721",
                newNftContractAddress
            )
            expect(await newNftContract.name()).to.equal("HoangCoin")
            expect(await newNftContract.symbol()).to.equal("HLC")
            expect(await newNftContract.baseURI()).to.equal("")
            const MINTER_ROLE = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("MINTER_ROLE")
            )
            const URI_SETTER_ROLE = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("URI_SETTER_ROLE")
            )
            expect(await newNftContract.hasRole(MINTER_ROLE, users[0].address))
                .to.true
            expect(
                await newNftContract.hasRole(URI_SETTER_ROLE, users[0].address)
            ).to.true
            expect(await newNftContract.admin()).to.equal(manager.address)
        })

        // it("should revert when nft names is longer than 32 bytes", async () => {
        //     name = "012345678901234567890123456789012"
        //     symbol = "HLC"
        //     URI = ""
        //     await expect(
        //         nftFactory721
        //             .connect(users[0])
        //             .deployCollectible721(name, symbol, URI)
        //     ).to.be.revertedWith("NFT__StringTooLong")
        // })
    })

    describe("mint", () => {
        let newNftContract: Collectible721
        beforeEach(async () => {
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory721_v1")
            )
            const name = "HoangCoin"
            const symbol = "HLC"
            const URI = "https://"
            await nftFactory721
                .connect(users[0])
                .deployCollectible721(name, symbol, URI)
            const salt = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ["bytes32", "string", "string", "string"],
                    [version, name, symbol, URI]
                )
            )
            const newNftContractAddress = await nftFactory721.deployedContracts(
                BigNumber.from(salt)
            )
            newNftContract = await ethers.getContractAt(
                "Collectible721",
                newNftContractAddress
            )
        })

        it("mint a token and transfer to the owner", async () => {
            const token1 = {
                _fee: 1,
                _type: 721,
                _supply: 1,
                _index: 1,
                _creator: users[0].address,
            }

            const tokenId1 = await tokenIdGenerator.createTokenId(token1)
            expect(
                await newNftContract
                    .connect(users[0])
                    .mint(users[0].address, tokenId1, "1", "")
            ).to.emit("ERC721", "Transfer")

            expect(await newNftContract.balanceOf(users[0].address)).to.equal(1)
            expect(await newNftContract.ownerOf(tokenId1)).to.equal(
                users[0].address
            )
        })

        it("revert when amount of token minted is larger than 1", async () => {
            const token1 = {
                _fee: 1,
                _type: 721,
                _supply: 1,
                _index: 1,
                _creator: users[0].address,
            }

            const tokenId1 = await tokenIdGenerator.createTokenId(token1)
            await expect(
                newNftContract
                    .connect(users[0])
                    .mint(users[0].address, tokenId1, 2, "")
            ).to.be.revertedWith("NFT__InvalidInput")
        })

        it("revert when the address calling the mint function don't have minter role", async () => {
            const token1 = {
                _fee: 1,
                _type: 721,
                _supply: 1,
                _index: 1,
                _creator: users[0].address,
            }

            const tokenId1 = await tokenIdGenerator.createTokenId(token1)
            await expect(
                newNftContract
                    .connect(users[1])
                    .mint(users[1].address, tokenId1, 1, "")
            ).to.be.revertedWith(
                `AccessControl: account ${users[1].address.toLowerCase()} is missing role ${ethers.utils.keccak256(
                    ethers.utils.toUtf8Bytes("MINTER_ROLE")
                )}`
            )
        })

        it("revert when the token is already exist", async () => {
            const token1 = {
                _fee: 1,
                _type: 721,
                _supply: 1,
                _index: 1,
                _creator: users[0].address,
            }

            const tokenId1 = await tokenIdGenerator.createTokenId(token1)

            await newNftContract
                .connect(users[0])
                .mint(users[0].address, tokenId1, 1, "")

            await expect(
                newNftContract
                    .connect(users[0])
                    .mint(users[0].address, tokenId1, 1, "")
            ).to.be.revertedWith("NFT__TokenExisted")
        })
    })
})
