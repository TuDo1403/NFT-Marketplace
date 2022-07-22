import * as dotenv from "dotenv"

import {HardhatUserConfig, task} from "hardhat/config"
import "@openzeppelin/hardhat-upgrades"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-waffle"
import "@typechain/hardhat"
import "hardhat-gas-reporter"
import "hardhat-contract-sizer"
import "solidity-coverage"
dotenv.config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners()

    for (const account of accounts) {
        console.log(account.address)
    }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.13",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            evmVersion: "berlin"
        },
        
    },

    networks: {
        ropsten: {
            url: process.env.ROPSTEN_URL || "",
            accounts:
                process.env.PRIVATE_KEY !== undefined
                    ? [process.env.PRIVATE_KEY]
                    : [],
        },
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS ? true : false,
        currency: "USD",
        token: "ETH",
        noColors: true,
        // gasPrice: 21,
        coinmarketcap: process.env.CMC_API_KEY,
        //outputFile: `./logs/gas-cost-${Date.now()}.log`,
        //outputFile: `./logs/gas-cost-${Date.now()}.log`,
        gasPriceApi: `https://api.etherscan.io/api?module=proxy&action=eth_gasPrice`,
        // gasPriceApi: `https://api-moonbeam.moonscan.io/api?module=proxy&action=eth_gasPrice&apikey=${process.env.GLMR_API_KEY}`,
        // gasPriceApi: `https://api.bscscan.com/api?module=proxy&action=eth_gasPrice&apikey=${process.env.BNB_API_KEY}`,
    },
    contractSizer: {
        alphaSort: true,
        runOnCompile: true,
        disambiguatePaths: false,
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
}

export default config
