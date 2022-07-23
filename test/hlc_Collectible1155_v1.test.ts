import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {expect} from "chai"
import {ethers, upgrades} from "hardhat"
import {BigNumber} from "ethers"
import {
    Collectible1155,
    Governance,
    NFTFactory,
    TokenCreator,
} from "../typechain-types"

describe("Collectible1155", () => {
    let admin: SignerWithAddress
    let verifier: SignerWithAddress
    let treasury: SignerWithAddress
    let users: SignerWithAddress[]

    let nftFactory: NFTFactory
    let collectible1155Base: Collectible1155
    let tokenCreator: TokenCreator
    let governance: Governance
    beforeEach(async () => {
        ;[admin, verifier, treasury, ...users] = await ethers.getSigners()
        const GovernanceFactory = await ethers.getContractFactory(
            "Governance",
            admin
        )
        governance = await GovernanceFactory.deploy(
            treasury.address,
            verifier.address
        )
        await governance.deployed()

        const Collectible1155BaseFactory = await ethers.getContractFactory(
            "Collectible1155",
            admin
        )
        collectible1155Base = await Collectible1155BaseFactory.deploy()
        await collectible1155Base.deployed()

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

        const TokenCreatorFactory = await ethers.getContractFactory(
            "TokenCreator"
        )
        tokenCreator = await TokenCreatorFactory.deploy()
        await tokenCreator.deployed()
    })

    describe("constructor", () => {
        it("should deploy a clone of Collectible1155 contract and initialzie", async () => {
            const name = "HoangCoin"
            const symbol = "HLC"
            const URI = ""
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory_v1")
            )
            await nftFactory
                .connect(users[0])
                .deployCollectible(
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
            const new1555ContractAddress = await nftFactory.deployedContracts(
                BigNumber.from(salt)
            )
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

        it("should revert when the name or the symbol is longer than 32 bytes", async () => {
            const name = "012345678901234567890123456789012"
            const symbol = "HLC"
            const URI = ""

            await expect(
                nftFactory
                    .connect(users[0])
                    .deployCollectible(
                        collectible1155Base.address,
                        name,
                        symbol,
                        URI
                    )
            ).to.be.revertedWith("NFT__StringTooLong")
        })
    })

    describe("mint", () => {
        let new1155Contract: Collectible1155
        beforeEach(async () => {
            const name = "HoangCoin"
            const symbol = "HLC"
            const URI = ""
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory_v1")
            )
            await nftFactory
                .connect(users[0])
                .deployCollectible(
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
            const new1555ContractAddress = await nftFactory.deployedContracts(
                BigNumber.from(salt)
            )

            new1155Contract = await ethers.getContractAt(
                "Collectible1155",
                new1555ContractAddress
            )
        })

        it("mint the token and transfer to the owner", async () => {
            let tokenInfo = {
                _fee: 1,
                _type: 1155,
                _supply: 10000,
                _index: 1,
                _creator: users[0].address,
            }
            let tokenId = await tokenCreator.createTokenId(
                tokenInfo._fee,
                tokenInfo._type,
                tokenInfo._supply,
                tokenInfo._index,
                tokenInfo._creator
            )

            await new1155Contract
                .connect(users[0])
                ["mint(address,uint256,uint256,string)"](
                    users[0].address,
                    tokenId,
                    BigNumber.from(90),
                    ""
                )
            await new1155Contract
                .connect(users[0])
                ["mint(uint256,uint256)"](tokenId, BigNumber.from(10))

            expect(
                await new1155Contract.balanceOf(users[0].address, tokenId)
            ).to.equal(BigNumber.from(100))
        })
    })
})
