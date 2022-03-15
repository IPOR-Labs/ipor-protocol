import hre from "hardhat";
import { BigNumber } from "ethers";

import { ERC20, IpToken, IvToken } from "../../types";

const usdcAbi = require("../../abis/usdcAbi.json");
const usdtAbi = require("../../abis/usdtAbi.json");
const daiAbi = require("../../abis/daiAbi.json");

// #####################################################################
// ##################          aTokens           #######################
// #####################################################################

export const aDaiAddress = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";
export const aUsdcAddress = "0xBcca60bB61934080951369a648Fb03DF4F96263C";
export const aUsdtAddress = "0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811";

export const aDaiFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(aDaiAddress, daiAbi, admin) as ERC20;
};

export const aUsdcFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(aUsdcAddress, usdcAbi, admin) as ERC20;
};
export const aUsdtFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(aUsdtAddress, usdtAbi, admin) as ERC20;
};

// #####################################################################
// ##################          cTokens           #######################
// #####################################################################

export const cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
export const cUsdcAddress = "0x39AA39c021dfbaE8faC545936693aC917d5E7563";
export const cUsdtAddress = "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9";

export const cDaiFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(cDaiAddress, daiAbi, admin) as ERC20;
};

export const cUsdcFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(cUsdcAddress, usdcAbi, admin) as ERC20;
};
export const cUsdtFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(cUsdtAddress, usdtAbi, admin) as ERC20;
};

// #####################################################################
// ##################          stable           ########################
// #####################################################################

export const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
export const usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
export const daiAddress = "0x6b175474e89094c44da98b954eedeac495271d0f";

export const usdcFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(usdcAddress, usdcAbi, admin) as ERC20;
};
// max amound 1606287659962048
export const transferUsdcToAddress = async (to: string, amoung: BigNumber) => {
    const accountToImpersonate = "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7"; // Usdc rich address - Curve.fi: DAI/USDC/USDT Pool
    await hre.network.provider.send("hardhat_setBalance", [
        accountToImpersonate,
        "0x500000000000000000000",
    ]);
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [accountToImpersonate],
    });
    const signer = await hre.ethers.provider.getSigner(accountToImpersonate);
    const usdcContract = new hre.ethers.Contract(usdcAddress, usdcAbi, signer) as ERC20;
    await usdcContract.connect(signer).transfer(to, amoung);
};

export const usdtFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(usdtAddress, usdtAbi, admin) as ERC20;
};
// max amound 1010694873293061
export const transferUsdtToAddress = async (to: string, amoung: BigNumber) => {
    const accountToImpersonate = "0x5754284f345afc66a98fbb0a0afe71e0f007b949"; // Usdt rich address
    await hre.network.provider.send("hardhat_setBalance", [
        accountToImpersonate,
        "0x500000000000000000000",
    ]);
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [accountToImpersonate],
    });
    const signer = await hre.ethers.provider.getSigner(accountToImpersonate);
    const usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, signer) as ERC20;
    await usdtContract.connect(signer).transfer(to, amoung);
};

export const daiFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(daiAddress, daiAbi, admin) as ERC20;
};
// max amound 1700078532741875411567855723
export const transferDaiToAddress = async (to: string, amoung: BigNumber) => {
    const accountToImpersonate = "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7"; // Dai rich address - Curve.fi: DAI/USDC/USDT Pool
    await hre.network.provider.send("hardhat_setBalance", [
        accountToImpersonate,
        "0x500000000000000000000",
    ]);
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [accountToImpersonate],
    });
    const signer = await hre.ethers.provider.getSigner(accountToImpersonate);
    const daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer) as ERC20;
    await daiContract.connect(signer).transfer(to, amoung);
};

// #####################################################################
// ##################         IpToken           ########################
// #####################################################################

export const ipTokenUsdtFactory = async (): Promise<IpToken> => {
    const ipTokenFactory = await hre.ethers.getContractFactory("IpToken");
    return ipTokenFactory.deploy(usdtAddress, "IP USDT", "ipUSDT") as Promise<IpToken>;
};

export const ipTokenUsdcFactory = async (): Promise<IpToken> => {
    const ipTokenFactory = await hre.ethers.getContractFactory("IpToken");
    return ipTokenFactory.deploy(usdtAddress, "IP USDC", "ipUSDC") as Promise<IpToken>;
};

export const ipTokenDaiFactory = async (): Promise<IpToken> => {
    const ipTokenFactory = await hre.ethers.getContractFactory("IpToken");
    return ipTokenFactory.deploy(usdtAddress, "IP DAI", "ipDAI") as Promise<IpToken>;
};

export const ipTokenSetup = async (ipToken: IpToken, josephAddress: string) => {
    ipToken.setJoseph(josephAddress);
};

// #####################################################################
// ##################         IvToken           ########################
// #####################################################################

export const ivTokenUsdtFactory = async (): Promise<IvToken> => {
    const ivTokenFactory = await hre.ethers.getContractFactory("IvToken");
    return ivTokenFactory.deploy("IV USDT", "ivUSDT", usdtAddress) as Promise<IvToken>;
};

export const ivTokenUsdcFactory = async (): Promise<IvToken> => {
    const ivTokenFactory = await hre.ethers.getContractFactory("IvToken");
    return ivTokenFactory.deploy("IV USDC", "ivUSDC", usdcAddress) as Promise<IvToken>;
};

export const ivTokenDaiFactory = async (): Promise<IvToken> => {
    const ivTokenFactory = await hre.ethers.getContractFactory("IvToken");
    return ivTokenFactory.deploy("IV DAI", "ivDAI", usdtAddress) as Promise<IvToken>;
};

export const ivTokenSetup = async (ivToken: IvToken, stanleyAddress: string) => {
    await ivToken.setStanley(stanleyAddress);
};
