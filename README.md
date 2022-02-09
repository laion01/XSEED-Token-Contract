# ERC20 xSeed Token

npm run compile
npm run deploy_testnet
npx run verify_testnet CONTRACT_ADDESS




### 1. hardhat write config
Get the APIkey address under [ethScan](https://etherscan.io/myapikey) or [bscScan](https://bscscan.com/myapikey) personal information 
```shell
cp hardhat.config.js.example hardhat.config.js

// modify hardhat.config.js
const INFURA_PROJECT_ID = "00e8...2b41";
const ROPSTEN_PRIVATE_KEY = "07f1c38b7318fc6bd5e958...e3";
apiKey: "EQF6AY17HK1574GNC...", // eth
```

### 1. Edit XSeedToken.sol

# Binance testnet
address constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
address constant factoryAddress = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
address constant routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

# Binance mainnet
address constant WETH = 0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c;
address constant factoryAddress = 0xca143ce32fe78f1f7019d7d551a6402fc5350c73;
address constant routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

# Ethereum mainnet
address constant WETH = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
address constant factoryAddress = 0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f;
address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;