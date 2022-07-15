import {expect} from "chai";
import {ethers} from "hardhat";
import {BigNumber} from "ethers";
import {TypedDataUtils} from "ethers-eip712";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {NFTFactory1155} from "../typechain/NFTFactory1155";
import {
    IGovernance,
    Governance,
    MarketplaceBase,
    ERC20Test,
    TokenCreator,
    Collectible1155,
} from "../typechain";

const typedData = {
    types: {
        EIP712Domain: [
            {name: "name", type: "string"},
            {name: "version", type: "string"},
            {name: "chainId", type: "uint256"},
            {name: "verifyingContract", type: "address"},
        ],
        Header: [
            {name: "nonce", type: "uint256"},
            {name: "ticketExpiration", type: "uint256"},
            {name: "seller", type: "address"},
            {name: "paymentToken", type: "address"},
            {name: "creatorPayoutAddr", type: "address"},
        ],
        Payment: [
            {name: "subTotal", type: "uint256"},
            {name: "creatorPayout", type: "uint256"},
            {name: "servicePayout", type: "uint256"},
            {name: "total", type: "uint256"},
        ],
        Item: [
            {name: "amount", type: "uint256"},
            {name: "tokenId", type: "uint256"},
            {name: "unitPrice", type: "uint256"},
            {name: "nftContract", type: "address"},
            {name: "tokenURI", type: "string"},
        ],

        Receipt: [
            {name: "header", type: "Header"},
            {name: "payment", type: "Payment"},
            {name: "item", type: "Item"},
        ],
    },
    domain: {
        name: "Marketplace",
        version: "1",
        chainId: 31337,
        verifyingContract: "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC",
    },
    primaryType: "Receipt" as const,
    message: {
        header: {
            nonce: BigNumber.from(0),
            ticketExpiration: BigNumber.from(0),
            seller: "",
            paymentToken: "",
            creatorPayoutAddr: "",
        },
        payment: {
            subTotal: BigNumber.from(0),
            creatorPayout: BigNumber.from(0),
            servicePayout: BigNumber.from(0),
            total: BigNumber.from(0),
        },
        item: {
            amount: BigNumber.from(0),
            tokenId: BigNumber.from(0),
            unitPrice: BigNumber.from(0),
            nftContract: "",
            tokenURI: "",
        },
    },
};

async function increaseTime(duration: number): Promise<void> {
    ethers.provider.send("evm_increaseTime", [duration]);
    ethers.provider.send("evm_mine", []);
}

async function decreaseTime(duration: number): Promise<void> {
    ethers.provider.send("evm_increaseTime", [duration * -1]);
    ethers.provider.send("evm_mine", []);
}

async function signReceipt(
    verifier: SignerWithAddress,
    verifyingContract: string,
    nonce: BigNumber,
    ticketExpiration: BigNumber,
    seller: string,
    paymentToken: string,
    creatorPayoutAddr: string,
    amount: BigNumber,
    tokenId: BigNumber,
    unitPrice: BigNumber,
    nftContract: string,
    tokenURI: string,
    subTotal: BigNumber,
    creatorPayout: BigNumber,
    servicePayout: BigNumber,
    total: BigNumber
): Promise<[any, string]> {
    let message = Object.assign({}, typedData.message);
    message.header = {
        nonce: nonce,
        ticketExpiration: ticketExpiration,
        seller: seller,
        paymentToken: paymentToken,
        creatorPayoutAddr: creatorPayoutAddr,
    };
    message.payment = {
        subTotal: subTotal,
        creatorPayout: creatorPayout,
        servicePayout: servicePayout,
        total: total,
    };
    message.item = {
        amount: amount,
        tokenId: tokenId,
        unitPrice: unitPrice,
        nftContract: nftContract,
        tokenURI: tokenURI,
    };

    let typedData_ = JSON.parse(JSON.stringify(typedData)); // copy data
    typedData_.message = message;
    typedData_.domain.verifyingContract = verifyingContract;
    const digest = TypedDataUtils.encodeDigest(typedData_);
    return [message, await verifier.signMessage(digest)];
}

