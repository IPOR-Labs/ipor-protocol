require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const keys = require("../../libs/json_keys.js");
const script = require("../../libs/contracts/setup/stanley_strategies/0001_initial_setup.js");

const IpTokenUsdt = artifacts.require("IpTokenUsdt");
const IpTokenUsdc = artifacts.require("IpTokenUsdc");
const IpTokenDai = artifacts.require("IpTokenDai");

const IvTokenUsdt = artifacts.require("IvTokenUsdt");
const IvTokenUsdc = artifacts.require("IvTokenUsdc");
const IvTokenDai = artifacts.require("IvTokenDai");

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");

const IporOracle = artifacts.require("IporOracle");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");
const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");
const StrategyAaveDai = artifacts.require("StrategyAaveDai");

const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");
const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");
const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");

const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

const JosephUsdt = artifacts.require("JosephUsdt");
const JosephUsdc = artifacts.require("JosephUsdc");
const JosephDai = artifacts.require("JosephDai");

const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");
const MiltonFacadeDataProvider = artifacts.require("MiltonFacadeDataProvider");
const CockpitDataProvider = artifacts.require("CockpitDataProvider");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);

    if (!process.env.SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS) {
        throw new Error(
            "Transfer ownership failed! Environment parameter SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS is not set!"
        );
    }

    const iporOwnerAddress = process.env.SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS;

    // IP Token
    const ipUSDT = await func.getValue(keys.ipUSDT);
    const ipUSDC = await func.getValue(keys.ipUSDC);
    const ipDAI = await func.getValue(keys.ipDAI);

    const ipUsdtInstance = await IpTokenUsdt.at(ipUSDT);
    const ipUsdcInstance = await IpTokenUsdc.at(ipUSDC);
    const ipDaiInstance = await IpTokenDai.at(ipDAI);

    await ipUsdtInstance.transferOwnership(iporOwnerAddress);
    await ipUsdcInstance.transferOwnership(iporOwnerAddress);
    await ipDaiInstance.transferOwnership(iporOwnerAddress);

    // IV Token
    const ivUSDT = await func.getValue(keys.ivUSDT);
    const ivUSDC = await func.getValue(keys.ivUSDC);
    const ivDAI = await func.getValue(keys.ivDAI);

    const ivUsdtInstance = await IvTokenUsdt.at(ivUSDT);
    const ivUsdcInstance = await IvTokenUsdc.at(ivUSDC);
    const ivDaiInstance = await IvTokenDai.at(ivDAI);

    await ivUsdtInstance.transferOwnership(iporOwnerAddress);
    await ivUsdcInstance.transferOwnership(iporOwnerAddress);
    await ivDaiInstance.transferOwnership(iporOwnerAddress);

    // Milton Spread Model
    const miltonSpreadModel = await func.getValue(keys.MiltonSpreadModel);

    const miltonSpreadModelInstance = await MiltonSpreadModel.at(miltonSpreadModel);
    await miltonSpreadModelInstance.transferOwnership(iporOwnerAddress);

    // Ipor Oracle
    const iporOracleProxy = await func.getValue(keys.IporOracleProxy);

    const iporOracleInstance = await IporOracle.at(iporOracleProxy);
    await iporOracleInstance.transferOwnership(iporOwnerAddress);

    // Milton Storage
    const miltonStorageProxyUsdt = await func.getValue(keys.MiltonStorageProxyUsdt);
    const miltonStorageProxyUsdc = await func.getValue(keys.MiltonStorageProxyUsdc);
    const miltonStorageProxyDai = await func.getValue(keys.MiltonStorageProxyDai);

    const miltonStorageUsdtInstance = await MiltonStorageUsdt.at(miltonStorageProxyUsdt);
    const miltonStorageUsdcInstance = await MiltonStorageUsdc.at(miltonStorageProxyUsdc);
    const miltonStorageDaiInstance = await MiltonStorageDai.at(miltonStorageProxyDai);

    await miltonStorageUsdtInstance.transferOwnership(iporOwnerAddress);
    await miltonStorageUsdcInstance.transferOwnership(iporOwnerAddress);
    await miltonStorageDaiInstance.transferOwnership(iporOwnerAddress);

    // AAVE Strategy
    const aaveStrategyProxyUsdt = await func.getValue(keys.AaveStrategyProxyUsdt);
    const aaveStrategyProxyUsdc = await func.getValue(keys.AaveStrategyProxyUsdc);
    const aaveStrategyProxyDai = await func.getValue(keys.AaveStrategyProxyDai);

    const aaveStrategyUsdtInstance = await StrategyAaveUsdt.at(aaveStrategyProxyUsdt);
    const aaveStrategyUsdcInstance = await StrategyAaveUsdc.at(aaveStrategyProxyUsdc);
    const aaveStrategyDaiInstance = await StrategyAaveDai.at(aaveStrategyProxyDai);

    await aaveStrategyUsdtInstance.transferOwnership(iporOwnerAddress);
    await aaveStrategyUsdcInstance.transferOwnership(iporOwnerAddress);
    await aaveStrategyDaiInstance.transferOwnership(iporOwnerAddress);

    // Compound Strategy
    const compoundStrategyProxyUsdt = await func.getValue(keys.CompoundStrategyProxyUsdt);
    const compoundStrategyProxyUsdc = await func.getValue(keys.CompoundStrategyProxyUsdc);
    const compoundStrategyProxyDai = await func.getValue(keys.CompoundStrategyProxyDai);

    const compoundStrategyUsdtInstance = await StrategyCompoundUsdt.at(compoundStrategyProxyUsdt);
    const compoundStrategyUsdcInstance = await StrategyCompoundUsdc.at(compoundStrategyProxyUsdc);
    const compoundStrategyDaiInstance = await StrategyCompoundDai.at(compoundStrategyProxyDai);

    await compoundStrategyUsdtInstance.transferOwnership(iporOwnerAddress);
    await compoundStrategyUsdcInstance.transferOwnership(iporOwnerAddress);
    await compoundStrategyDaiInstance.transferOwnership(iporOwnerAddress);

    // Stanley
    const stanleyProxyUsdt = await func.getValue(keys.StanleyProxyUsdt);
    const stanleyProxyUsdc = await func.getValue(keys.StanleyProxyUsdc);
    const stanleyProxyDai = await func.getValue(keys.StanleyProxyDai);

    const stanleyUsdtInstance = await StanleyUsdt.at(stanleyProxyUsdt);
    const stanleyUsdcInstance = await StanleyUsdc.at(stanleyProxyUsdc);
    const stanleyDaiInstance = await StanleyDai.at(stanleyProxyDai);

    await stanleyUsdtInstance.transferOwnership(iporOwnerAddress);
    await stanleyUsdcInstance.transferOwnership(iporOwnerAddress);
    await stanleyDaiInstance.transferOwnership(iporOwnerAddress);

    // Milton
    const miltonProxyUsdt = await func.getValue(keys.MiltonProxyUsdt);
    const miltonProxyUsdc = await func.getValue(keys.MiltonProxyUsdc);
    const miltonProxyDai = await func.getValue(keys.MiltonProxyDai);

    const miltonUsdtInstance = await MiltonUsdt.at(miltonProxyUsdt);
    const miltonUsdcInstance = await MiltonUsdc.at(miltonProxyUsdc);
    const miltonDaiInstance = await MiltonDai.at(miltonProxyDai);

    await miltonUsdtInstance.transferOwnership(iporOwnerAddress);
    await miltonUsdcInstance.transferOwnership(iporOwnerAddress);
    await miltonDaiInstance.transferOwnership(iporOwnerAddress);

    // Joseph
    const josephProxyUsdt = await func.getValue(keys.JosephProxyUsdt);
    const josephProxyUsdc = await func.getValue(keys.JosephProxyUsdc);
    const josephProxyDai = await func.getValue(keys.JosephProxyDai);

    const josephUsdtInstance = await JosephUsdt.at(josephProxyUsdt);
    const josephUsdcInstance = await JosephUsdc.at(josephProxyUsdc);
    const josephDaiInstance = await JosephDai.at(josephProxyDai);

    await josephUsdtInstance.transferOwnership(iporOwnerAddress);
    await josephUsdcInstance.transferOwnership(iporOwnerAddress);
    await josephDaiInstance.transferOwnership(iporOwnerAddress);

    // Ipor Oracle Facade Data Provider
    const iporOracleFacadeDataProviderProxy = await func.getValue(
        keys.IporOracleFacadeDataProviderProxy
    );
    const iporOracleFacadeDataProviderInstance = await IporOracleFacadeDataProvider.at(
        iporOracleFacadeDataProviderProxy
    );
    await iporOracleFacadeDataProviderInstance.transferOwnership(iporOwnerAddress);

    // Milton Facade Data Provider
    const miltonFacadeDataProviderProxy = await func.getValue(keys.MiltonFacadeDataProviderProxy);
    const miltonFacadeDataProviderInstance = await MiltonFacadeDataProvider.at(
        miltonFacadeDataProviderProxy
    );
    await miltonFacadeDataProviderInstance.transferOwnership(iporOwnerAddress);

    // Cockpit Data Provider
    const cockpitDataProviderProxy = await func.getValue(keys.CockpitDataProviderProxy);
    const cockpitDataProviderInstance = await CockpitDataProvider.at(cockpitDataProviderProxy);
    await cockpitDataProviderInstance.transferOwnership(iporOwnerAddress);

    await func.updateLastCompletedMigration();
};
