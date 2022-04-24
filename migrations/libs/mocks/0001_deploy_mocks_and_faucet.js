const keys = require("../json_keys.js");
const func = require("../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (
    deployer,
    _network,
    addresses,
    [
        TestnetFaucet,
        UsdtMockedToken,
        UsdcMockedToken,
        DaiMockedToken,
        MockAUsdc,
        MockAUsdt,
        MockADai,
        MockLendingPoolAave,
        MockProviderAave,
        MockStakedAave,
        AAVEMockedToken,
        MockAaveIncentivesController,
        MockWhitePaper,
        MockedCOMPToken,
        MockComptroller,
        MockCDai,
        MockCUSDT,
        MockCUSDC,
        MockStrategyTestnetUsdt,
        MockStrategyTestnetUsdc,
        MockStrategyTestnetDai,
    ]
) {
    let stableTotalSupply6Decimals = "1000000000000000000";
    let stableTotalSupply18Decimals = "1000000000000000000000000000000";

    await deployer.deploy(UsdtMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdt = await UsdtMockedToken.deployed();

    await func.update(keys.USDT, mockedUsdt.address);

    await deployer.deploy(UsdcMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdc = await UsdcMockedToken.deployed();

    await func.update(keys.USDC, mockedUsdc.address);

    await deployer.deploy(DaiMockedToken, stableTotalSupply18Decimals, 18);
    const mockedDai = await DaiMockedToken.deployed();

    await func.update(keys.DAI, mockedDai.address);

    await deployer.deploy(MockAUsdt);
    const mockedAUsdt = await MockAUsdt.deployed();

    await func.update(keys.aUSDT, mockedAUsdt.address);

    await deployer.deploy(MockAUsdc);
    const mockedAUsdc = await MockAUsdc.deployed();

    await func.update(keys.aUSDC, mockedAUsdc.address);

    await deployer.deploy(MockADai);
    const mockedADai = await MockADai.deployed();

    await func.update(keys.aDAI, mockedADai.address);

    await deployer.deploy(AAVEMockedToken, stableTotalSupply18Decimals, 18);
    const mockedAAVE = await AAVEMockedToken.deployed();

    await func.update(keys.AAVE, mockedAAVE.address);

    await deployer.deploy(
        MockLendingPoolAave,
        mockedDai.address,
        mockedADai.address,
        BigInt("1000000000000000000"),
        mockedUsdc.address,
        mockedAUsdc.address,
        BigInt("2000000"),
        mockedUsdt.address,
        mockedAUsdt.address,
        BigInt("2000000")
    );
    const mockedLendingPool = await MockLendingPoolAave.deployed();

    await deployer.deploy(MockProviderAave, mockedLendingPool.address);
    const mockedAaveProvider = await MockProviderAave.deployed();

    await func.update(keys.AaveProvider, mockedAaveProvider.address);

    await deployer.deploy(MockStakedAave, mockedAAVE.address);
    const mockedStakedAave = await MockStakedAave.deployed();

    await func.update(keys.AaveStaked, mockedStakedAave.address);

    await deployer.deploy(MockAaveIncentivesController, mockedStakedAave.address);
    const mockedAaveIncentivesController = await MockAaveIncentivesController.deployed();

    await func.update(keys.AaveIncentivesController, mockedAaveIncentivesController.address);

    await deployer.deploy(MockWhitePaper);
    const mockedWhitePaperInstance = await MockWhitePaper.deployed();

    await deployer.deploy(MockCUSDT, mockedUsdt.address, mockedWhitePaperInstance.address);
    const mockedCUsdt = await MockCUSDT.deployed();

    await func.update(keys.cUSDT, mockedCUsdt.address);

    await deployer.deploy(MockCUSDC, mockedUsdc.address, mockedWhitePaperInstance.address);
    const mockedCUsdc = await MockCUSDC.deployed();

    await func.update(keys.cUSDC, mockedCUsdc.address);

    await deployer.deploy(MockCDai, mockedDai.address, mockedWhitePaperInstance.address);
    const mockedCDai = await MockCDai.deployed();

    await func.update(keys.cDAI, mockedCDai.address);

    await deployer.deploy(MockedCOMPToken, stableTotalSupply18Decimals, 18);
    const mockedCOMP = await MockedCOMPToken.deployed();

    await func.update(keys.COMP, mockedCOMP.address);

    await deployer.deploy(
        MockComptroller,
        mockedCOMP.address,
        mockedCUsdt.address,
        mockedCUsdc.address,
        mockedCDai.address
    );
    const mockedComptroller = await MockComptroller.deployed();

    await func.update(keys.Comptroller, mockedComptroller.address);

    const testnetFaucetProxy = await deployProxy(
        TestnetFaucet,
        [mockedDai.address, mockedUsdc.address, mockedUsdt.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const testnetFaucetImpl = await erc1967.getImplementationAddress(testnetFaucetProxy.address);

    await func.update(keys.TestnetFaucetProxy, testnetFaucetProxy.address);
    await func.update(keys.TestnetFaucetImpl, testnetFaucetImpl);

    const mockedStrategyTestnetUsdtProxy = await deployProxy(
        MockStrategyTestnetUsdt,
        [mockedUsdt.address, mockedAUsdt.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const mockedStrategyTestnetUsdtImpl = await erc1967.getImplementationAddress(
        mockedStrategyTestnetUsdtProxy.address
    );

    await func.update(keys.StrategyTestnetUsdtProxy, mockedStrategyTestnetUsdtProxy.address);
    await func.update(keys.StrategyTestnetUsdtImpl, mockedStrategyTestnetUsdtImpl);

    const mockedStrategyTestnetUsdcProxy = await deployProxy(
        MockStrategyTestnetUsdc,
        [mockedUsdc.address, mockedAUsdc.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const mockedStrategyTestnetUsdcImpl = await erc1967.getImplementationAddress(
        mockedStrategyTestnetUsdcProxy.address
    );

    await func.update(keys.StrategyTestnetUsdcProxy, mockedStrategyTestnetUsdcProxy.address);
    await func.update(keys.StrategyTestnetUsdcImpl, mockedStrategyTestnetUsdcImpl);

    const mockedStrategyTestnetDaiProxy = await deployProxy(
        MockStrategyTestnetDai,
        [mockedDai.address, mockedADai.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const mockedStrategyTestnetDaiImpl = await erc1967.getImplementationAddress(
        mockedStrategyTestnetDaiProxy.address
    );

    await func.update(keys.StrategyTestnetDaiProxy, mockedStrategyTestnetDaiProxy.address);
    await func.update(keys.StrategyTestnetDaiImpl, mockedStrategyTestnetDaiImpl);
};
