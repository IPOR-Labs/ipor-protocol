const keys = require("../../json_keys.js");
const func = require("../../json_func.js");

module.exports = async function (deployer, _network, addresses) {
    const usdt = "TODO";
    await func.update(keys.USDT, usdt);

    const usdc = "TODO";
    await func.update(keys.USDC, usdc);

    const dai = "TODO";
    await func.update(keys.DAI, dai);

    const aave = "TODO";
    await func.update(keys.AAVE, aave);

    const aaveProvider = "TODO";
    await func.update(keys.AaveProvider, aaveProvider);

    const stakedAave = "TODO";
    await func.update(keys.StakedAave, stakedAave);

    const aaveIncentivesController = "TODO";
    await func.update(keys.AaveIncentivesController, aaveIncentivesController);

    // Shared token - AAVE
    const aUsdt = "TODO";
    await func.update(keys.aUSDT, aUsdt);

    const aUsdc = "TODO";
    await func.update(keys.aUSDC, aUsdc);

    const aDai = "TODO";
    await func.update(keys.aDAI, aDai);

    const comp = "TODO";
    await func.update(keys.COMP, comp);

    const comptroller = "TODO";
    await func.update(keys.Comptroller, comptroller);

    const compToken = "TODO";
    await func.update(keys.CompToken, compToken);

    //Shared token - Compound
    const cUsdt = "TODO";
    await func.update(keys.cUSDT, cUsdt);

    const cUsdc = "TODO";
    await func.update(keys.cUSDC, cUsdc);

    const cDai = "TODO";
    await func.update(keys.cDAI, cDai);

    await func.updateLastCompletedMigration();
};
