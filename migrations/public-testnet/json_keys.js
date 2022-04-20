#!/usr/bin/node
const fs = require("fs");
const editJsonFile = require("edit-json-file");

const USDT = "USDT";
const USDC = "USDC";
const DAI = "DAI";

const AAVE = "AAVE";

const aUSDT = "aUSDT";
const aUSDC = "aUSDC";
const aDAI = "aDAI";

const AaveProvider = "AaveProvider";
const AaveStaked = "AaveStaked";
const AaveIncentivesController = "AaveIncentivesController";

const cUSDT = "cUSDT";
const cUSDC = "cUSDC";
const cDAI = "cDAI";

const ipUSDT = "ipUSDT";
const ipUSDC = "ipUSDC";
const ipDAI = "ipDAI";

const ivUSDT = "ivUSDT";
const ivUSDC = "ivUSDC";
const ivDAI = "ivDAI";

const MiltonSpreadModel = "MiltonSpreadModel";
const IporOracleProxy = "IporOracleProxy";
const IporOracleImpl = "IporOracleImpl";

module.exports = {
    USDT: USDT,
    USDC: USDC,
    DAI: DAI,
    ipUSDT: ipUSDT,
    ipUSDC: ipUSDC,
    ipDAI: ipDAI,
    ivUSDT: ivUSDT,
    ivUSDC: ivUSDC,
    ivDAI: ivDAI,
    AAVE: AAVE,
    aUSDT: aUSDT,
    aUSDC: aUSDC,
    aDAI: aDAI,
    AaveProvider: AaveProvider,
    AaveStaked: AaveStaked,
    AaveIncentivesController: AaveIncentivesController,
    cUSDT: cUSDT,
    cUSDC: cUSDC,
    cDAI: cDAI,
    MiltonSpreadModel: MiltonSpreadModel,
    IporOracleProxy: IporOracleProxy,
    IporOracleImpl: IporOracleImpl,
    MiltonStorageProxyUsdt: "MiltonStorageProxyUsdt",
    MiltonStorageImplUsdt: "MiltonStorageImplUsdt",
    MiltonStorageProxyUsdc: "MiltonStorageProxyUsdc",
    MiltonStorageImplUsdc: "MiltonStorageImplUsdc",
    MiltonStorageProxyDai: "MiltonStorageProxyDai",
    MiltonStorageImplDai: "MiltonStorageImplDai",
    AaveStrategyProxyUsdt: "AaveStrategyProxyUsdt",
    AaveStrategyImplUsdt: "AaveStrategyImplUsdt",
    AaveStrategyProxyUsdc: "AaveStrategyProxyUsdc",
    AaveStrategyImplUsdc: "AaveStrategyImplUsdc",
    AaveStrategyProxyDai: "AaveStrategyProxyDai",
    AaveStrategyImplDai: "AaveStrategyImplDai",
};
