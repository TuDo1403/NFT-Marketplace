import {expect} from "chai"
import {ethers, userConfig, upgrades} from "hardhat"
import {BigNumber} from "ethers"
import {TypedDataUtils} from "ethers-eip712"
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {
    Governance,
    Marketplace,
    ERC20Test,
    TokenCreator,
    Collectible1155,
    Collectible721,
    NFTFactory,
} from "../typechain-types"
const typedData = {
    types: {
        EIP712Domain: [
            {name: "name", type: "string"},
            {name: "version", type: "string"},
            {name: "chainId", type: "uint256"},
            {name: "verifyingContract", type: "address"},
        ],
        User: [
            {name: "addr", type: "address"},
            {name: "v", type: "uint8"},
            {name: "deadline", type: "uint256"},
            {name: "r", type: "bytes32"},
            {name: "s", type: "bytes32"},
        ],
        Header: [
            {name: "buyer", type: "User"},
            {name: "seller", type: "User"},
            {name: "nftContract", type: "address"},
            {name: "paymentToken", type: "address"},
        ],
        Item: [
            {name: "amount", type: "uint256"},
            {name: "tokenId", type: "uint256"},
            {name: "unitPrice", type: "uint256"},
            {name: "tokenURI", type: "string"},
        ],
        Bulk: [
            {name: "amounts", type: "uint256[]"},
            {name: "tokenIds", type: "uint256[]"},
            {name: "unitPrices", type: "uint256[]"},
            {name: "tokenURIs", type: "string[]"},
        ],
        Receipt: [
            {name: "header", type: "Header"},
            {name: "item", type: "Item"},
            {name: "nonce", type: "uint256"},
            {name: "deadline", type: "uint256"},
        ],
        BulkReceipt: [
            {name: "header", type: "Header"},
            {name: "bulk", type: "Bulk"},
            {name: "nonce", type: "uint256"},
            {name: "deadline", type: "uint256"},
        ],
    },
    domain: {
        name: "Marketplace",
        version: "v1",
        chainId: 31337,
        verifyingContract: "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC",
    },
    primaryType: "Receipt" as const,
    message: {
        header: {
            buyer: {
                addr: "",
                v: BigNumber.from(0),
                deadline: BigNumber.from(0),
                r: "",
                s: "",
            },
            seller: {
                addr: "",
                v: BigNumber.from(0),
                deadline: BigNumber.from(0),
                r: "",
                s: "",
            },
            nftContract: "",
            paymentToken: "",
        },
        item: {
            amount: BigNumber.from(0),
            tokenId: BigNumber.from(0),
            unitPrice: BigNumber.from(0),
            tokenURI: "",
        },
        nonce: BigNumber.from(0),
        deadline: BigNumber.from(0),
    },
}

async function increaseTime(duration: number): Promise<void> {
    ethers.provider.send("evm_increaseTime", [duration])
    ethers.provider.send("evm_mine", [])
}

async function decreaseTime(duration: number): Promise<void> {
    ethers.provider.send("evm_increaseTime", [duration * -1])
    ethers.provider.send("evm_mine", [])
}

async function signReceipt(
    addrBuyer: string,
    vBuyer: BigNumber,
    deadlineBuyer: BigNumber,
    rBuyer: string,
    sBuyer: string,
    addrSeller: string,
    vSeller: BigNumber,
    deadlineSeller: BigNumber,
    rSeller: string,
    sSeller: string,
    nftContract: string,
    paymentToken: string,
    amount: BigNumber,
    tokenId: BigNumber,
    unitPrice: BigNumber,
    tokenURI: string,
    nonce: BigNumber,
    deadline: BigNumber,
    verifyingContract: string,
    verifier: SignerWithAddress
): Promise<[any, string]> {
    let message = Object.assign({}, typedData.message)
    message.header = {
        buyer: {
            addr: addrBuyer,
            v: vBuyer,
            deadline: deadlineBuyer,
            r: rBuyer,
            s: sBuyer,
        },
        seller: {
            addr: addrSeller,
            v: vSeller,
            deadline: deadlineSeller,
            r: rSeller,
            s: sSeller,
        },
        nftContract: nftContract,
        paymentToken: paymentToken,
    }
    message.item = {
        amount: amount,
        tokenId: tokenId,
        unitPrice: unitPrice,
        tokenURI: tokenURI,
    }
    message.nonce = nonce
    message.deadline = deadline
    let typedData_ = JSON.parse(JSON.stringify(typedData))
    typedData_.message = message
    typedData_.domain.verifyingContract = verifyingContract
    const digest = TypedDataUtils.encodeDigest(typedData_)
    return [message, await verifier.signMessage(digest)]
}

