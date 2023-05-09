import { BigNumber, Signer } from "ethers";

import {
    ERC20,
    MockCUSDT,
    IpToken,
    IvToken,
    TestnetFaucet,
    StrategyAave,
    StrategyCompound,
    StanleyDai,
    StanleyUsdc,
    StanleyUsdt,
    MiltonStorageDai,
    MiltonStorageUsdc,
    MiltonStorageUsdt,
    MiltonSpreadModelUsdt,
    MiltonSpreadModelUsdc,
    MiltonSpreadModelDai,
    IporOracle,
    MiltonUsdc,
    MiltonUsdt,
    MiltonDai,
    JosephDai,
    JosephUsdc,
    JosephUsdt,
    MiltonFacadeDataProvider,
} from "../../types";
import {
    testnetFaucetFactory,
    testnetFaucetSetup,
    miltonStorageDaiFactory,
    miltonStorageUsdcFactory,
    miltonStorageUsdtFactory,
    miltonStorageSetup,
    miltonSpreadModelUsdtFactory,
    miltonSpreadModelUsdcFactory,
    miltonSpreadModelDaiFactory,
    miltonDaiFactory,
    miltonUsdcFactory,
    miltonUsdtFactory,
    miltonSetup,
    miltonFacadeDataProviderFactory,
} from "./milton";
import { josephDaiFactory, josephUsdcFactory, josephUsdtFactory } from "./joseph";
import { iporOracleFactory, iporOracleSetup, initIporValues } from "./iporOracle";
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
    strategyAaveSetup,
} from "./aave";
import {
    compTokenFactory,
    compoundDaiStrategyFactory,
    compoundUsdcStrategyFactory,
    compoundUsdtStrategyFactory,
    strategyCompoundSetup,
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
    cDai: MockCUSDT;
    cUsdc: MockCUSDT;
    cUsdt: MockCUSDT;
    testnetFaucet: TestnetFaucet;
    ipTokenDai: IpToken;
    ipTokenUsdc: IpToken;
    ipTokenUsdt: IpToken;
    ivTokenDai: IvToken;
    ivTokenUsdc: IvToken;
    ivTokenUsdt: IvToken;
    strategyAaveDai: StrategyAave;
    strategyAaveDaiV2: StrategyAave;
    strategyAaveUsdc: StrategyAave;
    strategyAaveUsdt: StrategyAave;
    strategyCompoundDai: StrategyCompound;
    strategyCompoundUsdc: StrategyCompound;
    strategyCompoundUsdt: StrategyCompound;
    stanleyDai: StanleyDai;
    stanleyUsdc: StanleyUsdc;
    stanleyUsdt: StanleyUsdt;
    miltonStorageDai: MiltonStorageDai;
    miltonStorageUsdc: MiltonStorageUsdc;
    miltonStorageUsdt: MiltonStorageUsdt;
    miltonSpreadModelUsdt: MiltonSpreadModelUsdt;
    miltonSpreadModelUsdc: MiltonSpreadModelUsdc;
    miltonSpreadModelDai: MiltonSpreadModelDai;
    miltonFacadeDataProvider: MiltonFacadeDataProvider;
    iporOracle: IporOracle;
    miltonDai: MiltonDai;
    miltonUsdc: MiltonUsdc;
    miltonUsdt: MiltonUsdt;
    josephDai: JosephDai;
    josephUsdc: JosephUsdc;
    josephUsdt: JosephUsdt;
};