describe("MarketplaceBase", () => {
    let admin: SignerWithAddress;
    let users: SignerWithAddress[];
    let manager: SignerWithAddress;
    let verifier: SignerWithAddress;
    let treasury: SignerWithAddress;

    let governance: Governance;
    let paymentToken: ERC20Test;
    let collectible1155Base: Collectible1155;
    let collectible1155: Collectible1155;
    let nftFactory1155: NFTFactory1155;
    let marketplace: MarketplaceBase;
    let tokenCreator: TokenCreator;

    let serviceFee: number;

    const balance = 1e5;
    const tokenURI = "https://triton.example/token/";

    before(async () => {
        [admin, manager, verifier, treasury, ...users] =
            await ethers.getSigners();
        const ERC20TestFactory = await ethers.getContractFactory(
            "ERC20Test",
            admin
        );
        paymentToken = await ERC20TestFactory.deploy("PaymentToken", "PMT");
        for (const u of users) await paymentToken.mint(u.address, balance);

        const governanceFactory = await ethers.getContractFactory(
            "Governance",
            admin
        );
        governance = await governanceFactory.deploy(
            manager.address,
            treasury.address,
            verifier.address
        );

        await governance.connect(manager).registerToken(paymentToken.address);

        const collectible1155Factory = await ethers.getContractFactory(
            "Collectible1155",
            admin
        );
        collectible1155 = await collectible1155Factory.deploy(
            governance.address
        );

        serviceFee = 250;
        const marketplaceBaseFactory = await ethers.getContractFactory(
            "MarketplaceBase",
            admin
        );
        marketplace = await marketplaceBaseFactory.deploy(
            governance.address,
            serviceFee,
            500
        );
        await governance
            .connect(manager)
            .updateMarketplace(marketplace.address);
        const tokenCreatorFactory = await ethers.getContractFactory(
            "TokenCreator",
            admin
        );
        tokenCreator = await tokenCreatorFactory.deploy();
    });

    it("should let user redeem with valid receipt", async () => {
        const now = (await ethers.provider.getBlock("latest")).timestamp;
        let buyer: SignerWithAddress;
        let creator: SignerWithAddress;
        [buyer, creator, ] = users;
        // buyer = users[0];
        // creator = users[1];
        const nonce = await marketplace.nonce();
        const creatorFee = 250;
        const tokenId = await tokenCreator.createTokenId(
            creatorFee,
            1155,
            0,
            2e5,
            creator.address
        );
        let amount = 12;
        let unitPrice = 500;
        const subTotal = amount * unitPrice;
        const creatorPayout = (subTotal * creatorFee) / 1e4;
        const servicePayout = (subTotal * serviceFee) / 1e4;
        const total = subTotal + creatorPayout + servicePayout;
        const deadline = now + 60 * 1000;
        const ticketExpiration = now + 5 * 60 * 1000;
        let receipt: any;
        let signature: string;
        [receipt, signature] = await signReceipt(
            verifier,
            marketplace.address,
            nonce,
            BigNumber.from(ticketExpiration),
            creator.address,
            paymentToken.address,
            creator.address,
            BigNumber.from(amount),
            tokenId,
            BigNumber.from(unitPrice),
            collectible1155.address,
            tokenURI,
            BigNumber.from(subTotal),
            BigNumber.from(creatorPayout),
            BigNumber.from(servicePayout),
            BigNumber.from(total)
        );
        await paymentToken.connect(buyer).approve(marketplace.address, total);
        await paymentToken
            .connect(buyer)
            .approve(treasury.address, servicePayout);

        expect(
            await marketplace
                .connect(buyer)
                .redeem(deadline, receipt, signature, {value: total})
        )
            .to.emit(marketplace, "ItemRedeemed")
            .withArgs(
                collectible1155.address,
                buyer.address,
                tokenId,
                paymentToken,
                unitPrice,
                total
            );
    });
});