async function erc20PermitSignature(
    buyer: SignerWithAddress,
    spender: string,
    value: BigNumber,
    nonce: BigNumber,
    deadline: BigNumber,
    verifyingContract: string
): Promise<[string, string, number]> {
    const signature = await buyer._signTypedData(
        {
            name: "PaymentToken",
            version: "1",
            chainId: 31337,
            verifyingContract: verifyingContract,
        },
        {
            Permit: [
                {
                    name: "owner",
                    type: "address",
                },
                {
                    name: "spender",
                    type: "address",
                },
                {
                    name: "value",
                    type: "uint256",
                },
                {
                    name: "nonce",
                    type: "uint256",
                },
                {
                    name: "deadline",
                    type: "uint256",
                },
            ],
        },
        {
            owner: buyer.address,
            spender,
            value,
            nonce,
            deadline,
        }
    )
    const {r, s, v} = ethers.utils.splitSignature(signature)
    return [r, s, v]
}

async function erc1155PermitSignature(
    seller: SignerWithAddress,
    spender: string,
    nonce: BigNumber,
    deadline: BigNumber,
    verifyingContract: string,
    domainName: string
): Promise<[string, string, number]> {
    const typedData = {
        types: {
            EIP712Domain: [
                {name: "name", type: "string"},
                {name: "version", type: "string"},
                {name: "chainId", type: "uint256"},
                {name: "verifyingContract", type: "address"},
            ],
            Permit: [
                {name: "owner", type: "address"},
                {name: "spender", type: "address"},
                {name: "nonce", type: "uint256"},
                {name: "deadline", type: "uint256"},
            ],
        },
        primaryType: "Permit" as const,
        domain: {
            name: domainName,
            version: "v1",
            chainId: 31337,
            verifyingContract: verifyingContract,
        },
        message: {
            owner: "",
            spender: "",
            nonce: BigNumber.from(0),
            deadline: BigNumber.from(0),
        },
    }
    let message = Object.assign({}, typedData.message)
    message = {
        owner: seller.address,
        spender: spender,
        nonce: nonce,
        deadline: deadline,
    }
    let typedData_ = JSON.parse(JSON.stringify(typedData))
    typedData_.message = message
    const digest = TypedDataUtils.encodeDigest(typedData_)
    const signature = await seller.signMessage(digest)
    const {r, s, v} = ethers.utils.splitSignature(signature)
    return [r, s, v]
}

async function erc721PermitSignature(
    seller: SignerWithAddress,
    spender: string,
    tokenId: BigNumber,
    nonce: BigNumber,
    deadline: BigNumber,
    verifyingContract: string,
    domainName: string
): Promise<[string, string, number]> {
    const typedData = {
        types: {
            EIP712Domain: [
                {name: "name", type: "string"},
                {name: "version", type: "string"},
                {name: "chainId", type: "uint256"},
                {name: "verifyingContract", type: "address"},
            ],
            Permit: [
                {name: "spender", type: "address"},
                {name: "tokenId", type: "uint256"},
                {name: "nonce", type: "uint256"},
                {name: "deadline", type: "uint256"},
            ],
        },
        primaryType: "Permit" as const,
        domain: {
            name: domainName,
            version: "v1",
            chainId: 31337,
            verifyingContract: verifyingContract,
        },
        message: {
            spender,
            tokenId,
            nonce,
            deadline,
        },
    }
    let typeData_ = JSON.parse(JSON.stringify(typedData))
    const digest = TypedDataUtils.encodeDigest(typeData_)
    const signature = await seller.signMessage(digest)
    const {r, s, v} = ethers.utils.splitSignature(signature)
    console.log(`tokenId: ${tokenId}`)
    console.log(`deadline: ${deadline}`)
    console.log(`spender: ${spender}`)
    return [r, s, v]
}

