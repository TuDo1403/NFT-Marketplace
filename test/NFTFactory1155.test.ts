import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { Collectible1155, Governance, NFTFactory1155, TokenId } from "../typechain";

describe("NFTFactory1155", () => {
    let manager: SignerWithAddress;
    let treasury: SignerWithAddress;
    let verifier: SignerWithAddress;
    let marketplace: SignerWithAddress;
    let users: SignerWithAddress[];

    let governance: Governance;
    let nftFactory1155: NFTFactory1155;
    let collectible1155: Collectible1155;
    let myCollectible1155: Collectible1155;
    let tokenIdGenerator: TokenId;

    before(async () => {
        [manager, treasury, verifier, marketplace,...users] = await ethers.getSigners();

        const GovernanceContract = await ethers.getContractFactory("Governance", manager);
        governance = await GovernanceContract.deploy(
            manager.address,
            treasury.address,
            verifier.address
        );
        await governance.deployed();

        const Collectible1155Contract = await ethers.getContractFactory("Collectible1155", manager);
        collectible1155 = await Collectible1155Contract.deploy(
            manager.address
        );
        await collectible1155.deployed();

        const NFTFactory1155Contract = await ethers.getContractFactory("NFTFactory1155", manager);
        nftFactory1155 = await NFTFactory1155Contract.deploy(
            governance.address
        );
        await nftFactory1155.deployed();

        const TokenIdGeneratorContract = await ethers.getContractFactory("TokenId");
        tokenIdGenerator = await TokenIdGeneratorContract.deploy();
        await tokenIdGenerator.deployed();
    });

    it("Change governance address", async () => {
        let newGovernance = "0x90F79bf6EB2c4f870365E785982E1f101E93b906"; // any address
        await nftFactory1155.setGovernance(newGovernance);
        expect(await nftFactory1155.governance()).to.equal(newGovernance);
    });

    it("Create new collectible erc1155", async () => {
        let newTokenName = "DEMOTOKEN";
        let newSymbol = "DT";
        let newBaseUri = "";

        await nftFactory1155.deployCollectible1155(
            collectible1155.address,
            newTokenName,
            newSymbol,
            newBaseUri
        );

        let version = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("NFTFactory1155_v1"));
        let salt = ethers.utils.keccak256(ethers.utils.solidityPack(
            ["bytes", "string", "string", "string"],
            [version, newTokenName, newSymbol, newBaseUri]
        ));

        let deployedAddr = await nftFactory1155.deployedContracts(BigNumber.from(salt));

        let deployedCollectible = await ethers.getContractAt("Collectible1155", deployedAddr);

        expect(await deployedCollectible.name()).to.equal(newTokenName);
        expect(await deployedCollectible.symbol()).to.equal(newSymbol);
    });

    it("Create second collectible", async () => {
        let newTokenName = "DEMOTOKEN2";
        let newSymbol = "DT2";
        let newBaseUri = "";

        await nftFactory1155.deployCollectible1155(
            collectible1155.address,
            newTokenName,
            newSymbol,
            newBaseUri
        );

        let version = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("NFTFactory1155_v1"));
        let salt = ethers.utils.keccak256(ethers.utils.solidityPack(
            ["bytes", "string", "string", "string"],
            [version, newTokenName, newSymbol, newBaseUri]
        ));

        let deployedAddr = await nftFactory1155.connect(users[0]).deployedContracts(BigNumber.from(salt));

        myCollectible1155 = await ethers.getContractAt("Collectible1155", deployedAddr);

        expect(await myCollectible1155.name()).to.equal(newTokenName);
        expect(await myCollectible1155.symbol()).to.equal(newSymbol);
    });

    it("Test mint erc1155 functions", async () => {
        let newTokenName = "DEMOTOKEN2";
        let newSymbol = "DT2";
        let newBaseUri = "";

        let version = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("NFTFactory1155_v1"));
        let salt = ethers.utils.keccak256(ethers.utils.solidityPack(
            ["bytes", "string", "string", "string"],
            [version, newTokenName, newSymbol, newBaseUri]
        ));

        let deployedAddr = await nftFactory1155.connect(manager).deployedContracts(BigNumber.from(salt));
        myCollectible1155 = await ethers.getContractAt("Collectible1155", deployedAddr);

        let tokenInfo = {
            _fee: 1,
            _type: 1155,
            _supply: 10000,
            _index: 1,
            _creator: users[0].address
        };
        let tokenId = await tokenIdGenerator.createTokenId(tokenInfo);
        console.log("Token Id: ",tokenId);
        let creator = await tokenIdGenerator.getTokenCreator(tokenId);
        console.log("Creator: ", creator);
        expect(creator).to.equal(users[0].address);

        await myCollectible1155.connect(manager)["mint(address,uint256,uint256,string)"](users[0].address, tokenId, BigNumber.from(10), "");
        
        await myCollectible1155.connect(users[0])["mint(uint256,uint256)"](tokenId, BigNumber.from(9990));

        expect(await myCollectible1155.balanceOf(users[0].address, tokenId)).to.equal(BigNumber.from(10000));

    });
});