export const deploy = async (admin: Signer): Promise<DeployType> => {
    const testnetFaucet = await testnetFaucetFactory();

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
    const strategyAaveDaiV2 = await aaveDaiStrategyFactory();
    const strategyAaveUsdc = await aaveUsdcStrategyFactory();
    const strategyAaveUsdt = await aaveUsdtStrategyFactory();

    await strategyAaveDai.addPauseGuardian(await admin.getAddress());
    await strategyAaveDaiV2.addPauseGuardian(await admin.getAddress());
    await strategyAaveUsdc.addPauseGuardian(await admin.getAddress());
    await strategyAaveUsdt.addPauseGuardian(await admin.getAddress());

    const compToken = await compTokenFactory();

    const strategyCompoundDai = await compoundDaiStrategyFactory();
    const strategyCompoundUsdc = await compoundUsdcStrategyFactory();
    const strategyCompoundUsdt = await compoundUsdtStrategyFactory();

    await strategyCompoundDai.addPauseGuardian(await admin.getAddress());
    await strategyCompoundUsdc.addPauseGuardian(await admin.getAddress());
    await strategyCompoundUsdt.addPauseGuardian(await admin.getAddress());

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

    await stanleyDai.addPauseGuardian(await admin.getAddress());
    await stanleyUsdc.addPauseGuardian(await admin.getAddress());
    await stanleyUsdt.addPauseGuardian(await admin.getAddress());

    const miltonStorageDai = await miltonStorageDaiFactory();
    const miltonStorageUsdc = await miltonStorageUsdcFactory();
    const miltonStorageUsdt = await miltonStorageUsdtFactory();
    const miltonSpreadModelUsdt = await miltonSpreadModelUsdtFactory();
    const miltonSpreadModelUsdc = await miltonSpreadModelUsdcFactory();
    const miltonSpreadModelDai = await miltonSpreadModelDaiFactory();

    const assets = [usdt.address, usdc.address, dai.address];

    //update timestamp examples only
    const updateTimestamps = [
        BigNumber.from("1640000000"),
        BigNumber.from("1640000000"),
        BigNumber.from("1640000000"),
    ];

    const exponentialMovingAverages = [
        BigNumber.from("31132626894697926"),
        BigNumber.from("30109512549022512"),
        BigNumber.from("32706669664256327"),
    ];
    const exponentialWeightedMovingVariances = [
        BigNumber.from("1828129745656718"),
        BigNumber.from("53273740801041"),
        BigNumber.from("49811986068491"),
    ];

    const initialParams = {
        assets,
        updateTimestamps,
        exponentialMovingAverages,
        exponentialWeightedMovingVariances,
    };

    const iporOracle = await iporOracleFactory(initialParams);

    const miltonUsdt = await miltonUsdtFactory(
        iporOracle.address,
        miltonStorageUsdt.address,
        miltonSpreadModelUsdt.address,
        stanleyUsdt.address
    );
    const miltonUsdc = await miltonUsdcFactory(
        iporOracle.address,
        miltonStorageUsdc.address,
        miltonSpreadModelUsdc.address,
        stanleyUsdc.address
    );
    const miltonDai = await miltonDaiFactory(
        iporOracle.address,
        miltonStorageDai.address,
        miltonSpreadModelDai.address,
        stanleyDai.address
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
    const miltonFacadeDataProvider = await miltonFacadeDataProviderFactory(
        dai,
        usdc,
        usdt,
        miltonDai,
        miltonUsdc,
        miltonUsdt,
        miltonStorageDai,
        miltonStorageUsdc,
        miltonStorageUsdt,
        josephUsdt,
        josephUsdc,
        josephDai,
        iporOracle
    );
    await josephDai.addAppointedToRebalance(await admin.getAddress());
    await josephUsdc.addAppointedToRebalance(await admin.getAddress());
    await josephUsdt.addAppointedToRebalance(await admin.getAddress());
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
        testnetFaucet,
        ipTokenDai,
        ipTokenUsdc,
        ipTokenUsdt,
        ivTokenDai,
        ivTokenUsdc,
        ivTokenUsdt,
        strategyAaveDai,
        strategyAaveDaiV2,
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
        miltonSpreadModelUsdt,
        miltonSpreadModelUsdc,
        miltonSpreadModelDai,
        miltonFacadeDataProvider,
        iporOracle,
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
        testnetFaucet,
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
        strategyAaveDaiV2,
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
        iporOracle,
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

    await strategyAaveSetup(strategyAaveDai, stanleyDai.address);
    await strategyAaveSetup(strategyAaveDaiV2, stanleyDai.address);
    await strategyAaveSetup(strategyAaveUsdc, stanleyUsdc.address);
    await strategyAaveSetup(strategyAaveUsdt, stanleyUsdt.address);

    await strategyCompoundSetup(strategyCompoundDai, stanleyDai.address);
    await strategyCompoundSetup(strategyCompoundUsdc, stanleyUsdc.address);
    await strategyCompoundSetup(strategyCompoundUsdt, stanleyUsdt.address);

    await iporOracleSetup(iporOracle);
    await initIporValues(iporOracle);

    await testnetFaucetSetup(testnetFaucet, dai, usdc, usdt);
};
