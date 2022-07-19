import {ethers} from "hardhat"
import {expect} from "chai"
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {
    Governance,
    NFTFactory721,
    Collectible721,
    TokenCreator,
    ERC721,
} from "../typechain"
import {BigNumber} from "ethers"

describe("Collectible721", () => {
    let admin: SignerWithAddress
    let manager: SignerWithAddress
    let treasury: SignerWithAddress
    let verifier: SignerWithAddress
    let users: SignerWithAddress[]

    let governance: Governance
    let nftFactory721: NFTFactory721
    let collectible721: Collectible721
    let tokenIdGenerator: TokenCreator
    beforeEach(async () => {
        ;[admin, manager, treasury, verifier, ...users] =
            await ethers.getSigners()
        // deploy nftfactory721
        const GovernanceFactory = await ethers.getContractFactory(
            "Governance",
            admin
        )
        governance = await GovernanceFactory.deploy(
            manager.address,
            treasury.address,
            verifier.address
        )
        await governance.deployed()
        const NFTFactory721 = await ethers.getContractFactory(
            "NFTFactory721",
            admin
        )
        nftFactory721 = await NFTFactory721.deploy(governance.address)
        await nftFactory721.deployed()

        const TokenIdFactory = await ethers.getContractFactory(
            "TokenCreator",
            admin
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

        it("users[0] deploy nft successfully", async () => {
            name = "HoangCoin"
            symbol = "HLC"
            URI = ""
            await nftFactory721
                .connect(users[0])
                .deployCollectible(name, symbol, URI)
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
            // const DEFAULT_ADMIN_ROLE =
            //     ethers.utils.toUtf8Bytes("0x00")
            // )
            expect(await newNftContract.hasRole(MINTER_ROLE, users[0].address))
                .to.true
            // expect(
            //     await newNftContract.hasRole(
            //         ethers.utils.toUtf8Bytes("0x00"),
            //         users[0].address
            //     )
            // ).to.true
            expect(await newNftContract.admin()).to.equal(governance.address)
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
                .deployCollectible(name, symbol, URI)
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

        it.only("mint a token and transfer to the owner", async () => {
            const token1 = {
                _fee: 1,
                _type: 721,
                _supply: 1,
                _index: 1,
                _creator: users[0].address,
            }

            const tokenId1 = await tokenIdGenerator.createTokenId(
                token1._fee,
                token1._type,
                token1._supply,
                token1._index,
                token1._creator
            )
            expect(
                await newNftContract.connect(users[0]).mint(users[0].address, {
                    amount: token1._supply,
                    tokenId: tokenId1,
                    unitPrice: 500,
                    tokenURI: "",
                })
            ).to.emit("ERC721Lite", "Transfer")

            expect(await newNftContract.balanceOf(users[0].address)).to.equal(1)
            expect(await newNftContract.ownerOf(tokenId1)).to.equal(
                users[0].address
            )
        })

        it("revert when amount of token minted is larger than 1", async () => {
            const token1 = {
                _fee: 1,
                _type: 721,
                _supply: 2,
                _index: 1,
                _creator: users[0].address,
            }

            const tokenId1 = await tokenIdGenerator.createTokenId(
                token1._fee,
                token1._type,
                token1._supply,
                token1._index,
                token1._creator
            )
            await expect(
                newNftContract.connect(users[0]).mint(users[0].address, {
                    amount: token1._supply,
                    tokenId: tokenId1,
                    unitPrice: 500,
                    tokenURI: "",
                })
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

            const tokenId1 = await tokenIdGenerator.createTokenId(
                token1._fee,
                token1._type,
                token1._supply,
                token1._index,
                token1._creator
            )
            await expect(
                newNftContract.connect(users[1]).mint(users[1].address, {
                    amount: token1._supply,
                    tokenId: tokenId1,
                    unitPrice: 500,
                    tokenURI: "",
                })
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

            const tokenId1 = await tokenIdGenerator.createTokenId(
                token1._fee,
                token1._type,
                token1._supply,
                token1._index,
                token1._creator
            )

            await newNftContract.connect(users[0]).mint(users[0].address, {
                amount: token1._supply,
                tokenId: tokenId1,
                unitPrice: 500,
                tokenURI: "",
            })

            await expect(
                newNftContract.connect(users[0]).mint(users[0].address, {
                    amount: token1._supply,
                    tokenId: tokenId1,
                    unitPrice: 500,
                    tokenURI: "",
                })
            ).to.be.revertedWith("ERC721__TokenExisted")
        })
    })
})
