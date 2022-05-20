const func = require("../../libs/json_keys.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    const usdt = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
    await func.update(keys.USDT, usdt);

    const usdc = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    await func.update(keys.USDC, usdc);

    const dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    await func.update(keys.DAI, dai);

    //AAVE - Begin
    const aave = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
    await func.update(keys.AAVE, aave);

    const aUsdt = "0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811";
    await func.update(keys.aUSDT, aUsdt);

    const aUsdc = "0xBcca60bB61934080951369a648Fb03DF4F96263C";
    await func.update(keys.aUSDC, aUsdc);

    const aDai = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";
    await func.update(keys.aDAI, aDai);

    const aaveProvider = "0xb53c1a33016b2dc2ff3653530bff1848a515c8c5";
    await func.update(keys.AaveProvider, aaveProvider);

    const stakedAave = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";
    await func.update(keys.StakedAave, stakedAave);

    const aaveIncentivesController = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";
    await func.update(keys.AaveIncentivesController, aaveIncentivesController);
    //AAVE - End

    //Compound - Begin
    const comp = "0xc00e94cb662c3520282e6f5717214004a7f26888";
    await func.update(keys.COMP, comp);

    const cUsdt = "0xf650c3d88d12db855b8bf7d11be6c55a4e07dcc9";
    await func.update(keys.cUSDT, cUsdt);

    const cUsdc = "0x39aa39c021dfbae8fac545936693ac917d5e7563";
    await func.update(keys.cUSDC, cUsdc);

    const cDai = "0x5d3a536e4d6dbd6114cc1ead35777bab948e3643";
    await func.update(keys.cDAI, cDai);

    const comptroller = "0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b";
    await func.update(keys.Comptroller, comptroller);
    //Compound - End

    await func.updateLastCompletedMigration();
};
