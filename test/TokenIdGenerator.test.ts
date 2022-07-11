/* eslint-disable prettier/prettier */
import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { TokenIdGenerator } from "../typechain";
import { BigNumber } from "ethers";

let signedTokenIdGenerator: TokenIdGenerator;
let users: SignerWithAddress[];
let tokenIdGenerator: TokenIdGenerator;

beforeEach(async () => {
    users = await ethers.getSigners();
    const TokenIdGeneratorFactory = await ethers.getContractFactory(
        "TokenIdGenerator",
        users[0]
    );
    tokenIdGenerator = await TokenIdGeneratorFactory.deploy();
    await tokenIdGenerator.deployed();

    signedTokenIdGenerator = tokenIdGenerator.connect(users[0]);
});

describe("TokenIdGenerator", () => {
    const fee = 250
    const type = 1155
    const supply = 50000
    const index = 1432
    it("can extract address from tokenId", async () => {
        const tokenId: BigNumber = await signedTokenIdGenerator.createTokenId(
            fee,
            type,
            supply,
            index,
            users[0].address
        );
        const userAddr = await signedTokenIdGenerator.getTokenCreator(tokenId);
        expect(userAddr).to.equal(users[0].address);
    });
    it("can extract supply from tokenId", async () => {
        const tokenId: BigNumber = await signedTokenIdGenerator.createTokenId(
            fee,
            type,
            supply,
            index,
            users[0].address
        );
        const supply_ = await signedTokenIdGenerator.getTokenMaxSupply(tokenId);
        expect(supply_).to.equal(supply);
    })
    it("can extract type from tokenId", async () => {
        const tokenId: BigNumber = await signedTokenIdGenerator.createTokenId(
            fee,
            type,
            supply,
            index,
            users[0].address
        );
        const type_ = await signedTokenIdGenerator.getTokenType(tokenId);
        expect(type_).to.equal(type);
    })
    it("can extract index from tokenId", async () => {
        const tokenId: BigNumber = await signedTokenIdGenerator.createTokenId(
            fee,
            type,
            supply,
            index,
            users[0].address
        );
        const index_ = await signedTokenIdGenerator.getTokenIndex(tokenId);
        expect(index_).to.equal(index);
    })
});