describe("MarketplaceBase", () => {
    let admin: SignerWithAddress
    let users: SignerWithAddress[]
    let verifier: SignerWithAddress
    let treasury: SignerWithAddress

    let governance: Governance
    let paymentToken: ERC20Test
    let nftFactory: NFTFactory
    let collectible1155Base: Collectible1155
    let collectible721Base: Collectible721
    let cloneNft1155: Collectible1155
    let cloneNft721: Collectible721
    let marketplace: Marketplace
    let tokenCreator: TokenCreator
    let serviceFee: number
    const balance = ethers.utils.parseEther("100000")
    const tokenURI1155 = "https://triton.com/token"
    const tokenURI721 = "https://vaicoin.com/token"
    let buyer: SignerWithAddress
    let creator: SignerWithAddress

    before(async () => {
        ;[admin, verifier, treasury, ...users] = await ethers.getSigners()
        buyer = users[0]
        creator = users[1]
        const ERC20TestFactory = await ethers.getContractFactory(
            "ERC20Test",
            admin
        )
        paymentToken = (await ERC20TestFactory.deploy("PaymentToken", "PMT") as ERC20Test)
        await paymentToken.deployed()
        for (const u of users) await paymentToken.mint(u.address, balance)

        const GovernanceFactory = await ethers.getContractFactory(
            "Governance",
            admin
        )
        governance = (await GovernanceFactory.deploy(
            treasury.address,
            verifier.address
        ) as Governance)
        await governance.deployed()
        await governance.connect(admin).registerToken(paymentToken.address)

        // const Collectible1155BaseFactory = await ethers.getContractFactory(
        //     "Collectible1155",
        //     admin
        // )
        // collectible1155Base = await Collectible1155BaseFactory.deploy()
        // await collectible1155Base.deployed()

        // const NFTFactoryFactory = await ethers.getContractFactory(
        //     "NFTFactory",
        //     admin
        // )
        // nftFactory = (await upgrades.deployProxy(
        //     NFTFactoryFactory,
        //     [governance.address],
        //     {initializer: "initialize"}
        // )) as NFTFactory
        // await nftFactory.deployed()

        // await nftFactory
        //     .connect(creator)
        //     .deployCollectible(collectible1155Base.address, "Triton", "TNT", "")
        // const version = ethers.utils.keccak256(
        //     ethers.utils.toUtf8Bytes("NFTFactory_v1")
        // )
        // const salt = ethers.utils.keccak256(
        //     ethers.utils.solidityPack(
        //         ["bytes32", "string", "string", "string"],
        //         [version, "Triton", "TNT", ""]
        //     )
        // )
        // const cloneNft1155Address = await nftFactory.deployedContracts(
        //     BigNumber.from(salt)
        // )
        // cloneNft1155 = await ethers.getContractAt(
        //     "Collectible1155",
        //     cloneNft1155Address,
        //     admin
        // )

        serviceFee = 5
        const MarketplaceBaseFactory = await ethers.getContractFactory(
            "Marketplace",
            admin
        )
        marketplace = (await MarketplaceBaseFactory.deploy() as Marketplace)
        await marketplace.deployed()
        await marketplace.initialize(governance.address, serviceFee)
        await governance.connect(admin).updateMarketplace(marketplace.address)
        console.log("marketplace address: ", await governance.marketplace())
        const TokenCreatorFactory = await ethers.getContractFactory(
            "TokenCreator",
            admin
        )
        tokenCreator = (await TokenCreatorFactory.deploy() as TokenCreator)
        await tokenCreator.deployed()
    })

    describe("NFT 1155", async () => {
        beforeEach(async () => {
            const Collectible1155BaseFactory = await ethers.getContractFactory(
                "Collectible1155",
                admin
            )
            collectible1155Base = (await Collectible1155BaseFactory.deploy() as Collectible1155)
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

            await nftFactory
                .connect(creator)
                .deployCollectible(
                    collectible1155Base.address,
                    "Triton",
                    "TNT",
                    ""
                )
            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory_v1")
            )
            const salt = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ["bytes32", "string", "string", "string"],
                    [version, "Triton", "TNT", ""]
                )
            )
            const cloneNft1155Address = await nftFactory.deployedContracts(
                BigNumber.from(salt)
            )
            cloneNft1155 = (await ethers.getContractAt(
                "Collectible1155",
                cloneNft1155Address,
                creator
            ) as Collectible1155)
        })
        it("should let user redeem with valid receipt", async () => {
            const now = (await ethers.provider.getBlock("latest")).timestamp

            const nonce = await marketplace.nonces(marketplace.address)
            const creatorFee = 250
            const tokenId = await tokenCreator.createTokenId(
                creatorFee,
                1155,
                2e5,
                0,
                creator.address
            )
            let amount = 12
            let unitPrice = 20
            const salePrice = unitPrice * amount
            // const servicePay = (totalPay * serviceFee) / 1e4
            const deadline = now + 60 * 1000
            let receipt: any
            let signature: string

            //Buyer sign signature to permit marketplace to use totalPay to buy nft
            const buyerNonce = await paymentToken.nonces(buyer.address)
            let rBuyer: string
            let sBuyer: string
            let vBuyer: number
            ;[rBuyer, sBuyer, vBuyer] = await erc20PermitSignature(
                buyer,
                marketplace.address,
                ethers.utils.parseEther(salePrice.toString()),
                BigNumber.from(buyerNonce),
                BigNumber.from(deadline),
                paymentToken.address
            )

            //Seller sign signature to permit marketplace to transfer nft when buyer buy nft
            let rSeller: string
            let sSeller: string
            let vSeller: number
            const sellerNonce = await cloneNft1155.nonces(creator.address)
            ;[rSeller, sSeller, vSeller] = await erc1155PermitSignature(
                creator,
                marketplace.address,
                BigNumber.from(sellerNonce),
                BigNumber.from(deadline),
                cloneNft1155.address,
                "Collectible1155"
            )
            ;[receipt, signature] = await signReceipt(
                buyer.address,
                BigNumber.from(vBuyer),
                BigNumber.from(deadline),
                rBuyer,
                sBuyer,
                creator.address,
                BigNumber.from(vSeller),
                BigNumber.from(deadline),
                rSeller,
                sSeller,
                cloneNft1155.address,
                paymentToken.address,
                BigNumber.from(amount),
                BigNumber.from(tokenId),
                ethers.utils.parseEther(unitPrice.toString()),
                tokenURI1155,
                nonce,
                BigNumber.from(deadline),
                marketplace.address,
                verifier
            )

            // console.log(`signature: ${signature}`)
            // console.log(`verifier address: ${verifier.address}`)
            // const enodeType2 = TypedDataUtils.encodeType(
            //     typedData.types,
            //     "BulkReceipt"
            // )
            // console.log(enodeType2)
            // console.log(
            //     ethers.utils.keccak256(ethers.utils.toUtf8Bytes(enodeType2))
            // )
            console.log(creator.address)
            console.log(marketplace.address)
            console.log("----------------------------------------------------")
            // await paymentToken.connect(buyer).approve(marketplace.address, totalPay)

            await expect(
                marketplace
                    .connect(buyer)
                    .redeem(receipt, signature, {value: ethers.utils.parseEther(salePrice.toString())})
            ).to.emit(marketplace, "ItemRedeemed")
        })
    })

    describe("NFT 721", async () => {
        beforeEach(async () => {
            const Collectible721Factory = await ethers.getContractFactory(
                "Collectible721",
                admin
            )
            collectible721Base = (await Collectible721Factory.deploy() as Collectible721)
            await collectible721Base.deployed()

            creator = users[2]
            buyer = users[3]
            await nftFactory
                .connect(creator)
                .deployCollectible(
                    collectible721Base.address,
                    "VaiCoin",
                    "VC",
                    ""
                )

            const version = ethers.utils.keccak256(
                ethers.utils.toUtf8Bytes("NFTFactory_v1")
            )
            const salt = ethers.utils.solidityKeccak256(
                ["bytes32", "string", "string", "string"],
                [version, "VaiCoin", "VC", ""]
            )

            const cloneNft721Address = await nftFactory.deployedContracts(salt)
            cloneNft721 = (await ethers.getContractAt(
                "Collectible721",
                cloneNft721Address,
                creator
            ) as Collectible721)
        })

        it("should let user redeem with valid receipt", async () => {
            const now = (await ethers.provider.getBlock("latest")).timestamp
            const nonce = await marketplace.nonces(marketplace.address)
            const creatorFee = 300
            const tokenId = await tokenCreator.createTokenId(
                creatorFee,
                721,
                1,
                1,
                creator.address
            )

            const salePrice = 500
            const deadline = now + 60 * 1000
            let receipt: any
            let signature: string

            const buyerNonce = await paymentToken.nonces(buyer.address)
            let rBuyer: string
            let sBuyer: string
            let vBuyer: number
            ;[rBuyer, sBuyer, vBuyer] = await erc20PermitSignature(
                buyer,
                marketplace.address,
                BigNumber.from(salePrice),
                BigNumber.from(buyerNonce),
                BigNumber.from(deadline),
                paymentToken.address
            )

            let rSeller: string
            let sSeller: string
            let vSeller: number
            const sellerNonce = await cloneNft1155.nonces(creator.address)
            ;[rSeller, sSeller, vSeller] = await erc721PermitSignature(
                creator,
                marketplace.address,
                tokenId,
                sellerNonce,
                BigNumber.from(deadline),
                cloneNft721.address,
                "Collectible721"
            )
            ;[receipt, signature] = await signReceipt(
                buyer.address,
                BigNumber.from(vBuyer),
                BigNumber.from(deadline),
                rBuyer,
                sBuyer,
                creator.address,
                BigNumber.from(vSeller),
                BigNumber.from(deadline),
                rSeller,
                sSeller,
                cloneNft721.address,
                paymentToken.address,
                BigNumber.from(1),
                BigNumber.from(tokenId),
                BigNumber.from(salePrice),
                tokenURI721,
                nonce,
                BigNumber.from(deadline),
                marketplace.address,
                verifier
            )

            console.log(`buyer address: ${buyer.address}`)
            console.log(`marketplace address: ${marketplace.address}`)
            console.log(
                "----------------------------------------------------------------"
            )
            await expect(
                marketplace
                    .connect(buyer)
                    .redeem(receipt, signature, {value: salePrice})
            ).to.emit(marketplace, "ItemRedeemed")
        })
    })
})
