import { BigNumber } from "ethers";

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
import { josephDaiFactory, josephUsdcFactory, josephUsdtFactory } from "./joseph";
import { warrenFactory, warrenSetup, initIporValues } from "./warren";
import { stanleyDaiFactory, stanleyUsdcFactory, stanleyUsdtFactory, stanleySetup } from "./stanley";
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
export type DeployType = {
    dai: ERC20;
    usdc: ERC20;
    usdt: ERC20;
    aDai: ERC20;
    aUsdc: ERC20;
    aUsdt: ERC20;
    aaveToken: ERC20;
    compToken: ERC20;
    cDai: ERC20;
    cUsdc: ERC20;
    cUsdt: ERC20;
    miltonFaucet: MiltonFaucet;
    ipTokenDai: IpToken;
    ipTokenUsdc: IpToken;
    ipTokenUsdt: IpToken;
    ivTokenDai: IvToken;
    ivTokenUsdc: IvToken;
    ivTokenUsdt: IvToken;
    strategyAaveDai: AaveStrategy;
    strategyAaveUsdc: AaveStrategy;
    strategyAaveUsdt: AaveStrategy;
    strategyCompoundDai: CompoundStrategy;
    strategyCompoundUsdc: CompoundStrategy;
    strategyCompoundUsdt: CompoundStrategy;
    stanleyDai: StanleyDai;
    stanleyUsdc: StanleyUsdc;
    stanleyUsdt: StanleyUsdt;
    miltonStorageDai: MiltonStorageDai;
    miltonStorageUsdc: MiltonStorageUsdc;
    miltonStorageUsdt: MiltonStorageUsdt;
    miltonSpreadModel: MiltonSpreadModel;
    warren: Warren;
    miltonDai: MiltonDai;
    miltonUsdc: MiltonUsdc;
    miltonUsdt: MiltonUsdt;
    josephDai: JosephDai;
    josephUsdc: JosephUsdc;
    josephUsdt: JosephUsdt;
};

export const deploy = async (): Promise<DeployType> => {
    const miltonFaucet = await miltonFaucetFactory();

    const aUsdc = await aUsdcFactory();
    const aUsdt = await aUsdtFactory();
    const aDai = await aDaiFactory();

    const cUsdc = await cUsdcFactory();
    const cUsdt = await cUsdtFactory();
    const cDai = await cDaiFactory();

    const usdc = await usdcFactory();
    const usdt = await usdtFactory();
    const dai = await daiFactory();

    const aaveToken = await aaveTokenFactory();

    const ipTokenUsdt = await ipTokenUsdtFactory();
    const ipTokenUsdc = await ipTokenUsdcFactory();
    const ipTokenDai = await ipTokenDaiFactory();

    const ivTokenUsdt = await ivTokenUsdtFactory();
    const ivTokenUsdc = await ivTokenUsdcFactory();
    const ivTokenDai = await ivTokenDaiFactory();

    const strategyAaveDai = await aaveDaiStrategyFactory();
    const strategyAaveUsdc = await aaveUsdcStrategyFactory();
    const strategyAaveUsdt = await aaveUsdtStrategyFactory();

    const compToken = await compTokenFactory();

    const strategyCompoundDai = await compoundDaiStrategyFactory();
    const strategyCompoundUsdc = await compoundUsdcStrategyFactory();
    const strategyCompoundUsdt = await compoundUsdtStrategyFactory();

    const stanleyDai = await stanleyDaiFactory(
        ivTokenDai.address,
        strategyAaveDai.address,
        strategyCompoundDai.address
    );
    const stanleyUsdc = await stanleyUsdcFactory(
        ivTokenUsdc.address,
        strategyAaveUsdc.address,
        strategyCompoundUsdc.address
    );
    const stanleyUsdt = await stanleyUsdtFactory(
        ivTokenUsdt.address,
        strategyAaveUsdt.address,
        strategyCompoundUsdt.address
    );

    const miltonStorageDai = await miltonStorageDaiFactory();
    const miltonStorageUsdc = await miltonStorageUsdcFactory();
    const miltonStorageUsdt = await miltonStorageUsdtFactory();
    const miltonSpreadModel = await miltonSpreadModelFactory();

    const warren = await warrenFactory();

    const miltonDai = await miltonDaiFactory(
        ipTokenDai.address,
        warren.address,
        miltonStorageDai.address,
        miltonSpreadModel.address,
        stanleyDai.address
    );
    const miltonUsdc = await miltonUsdcFactory(
        ipTokenUsdc.address,
        warren.address,
        miltonStorageUsdc.address,
        miltonSpreadModel.address,
        stanleyUsdc.address
    );
    const miltonUsdt = await miltonUsdtFactory(
        ipTokenUsdt.address,
        warren.address,
        miltonStorageUsdt.address,
        miltonSpreadModel.address,
        stanleyUsdt.address
    );

    const josephDai = await josephDaiFactory(
        ipTokenDai.address,
        miltonDai.address,
        miltonStorageDai.address,
        stanleyDai.address
    );
    const josephUsdc = await josephUsdcFactory(
        ipTokenUsdc.address,
        miltonUsdc.address,
        miltonStorageUsdc.address,
        stanleyUsdc.address
    );
    const josephUsdt = await josephUsdtFactory(
        ipTokenUsdt.address,
        miltonUsdt.address,
        miltonStorageUsdt.address,
        stanleyUsdt.address
    );
    return {
        dai,
        usdc,
        usdt,
        aDai,
        aUsdc,
        aUsdt,
        aaveToken,
        compToken,
        cDai,
        cUsdc,
        cUsdt,
        miltonFaucet,
        ipTokenDai,
        ipTokenUsdc,
        ipTokenUsdt,
        ivTokenDai,
        ivTokenUsdc,
        ivTokenUsdt,
        strategyAaveDai,
        strategyAaveUsdc,
        strategyAaveUsdt,
        strategyCompoundDai,
        strategyCompoundUsdc,
        strategyCompoundUsdt,
        stanleyDai,
        stanleyUsdc,
        stanleyUsdt,
        miltonStorageDai,
        miltonStorageUsdc,
        miltonStorageUsdt,
        miltonSpreadModel,
        warren,
        miltonDai,
        miltonUsdc,
        miltonUsdt,
        josephDai,
        josephUsdc,
        josephUsdt,
    };
};

export const setup = async (deployed: DeployType) => {
    const {
        miltonFaucet,
        usdc,
        usdt,
        dai,
        ipTokenUsdt,
        ipTokenUsdc,
        ipTokenDai,
        ivTokenUsdt,
        ivTokenUsdc,
        ivTokenDai,
        strategyAaveDai,
        strategyAaveUsdc,
        strategyAaveUsdt,
        strategyCompoundDai,
        strategyCompoundUsdc,
        strategyCompoundUsdt,
        stanleyDai,
        stanleyUsdc,
        stanleyUsdt,
        miltonStorageDai,
        miltonStorageUsdc,
        miltonStorageUsdt,
        warren,
        miltonDai,
        miltonUsdc,
        miltonUsdt,
        josephDai,
        josephUsdc,
        josephUsdt,
    } = deployed;

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
    await initIporValues(warren);

    await miltonFaucetSetup(miltonFaucet, dai, usdc, usdt);
};
