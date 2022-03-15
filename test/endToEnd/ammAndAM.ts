import { getEnabledCategories } from "node:trace_events";
import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";
const { expect } = require("chai");
import {
    ERC20,
    IpToken,
    IvToken,
    MiltonFaucet,
    AaveStrategy,
    CompoundStrategy,
    StanleyDai,
    StanleyUsdc,
    StanleyUsdt,
    MiltonStorageDai,
    MiltonStorageUsdc,
    MiltonStorageUsdt,
    MiltonSpreadModel,
    Warren,
    MiltonUsdc,
    MiltonUsdt,
    MiltonDai,
    JosephDai,
    JosephUsdc,
    JosephUsdt,
} from "../../types";

import {
    aaveTokenFactory,
    aaveUsdtStrategyFactory,
    aaveUsdcStrategyFactory,
    aaveDaiStrategyFactory,
    aaveStrategySetup,
} from "./aave";

import {
    compTokenFactory,
    compoundDaiStrategyFactory,
    compoundUsdcStrategyFactory,
    compoundUsdtStrategyFactory,
    compoundStrategySetup,
} from "./compound";
import {
    miltonFaucetFactory,
    miltonFaucetSetup,
    miltonStorageDaiFactory,
    miltonStorageUsdcFactory,
    miltonStorageUsdtFactory,
    miltonStorageSetup,
    miltonSpreadModelFactory,
    miltonDaiFactory,
    miltonUsdcFactory,
    miltonUsdtFactory,
    miltonSetup,
} from "./milton";
import {
    aDaiFactory,
    aUsdcFactory,
    aUsdtFactory,
    cDaiFactory,
    cUsdcFactory,
    cUsdtFactory,
    daiFactory,
    usdcFactory,
    usdtFactory,
    ipTokenUsdcFactory,
    ipTokenUsdtFactory,
    ipTokenDaiFactory,
    ipTokenSetup,
    ivTokenUsdcFactory,
    ivTokenUsdtFactory,
    ivTokenDaiFactory,
    ivTokenSetup,
} from "./tokens";
import { josephDaiFactory, josephUsdcFactory, josephUsdtFactory } from "./joseph";

import { warrenFactory, warrenSetup, initIporValuse } from "./warren";
import { stanleyDaiFactory, stanleyUsdcFactory, stanleyUsdtFactory, stanleySetup } from "./stanley";

// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("End to End tests on mainnet fork", function () {
    let dai: ERC20;
    let usdc: ERC20;
    let usdt: ERC20;

    let aDai: ERC20;
    let aUsdc: ERC20;
    let aUsdt: ERC20;

    let aaveToken: ERC20;
    let compToken: ERC20;

    let cDai: ERC20;
    let cUsdc: ERC20;
    let cUsdt: ERC20;

    let miltonFaucet: MiltonFaucet;

    let ipTokenDai: IpToken;
    let ipTokenUsdc: IpToken;
    let ipTokenUsdt: IpToken;

    let ivTokenDai: IvToken;
    let ivTokenUsdc: IvToken;
    let ivTokenUsdt: IvToken;

    let strategyAaveDai: AaveStrategy;
    let strategyAaveUsdc: AaveStrategy;
    let strategyAaveUsdt: AaveStrategy;

    let strategyCompoundDai: CompoundStrategy;
    let strategyCompoundUsdc: CompoundStrategy;
    let strategyCompoundUsdt: CompoundStrategy;

    let stanleyDai: StanleyDai;
    let stanleyUsdc: StanleyUsdc;
    let stanleyUsdt: StanleyUsdt;

    let miltonStorageDai: MiltonStorageDai;
    let miltonStorageUsdc: MiltonStorageUsdc;
    let miltonStorageUsdt: MiltonStorageUsdt;
    let miltonSpreadModel: MiltonSpreadModel;

    let warren: Warren;

    let miltonDai: MiltonDai;
    let miltonUsdc: MiltonUsdc;
    let miltonUsdt: MiltonUsdt;

    let josephDai: JosephDai;
    let josephUsdc: JosephUsdc;
    let josephUsdt: JosephUsdt;

    before(async () => {
        miltonFaucet = await miltonFaucetFactory();

        aUsdc = await aUsdcFactory();
        aUsdt = await aUsdtFactory();
        aDai = await aDaiFactory();

        cUsdc = await cUsdcFactory();
        cUsdt = await cUsdtFactory();
        cDai = await cDaiFactory();

        usdc = await usdcFactory();
        usdt = await usdtFactory();
        dai = await daiFactory();

        aaveToken = await aaveTokenFactory();

        ipTokenUsdt = await ipTokenUsdtFactory();
        ipTokenUsdc = await ipTokenUsdcFactory();
        ipTokenDai = await ipTokenDaiFactory();

        ivTokenUsdt = await ivTokenUsdtFactory();
        ivTokenUsdc = await ivTokenUsdcFactory();
        ivTokenDai = await ivTokenDaiFactory();

        strategyAaveDai = await aaveDaiStrategyFactory();
        strategyAaveUsdc = await aaveUsdcStrategyFactory();
        strategyAaveUsdt = await aaveUsdtStrategyFactory();

        compToken = await compTokenFactory();

        strategyCompoundDai = await compoundDaiStrategyFactory();
        strategyCompoundUsdc = await compoundUsdcStrategyFactory();
        strategyCompoundUsdt = await compoundUsdtStrategyFactory();

        stanleyDai = await stanleyDaiFactory(
            ivTokenDai.address,
            strategyAaveDai.address,
            strategyCompoundDai.address
        );
        stanleyUsdc = await stanleyUsdcFactory(
            ivTokenUsdc.address,
            strategyAaveUsdc.address,
            strategyCompoundUsdc.address
        );
        stanleyUsdt = await stanleyUsdtFactory(
            ivTokenUsdt.address,
            strategyAaveUsdt.address,
            strategyCompoundUsdt.address
        );

        miltonStorageDai = await miltonStorageDaiFactory();
        miltonStorageUsdc = await miltonStorageUsdcFactory();
        miltonStorageUsdt = await miltonStorageUsdtFactory();
        miltonSpreadModel = await miltonSpreadModelFactory();

        warren = await warrenFactory();
        warren.deployed();

        miltonDai = await miltonDaiFactory(
            ipTokenDai.address,
            warren.address,
            miltonStorageDai.address,
            miltonSpreadModel.address,
            stanleyDai.address
        );
        miltonUsdc = await miltonUsdcFactory(
            ipTokenUsdc.address,
            warren.address,
            miltonStorageUsdc.address,
            miltonSpreadModel.address,
            stanleyUsdc.address
        );
        miltonUsdt = await miltonUsdtFactory(
            ipTokenUsdt.address,
            warren.address,
            miltonStorageUsdt.address,
            miltonSpreadModel.address,
            stanleyUsdt.address
        );

        josephDai = await josephDaiFactory(
            ipTokenDai.address,
            miltonDai.address,
            miltonStorageDai.address,
            stanleyDai.address
        );
        josephUsdc = await josephUsdcFactory(
            ipTokenUsdc.address,
            miltonUsdc.address,
            miltonStorageUsdc.address,
            stanleyUsdc.address
        );
        josephUsdt = await josephUsdtFactory(
            ipTokenUsdt.address,
            miltonUsdt.address,
            miltonStorageUsdt.address,
            stanleyUsdt.address
        );

        // #####################################################################
        // ##################          Setup            ########################
        // #####################################################################
        await miltonSetup(miltonDai, josephDai, stanleyDai);
        await miltonSetup(miltonUsdc, josephUsdc, stanleyUsdc);
        await miltonSetup(miltonUsdt, josephUsdt, stanleyUsdt);

        await ipTokenSetup(ipTokenDai, josephDai.address);
        await ipTokenSetup(ipTokenUsdc, josephUsdc.address);
        await ipTokenSetup(ipTokenUsdt, josephUsdt.address);

        await miltonStorageSetup(miltonStorageDai, miltonDai, josephDai);
        await miltonStorageSetup(miltonStorageUsdc, miltonUsdc, josephUsdc);
        await miltonStorageSetup(miltonStorageUsdt, miltonUsdt, josephUsdt);

        await stanleySetup(stanleyDai, miltonDai.address);
        await stanleySetup(stanleyUsdc, miltonUsdc.address);
        await stanleySetup(stanleyUsdt, miltonUsdt.address);

        await ivTokenSetup(ivTokenDai, stanleyDai.address);
        await ivTokenSetup(ivTokenUsdc, stanleyUsdc.address);
        await ivTokenSetup(ivTokenUsdt, stanleyUsdt.address);

        await aaveStrategySetup(strategyAaveDai, stanleyDai.address);
        await aaveStrategySetup(strategyAaveUsdc, stanleyUsdc.address);
        await aaveStrategySetup(strategyAaveUsdt, stanleyUsdt.address);

        await compoundStrategySetup(strategyCompoundDai, stanleyDai.address);
        await compoundStrategySetup(strategyCompoundUsdc, stanleyUsdc.address);
        await compoundStrategySetup(strategyCompoundUsdt, stanleyUsdt.address);

        await warrenSetup(warren);
        await initIporValuse(warren);

        await miltonFaucetSetup(miltonFaucet, dai, usdc, usdt);
    });

    it("test", async () => {
        expect(true).to.be.true;
    });
});
