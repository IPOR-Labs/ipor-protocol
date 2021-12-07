const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
  TOTAL_SUPPLY_18_DECIMALS,
  TOTAL_SUPPLY_6_DECIMALS,
  USER_SUPPLY_18_DECIMALS,
  ZERO,
  COLLATERALIZATION_FACTOR_18DEC,
  USD_10_000_18DEC,
  USD_14_000_18DEC,
  USD_10_000_6DEC,
  USD_14_000_6DEC,
  USER_SUPPLY_6_DECIMALS,
  PERCENTAGE_3_18DEC,
  PERCENTAGE_3_6DEC,
  USD_10_18DEC,
  USD_10_400_18DEC
} = require("./Const.js");

const grantAllRoleIporConfiguration = async (iporConfiguration, accounts) => {
  await iporConfiguration.grantRole(
    keccak256("MILTON_STORAGE_ADMIN_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("MILTON_STORAGE_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("WARREN_STORAGE_ADMIN_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("WARREN_STORAGE_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("IPOR_ASSETS_ADMIN_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("IPOR_ASSETS_ROLE"),
    accounts[0].address
  );

  await iporConfiguration.grantRole(
    keccak256("MILTON_ADMIN_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("MILTON_ROLE"),
    accounts[0].address
  );

  await iporConfiguration.grantRole(
    keccak256("JOSEPH_ADMIN_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("JOSEPH_ROLE"),
    accounts[0].address
  );

  await iporConfiguration.grantRole(
    keccak256("WARREN_ADMIN_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("WARREN_ROLE"),
    accounts[0].address
  );

  await iporConfiguration.grantRole(
    keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
    accounts[0].address
  );

  await iporConfiguration.grantRole(
    keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE"),
    accounts[0].address
  );

  await iporConfiguration.grantRole(
    keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE"),
    accounts[0].address
  );

  await iporConfiguration.grantRole(
    keccak256("MILTON_SPREAD_STRATEGY_ADMIN_ROLE"),
    accounts[0].address
  );
  await iporConfiguration.grantRole(
    keccak256("MILTON_SPREAD_STRATEGY_ROLE"),
    accounts[0].address
  );
};

const setupTokenDaiInitialValuesForUsers = async (users, testData) => {
  for (let i = 0; i < users.length; i++) {
    await testData.tokenDai.setupInitialAmount(
      users[i].address,
      USER_SUPPLY_18_DECIMALS
    );
  }
};

const setupTokenUsdtInitialValuesForUsers = async (users, testData) => {
  for (let i = 0; i < users.length; i++) {
    await testData.tokenUsdt.setupInitialAmount(
      users[i].address,
      USER_SUPPLY_6_DECIMALS
    );
  }
};

const setupIpTokenDaiInitialValues = async (
  liquidityProvider,
  initialAmount
) => {
  if (initialAmount > 0) {
    await data.iporConfiguration.setJoseph(liquidityProvider.address);
    await data.ipTokenDai
      .connect(liquidityProvider)
      .mint(liquidityProvider.address, initialAmount);
    await data.iporConfiguration.setJoseph(data.joseph.address);
  }
};

const setupIpTokenUsdtInitialValues = async (
  liquidityProvider,
  initialAmount
) => {
  if (initialAmount > 0) {
    await data.iporConfiguration.setJoseph(liquidityProvider.address);
    await data.ipTokenUsdt
      .connect(liquidityProvider)
      .mint(liquidityProvider, initialAmount);
    await data.iporConfiguration.setJoseph(data.joseph.address);
  }
};

const getStandardDerivativeParamsDAI = (user, testData) => {
  return {
    asset: testData.tokenDai.address,
    totalAmount: USD_10_000_18DEC,
    slippageValue: 3,
    collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
    direction: 0,
    openTimestamp: Math.floor(Date.now() / 1000),
    from: user,
  };
};

const getStandardDerivativeParamsUSDT = (user, testData) => {
  return {
    asset: testData.tokenUsdt.address,
    totalAmount: USD_10_000_6DEC,
    slippageValue: 3,
    collateralizationFactor: BigInt(10000000),
    direction: 0,
    openTimestamp: Math.floor(Date.now() / 1000),
    from: user,
  };
};

const getLibraries = async () => {
  const DerivativeLogic = await ethers.getContractFactory("DerivativeLogic");
  const derivativeLogic = await DerivativeLogic.deploy();
  await derivativeLogic.deployed();

  const SoapIndicatorLogic = await ethers.getContractFactory(
    "SoapIndicatorLogic"
  );
  const soapIndicatorLogic = await SoapIndicatorLogic.deploy();
  await soapIndicatorLogic.deployed();

  const TotalSoapIndicatorLogic = await ethers.getContractFactory(
    "TotalSoapIndicatorLogic",
    {
      libraries: {
        SoapIndicatorLogic: soapIndicatorLogic.address,
      },
    }
  );
  const totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deploy();
  await totalSoapIndicatorLogic.deployed();

  return {
    derivativeLogic,
    totalSoapIndicatorLogic,
    soapIndicatorLogic,
  };
};

const prepareData = async (libraries, accounts) => {
  const IporConfiguration = await ethers.getContractFactory(
    "IporConfiguration"
  );
  const iporConfiguration = await IporConfiguration.deploy();
  await iporConfiguration.deployed();
  await grantAllRoleIporConfiguration(iporConfiguration, accounts);

  const MiltonDevToolDataProvider = await ethers.getContractFactory(
    "MiltonDevToolDataProvider"
  );
  const miltonDevToolDataProvider = await MiltonDevToolDataProvider.deploy(
    iporConfiguration.address
  );
  await miltonDevToolDataProvider.deployed();

  const TestWarren = await ethers.getContractFactory("TestWarren");
  const warren = await TestWarren.deploy();
  await warren.deployed();

  const TestMilton = await ethers.getContractFactory("TestMilton", {
    libraries: { DerivativeLogic: libraries.derivativeLogic.address },
  });
  const milton = await TestMilton.deploy();
  await milton.deployed();

  const TestJoseph = await ethers.getContractFactory("TestJoseph");
  const joseph = await TestJoseph.deploy();
  await joseph.deployed();

  await iporConfiguration.setWarren(await warren.address);
  await iporConfiguration.setMilton(await milton.address);
  await iporConfiguration.setJoseph(await joseph.address);

  await warren.initialize(iporConfiguration.address);
  await milton.initialize(iporConfiguration.address);
  await joseph.initialize(iporConfiguration.address);

  let data = {
    warren,
    milton,
    joseph,
    iporConfiguration,
    miltonDevToolDataProvider,
  };

  return data;
};

// TODO implement only for DAI
const prepareTestData = async (accounts, assets, data, lib) => {
  let tokenDai = null;
  let tokenUsdt = null;
  let tokenUsdc = null;
  let ipTokenUsdt = null;
  let ipTokenUsdc = null;
  let ipTokenDai = null;
  let iporAssetConfigurationUsdt = null;
  let iporAssetConfigurationUsdc = null;
  let iporAssetConfigurationDai = null;

  const MiltonStorage = await ethers.getContractFactory("MiltonStorage", {
    libraries: {
      DerivativesView: lib.derivativeLogic.address,
      TotalSoapIndicatorLogic: lib.totalSoapIndicatorLogic.address,
    },
  });
  const miltonStorage = await MiltonStorage.deploy();
  await miltonStorage.deployed();

  const WarrenStorage = await ethers.getContractFactory("WarrenStorage");
  const warrenStorage = await WarrenStorage.deploy();
  await warrenStorage.deployed();

  await warrenStorage.addUpdater(accounts[1].address);
  await warrenStorage.addUpdater(data.warren.address);

  await data.iporConfiguration.setMiltonStorage(miltonStorage.address);
  await data.iporConfiguration.setWarrenStorage(warrenStorage.address);

  await miltonStorage.initialize(data.iporConfiguration.address);
  await warrenStorage.initialize(data.iporConfiguration.address);

  const MiltonLPUtilizationStrategyCollateral = await ethers.getContractFactory(
    "MiltonLPUtilizationStrategyCollateral"
  );
  const miltonLPUtilizationStrategyCollateral =
    await MiltonLPUtilizationStrategyCollateral.deploy();
  await miltonLPUtilizationStrategyCollateral.deployed();
  await miltonLPUtilizationStrategyCollateral.initialize(
    data.iporConfiguration.address
  );
  await data.iporConfiguration.setMiltonLPUtilizationStrategy(
    miltonLPUtilizationStrategyCollateral.address
  );

  const MiltonSpreadStrategy = await ethers.getContractFactory(
    "MiltonSpreadStrategy"
  );
  const miltonSpreadStrategy = await MiltonSpreadStrategy.deploy();
  await miltonSpreadStrategy.deployed();
  await miltonSpreadStrategy.initialize(data.iporConfiguration.address);
  await data.iporConfiguration.setMiltonSpreadStrategy(
    miltonSpreadStrategy.address
  );

  for (let k = 0; k < assets.length; k++) {
    if (assets[k] === "USDT") {
      const UsdtMockedToken = await ethers.getContractFactory(
        "UsdtMockedToken"
      );
      tokenUsdt = await UsdtMockedToken.deploy(TOTAL_SUPPLY_6_DECIMALS, 6);
      await tokenUsdt.deployed();
      await data.iporConfiguration.addAsset(tokenUsdt.address);
      await data.milton.authorizeJoseph(tokenUsdt.address);
      const IpToken = await ethers.getContractFactory("IpToken");
      ipTokenUsdt = await IpToken.deploy(
        tokenUsdt.address,
        "IP USDT",
        "ipUSDT"
      );
      ipTokenUsdt.deployed();
      ipTokenUsdt.initialize(data.iporConfiguration.address);
      const IporAssetConfigurationUsdt = await ethers.getContractFactory(
        "IporAssetConfiguration"
      );
      iporAssetConfigurationUsdt = await IporAssetConfigurationUsdt.deploy(
        tokenUsdt.address,
        ipTokenUsdt.address
      );
      await iporAssetConfigurationUsdt.deployed();
      await data.iporConfiguration.setIporAssetConfiguration(
        tokenUsdt.address,
        await iporAssetConfigurationUsdt.address
      );
      await miltonStorage.addAsset(tokenUsdt.address);
    }
    // if (assets[k] === "USDC") {
    //     tokenUsdc = await UsdcMockedToken.new(TOTAL_SUPPLY_6_DECIMALS, 6);
    //     await data.iporConfiguration.addAsset(tokenUsdc.address);
    //     await data.milton.authorizeJoseph(tokenUsdc.address);
    //     ipTokenUsdc = await IpToken.new(tokenUsdc.address, "IP USDC", "ipUSDC");
    //     ipTokenUsdc.initialize(data.iporConfiguration.address);
    //     iporAssetConfigurationUsdc = await IporAssetConfigurationUsdc.new(tokenUsdc.address, ipTokenUsdc.address);
    //     await data.iporConfiguration.setIporAssetConfiguration(tokenUsdc.address, await iporAssetConfigurationUsdc.address);
    //     await miltonStorage.addAsset(tokenUsdc.address);
    // }
    if (assets[k] === "DAI") {
      const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
      tokenDai = await DaiMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18);
      await tokenDai.deployed();
      await data.iporConfiguration.addAsset(tokenDai.address);
      await data.milton.authorizeJoseph(tokenDai.address);

      const IpToken = await ethers.getContractFactory("IpToken");
      ipTokenDai = await IpToken.deploy(tokenDai.address, "IP DAI", "ipDAI");
      await ipTokenDai.deployed();
      ipTokenDai.initialize(data.iporConfiguration.address);

      const IporAssetConfigurationDai = await ethers.getContractFactory(
        "IporAssetConfiguration"
      );
      iporAssetConfigurationDai = await IporAssetConfigurationDai.deploy(
        tokenDai.address,
        ipTokenDai.address
      );
      await iporAssetConfigurationDai.deployed();

      await data.iporConfiguration.setIporAssetConfiguration(
        tokenDai.address,
        iporAssetConfigurationDai.address
      );
      await miltonStorage.addAsset(tokenDai.address);
    }
  }

  return {
    tokenDai,
    tokenUsdt,
    tokenUsdc,
    ipTokenUsdt,
    ipTokenUsdc,
    ipTokenDai,
    iporAssetConfigurationUsdt,
    iporAssetConfigurationUsdc,
    iporAssetConfigurationDai,
    miltonStorage,
    warrenStorage,
  };
};

const prepareApproveForUsers = async (users, asset, data, testData) => {
  for (let i = 0; i < users.length; i++) {
    if (asset === "USDT") {
      await testData.tokenUsdt
        .connect(users[i])
        .approve(data.joseph.address, TOTAL_SUPPLY_6_DECIMALS);
      await testData.tokenUsdt
        .connect(users[i])
        .approve(data.milton.address, TOTAL_SUPPLY_6_DECIMALS);
    }
    if (asset === "USDC") {
      await testData.tokenUsdc
        .connect(users[i])
        .approve(data.joseph.address, TOTAL_SUPPLY_6_DECIMALS);
      await testData.tokenUsdc
        .connect(users[i])
        .approve(data.milton.address, TOTAL_SUPPLY_6_DECIMALS);
    }
    if (asset === "DAI") {
      await testData.tokenDai
        .connect(users[i])
        .approve(data.joseph.address, TOTAL_SUPPLY_18_DECIMALS);
      await testData.tokenDai
        .connect(users[i])
        .approve(data.milton.address, TOTAL_SUPPLY_18_DECIMALS);
    }
  }
};

assertError = async (promise, error) => {
  try {
    await promise;
  } catch (e) {
    expect(
      e.message.includes(error),
      `Expected exception with message ${error} but actual error message: ${e.message}`
    ).to.be.true;
    return;
  }
  expect(false).to.be.true;
};

describe("IporConfigurationRoles", () => {
  let data = null;
  let admin, userOne, userTwo, userThree, liquidityProvider;
  let libraries;

  before(async () => {
    libraries = await getLibraries();
    [admin, userOne, userTwo, userThree, liquidityProvider] =
      await ethers.getSigners();
    data = await prepareData(libraries, [
      admin,
      userOne,
      userTwo,
      userThree,
      liquidityProvider,
    ]);
  });

  it("should provide liquidity and take ipToken - simple case 1 - 18 decimals", async () => {
    //given
    let testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);
    const liquidityAmount = USD_14_000_18DEC;

    const expectedLiquidityProviderStableBalance = BigInt(
      "9986000000000000000000000"
    );
    const expectedLiquidityPoolBalanceMilton = USD_14_000_18DEC;

    //when
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        liquidityAmount,
        params.openTimestamp
      );

    // //then
    const actualIpTokenBalanceSender = BigInt(
      await testData.ipTokenDai.balanceOf(liquidityProvider.address)
    );
    const actualUnderlyingBalanceMilton = BigInt(
      await testData.tokenDai.balanceOf(data.milton.address)
    );
    const actualLiquidityPoolBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(params.asset)
      ).liquidityPool
    );
    const actualUnderlyingBalanceSender = BigInt(
      await testData.tokenDai.balanceOf(liquidityProvider.address)
    );

    expect(
      liquidityAmount,
      `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${liquidityAmount}`
    ).to.be.eql(actualIpTokenBalanceSender);

    expect(
      liquidityAmount,
      `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${liquidityAmount}`
    ).to.be.eql(actualUnderlyingBalanceMilton);

    expect(
      expectedLiquidityPoolBalanceMilton,
      `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolBalanceMilton);

    expect(
      expectedLiquidityProviderStableBalance,
      `Incorrect DAI balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
    ).to.be.eql(actualUnderlyingBalanceSender);
  });

  it("should provide liquidity and take ipToken - simple case 1 - USDT 6 decimals", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["USDT"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "USDT",
      data,
      testData
    );
    await setupTokenUsdtInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsUSDT(userTwo, testData);
    const liquidityAmount = USD_14_000_6DEC;

    const expectedLiquidityProviderStableBalance = BigInt("9986000000000");
    const expectedLiquidityPoolBalanceMilton = USD_14_000_6DEC;

    //when
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        liquidityAmount,
        params.openTimestamp
      );

    //then
    const actualIpTokenBalanceSender = BigInt(
      await testData.ipTokenUsdt.balanceOf(liquidityProvider.address)
    );
    const actualUnderlyingBalanceMilton = BigInt(
      await testData.tokenUsdt.balanceOf(data.milton.address)
    );
    const actualLiquidityPoolBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(params.asset)
      ).liquidityPool
    );
    const actualUnderlyingBalanceSender = BigInt(
      await testData.tokenUsdt.balanceOf(liquidityProvider.address)
    );

    expect(
      liquidityAmount,
      `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${liquidityAmount.address}`
    ).to.be.eql(actualIpTokenBalanceSender);

    expect(
      liquidityAmount,
      `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${liquidityAmount.address}`
    ).to.be.eql(actualUnderlyingBalanceMilton);

    expect(
      expectedLiquidityPoolBalanceMilton,
      `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolBalanceMilton);

    expect(
      expectedLiquidityProviderStableBalance,
      `Incorrect USDT balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
    ).to.be.eql(actualUnderlyingBalanceSender);
  });

  it("should redeem ipToken - simple case 1 - DAI 18 decimals", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);
    const liquidityAmount = USD_14_000_18DEC;
    const withdrawAmount = USD_10_000_18DEC;
    const expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
    const expectedStableBalanceMilton = BigInt("4000000000000000000000");
    const expectedLiquidityProviderStableBalance = BigInt(
      "9996000000000000000000000"
    );
    const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        liquidityAmount,
        params.openTimestamp
      );

    //when
    await data.joseph
      .connect(liquidityProvider)
      .test_redeem(params.asset, withdrawAmount, params.openTimestamp);

    // //then
    const actualIpTokenBalanceSender = BigInt(
      await testData.ipTokenDai.balanceOf(liquidityProvider.address)
    );

    const actualUnderlyingBalanceMilton = BigInt(
      await testData.tokenDai.balanceOf(data.milton.address)
    );
    const actualLiquidityPoolBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(params.asset)
      ).liquidityPool
    );
    const actualUnderlyingBalanceSender = BigInt(
      await testData.tokenDai.balanceOf(liquidityProvider.address)
    );

    expect(
      expectedIpTokenBalanceSender,
      `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
    ).to.be.eql(actualIpTokenBalanceSender);

    expect(
      expectedStableBalanceMilton,
      `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
    ).to.be.eql(actualUnderlyingBalanceMilton);

    expect(
      expectedLiquidityPoolBalanceMilton,
      `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolBalanceMilton);

    expect(
      expectedLiquidityProviderStableBalance,
      `Incorrect DAI balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
    ).to.be.eql(actualUnderlyingBalanceSender);
  });

  it("should redeem ipToken - simple case 1 - USDT 6 decimals", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["USDT"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "USDT",
      data,
      testData
    );
    await setupTokenUsdtInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsUSDT(userTwo, testData);
    const liquidityAmount = USD_14_000_6DEC;
    const withdrawAmount = USD_10_000_6DEC;
    const expectedIpTokenBalanceSender = BigInt("4000000000");
    const expectedStableBalanceMilton = BigInt("4000000000");
    const expectedLiquidityProviderStableBalance = BigInt("9996000000000");
    const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        liquidityAmount,
        params.openTimestamp
      );

    //when
    await data.joseph
      .connect(liquidityProvider)
      .test_redeem(params.asset, withdrawAmount, params.openTimestamp);

    //then
    const actualIpTokenBalanceSender = BigInt(
      await testData.ipTokenUsdt.balanceOf(liquidityProvider.address)
    );

    const actualUnderlyingBalanceMilton = BigInt(
      await testData.tokenUsdt.balanceOf(data.milton.address)
    );
    const actualLiquidityPoolBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(params.asset)
      ).liquidityPool
    );
    const actualUnderlyingBalanceSender = BigInt(
      await testData.tokenUsdt.balanceOf(liquidityProvider.address)
    );

    expect(
      expectedIpTokenBalanceSender,
      `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
    ).to.be.eql(actualIpTokenBalanceSender);

    expect(
      expectedStableBalanceMilton,
      `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
    ).to.be.eql(actualUnderlyingBalanceMilton);

    expect(
      expectedLiquidityPoolBalanceMilton,
      `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolBalanceMilton);

    expect(
      expectedLiquidityProviderStableBalance,
      `Incorrect USDT balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
    ).to.be.eql(actualUnderlyingBalanceSender);
  });

  it("should calculate Exchange Rate when Liquidity Pool Balance and ipToken Total Supply is zero", async () => {
    //given
    let testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);

    const expectedExchangeRate = BigInt("1000000000000000000");

    //when
    const actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        testData.tokenDai.address,
        Math.floor(Date.now() / 1000)
      )
    );

    //then
    expect(
      expectedExchangeRate,
      `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);
  });

  it("should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is NOT zero, DAI 18 decimals", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    const expectedExchangeRate = BigInt("1000000000000000000");

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        USD_14_000_18DEC,
        params.openTimestamp
      );

    //when
    let actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        testData.tokenDai.address,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedExchangeRate,
      `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);
  });

  it("should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is NOT zero, USDT 6 decimals", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["USDT"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "USDT",
      data,
      testData
    );
    await setupTokenUsdtInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsUSDT(userTwo, testData);

    const expectedExchangeRate = BigInt("1000000");

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        USD_14_000_6DEC,
        params.openTimestamp
      );

    //when
    let actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        testData.tokenUsdt.address,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedExchangeRate,
      `Incorrect exchange rate for USDT, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);
  });

  it("should calculate Exchange Rate when Liquidity Pool Balance is zero and ipToken Total Supply is NOT zero", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    const expectedExchangeRate = BigInt("0");

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        USD_10_000_18DEC,
        params.openTimestamp
      );

    //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
    await data.iporConfiguration.setJoseph(userOne.address);
    await testData.miltonStorage
      .connect(userOne)
      .subtractLiquidity(params.asset, USD_10_000_18DEC);
    await data.iporConfiguration.setJoseph(data.joseph.address);

    //when
    const actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        testData.tokenDai.address,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedExchangeRate,
      `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
      expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);
  });

  it("should calculate Exchange Rate, Exchange Rate greater than 1, DAI 18 decimals", async () => {
    //given
    let testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    let expectedExchangeRate = BigInt("1000747756729810568");

    await data.warren
      .connect(userOne)
      .test_updateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        BigInt("40000000000000000000"),
        params.openTimestamp
      );

    //open position to have something in Liquidity Pool
    await data.milton
      .connect(userTwo)
      .test_openPosition(
        params.openTimestamp,
        params.asset,
        BigInt("40000000000000000000"),
        params.slippageValue,
        params.collateralizationFactor,
        params.direction
      );

    //when
    let actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        testData.tokenDai.address,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedExchangeRate,
      `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);
  });

  it("should calculate Exchange Rate, Exchange Rate greater than 1, USDT 6 decimals", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["USDT"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "USDT",
      data,
      testData
    );
    await setupTokenUsdtInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsUSDT(userTwo, testData);

    let expectedExchangeRate = BigInt("1000748");

    await data.warren
      .connect(userOne)
      .test_updateIndex(params.asset, PERCENTAGE_3_6DEC, params.openTimestamp);
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        BigInt("40000000"),
        params.openTimestamp
      );

    //open position to have something in Liquidity Pool
    await data.milton
      .connect(userTwo)
      .test_openPosition(
        params.openTimestamp,
        params.asset,
        BigInt("40000000"),
        params.slippageValue,
        params.collateralizationFactor,
        params.direction
      );

    //when
    let actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        testData.tokenUsdt.address,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedExchangeRate,
      `Incorrect exchange rate for USDT, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);
  });

  it("should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is zero", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    const amount = BigInt("40000000000000000000");
    const expectedExchangeRate = BigInt("1000000000000000000");

    await data.warren
      .connect(userOne)
      .test_updateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(params.asset, amount, params.openTimestamp);

    //open position to have something in Liquidity Pool
    await data.milton
      .connect(userTwo)
      .test_openPosition(
        params.openTimestamp,
        params.asset,
        amount,
        params.slippageValue,
        params.collateralizationFactor,
        params.direction
      );

    await data.joseph
      .connect(liquidityProvider)
      .test_redeem(params.asset, amount, params.openTimestamp);

    //when
    let actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        testData.tokenDai.address,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedExchangeRate,
      `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);
  });

  it("should NOT change Exchange Rate when Liquidity Provider provide liquidity, initial Exchange Rate equal to 1.5", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await testData.iporAssetConfigurationDai.grantRole(
      keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
      admin.address
    );
    await testData.iporAssetConfigurationDai.grantRole(
      keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
      admin.address
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    const amount = BigInt("180000000000000000000");
    await data.warren
      .connect(userOne)
      .test_updateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(params.asset, amount, params.openTimestamp);
    const oldOpeningFeePercentage =
      await testData.iporAssetConfigurationDai.getOpeningFeePercentage();
    await testData.iporAssetConfigurationDai.setOpeningFeePercentage(
      BigInt("600000000000000000")
    );

    //open position to have something in Liquidity Pool
    await data.milton
      .connect(userTwo)
      .test_openPosition(
        params.openTimestamp,
        params.asset,
        amount,
        params.slippageValue,
        params.collateralizationFactor,
        params.direction
      );

    //after this withdraw initial exchange rate is 1,5
    const expectedExchangeRate = BigInt("1714285714285714286");
    const exchangeRateBeforeProvideLiquidity = BigInt(
      await data.milton.calculateExchangeRate(
        params.asset,
        params.openTimestamp
      )
    );
    const expectedIpTokenBalanceForUserThree = BigInt("874999999999999999854");

    // //when
    await data.joseph
      .connect(userThree)
      .test_provideLiquidity(
        params.asset,
        BigInt("1500000000000000000000"),
        params.openTimestamp
      );

    const actualIpTokenBalanceForUserThree = BigInt(
      await testData.ipTokenDai.balanceOf(userThree.address)
    );
    const actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        params.asset,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedIpTokenBalanceForUserThree,
      `Incorrect ipToken Balance for asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
    ).to.be.eql(actualIpTokenBalanceForUserThree);

    expect(
      expectedExchangeRate,
      `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRate}`
    ).to.be.eql(exchangeRateBeforeProvideLiquidity);

    expect(
      expectedExchangeRate,
      `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);

    await testData.iporAssetConfigurationDai.setOpeningFeePercentage(
      oldOpeningFeePercentage
    );
  });

  it("should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5, DAI 18 decimals", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    const amount = BigInt("180000000000000000000");

    await data.warren
      .connect(userOne)
      .test_updateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(params.asset, amount, params.openTimestamp);
    const oldOpeningFeePercentage =
      await testData.iporAssetConfigurationDai.getOpeningFeePercentage();
    await testData.iporAssetConfigurationDai.grantRole(
      keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
      admin.address
    );
    await testData.iporAssetConfigurationDai.grantRole(
      keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
      admin.address
    );
    await testData.iporAssetConfigurationDai.setOpeningFeePercentage(
      BigInt("600000000000000000")
    );

    //open position to have something in Liquidity Pool
    await data.milton
      .connect(userTwo)
      .test_openPosition(
        params.openTimestamp,
        params.asset,
        amount,
        params.slippageValue,
        params.collateralizationFactor,
        params.direction
      );

    //after this withdraw initial exchange rate is 1,5
    const expectedExchangeRate = BigInt("1714285714285714286");
    const exchangeRateBeforeProvideLiquidity = BigInt(
      await data.milton.calculateExchangeRate(
        params.asset,
        params.openTimestamp
      )
    );
    const expectedIpTokenBalanceForUserThree = BigInt("0");

    //when
    await data.joseph
      .connect(userThree)
      .test_provideLiquidity(
        params.asset,
        BigInt("1500000000000000000000"),
        params.openTimestamp
      );
    await data.joseph
      .connect(userThree)
      .test_redeem(
        params.asset,
        BigInt("874999999999999999854"),
        params.openTimestamp
      );

    const actualIpTokenBalanceForUserThree = BigInt(
      await testData.ipTokenDai.balanceOf(userThree.address)
    );
    const actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        params.asset,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedIpTokenBalanceForUserThree,
      `Incorrect ipToken Balance for DAI asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
    ).to.be.eql(actualIpTokenBalanceForUserThree);

    expect(
      expectedExchangeRate,
      `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRate}`
    ).to.be.eql(exchangeRateBeforeProvideLiquidity);

    expect(
      expectedExchangeRate,
      `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);

    await testData.iporAssetConfigurationDai.setOpeningFeePercentage(
      oldOpeningFeePercentage
    );
  });

  it("should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5, USDT 6 decimals", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["USDT"],
      data,
      libraries
    );
    await testData.iporAssetConfigurationUsdt.grantRole(
      keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
      admin.address
    );
    await testData.iporAssetConfigurationUsdt.grantRole(
      keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
      admin.address
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "USDT",
      data,
      testData
    );
    await setupTokenUsdtInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsUSDT(userTwo, testData);

    const amount = BigInt("180000000");
    await data.warren
      .connect(userOne)
      .test_updateIndex(params.asset, PERCENTAGE_3_6DEC, params.openTimestamp);
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(params.asset, amount, params.openTimestamp);
    const oldOpeningFeePercentage =
      await testData.iporAssetConfigurationUsdt.getOpeningFeePercentage();
    await testData.iporAssetConfigurationUsdt.setOpeningFeePercentage(
      BigInt("600000")
    );

    //open position to have something in Liquidity Pool
    await data.milton
      .connect(userTwo)
      .test_openPosition(
        params.openTimestamp,
        params.asset,
        amount,
        params.slippageValue,
        params.collateralizationFactor,
        params.direction
      );

    //after this withdraw initial exchange rate is 1,5
    const expectedExchangeRate = BigInt("1714286");
    const exchangeRateBeforeProvideLiquidity = BigInt(
      await data.milton.calculateExchangeRate(
        params.asset,
        params.openTimestamp
      )
    );
    const expectedIpTokenBalanceForUserThree = BigInt("0");

    //when
    await data.joseph
      .connect(userThree)
      .test_provideLiquidity(
        params.asset,
        BigInt("1500000000"),
        params.openTimestamp
      );
    await data.joseph
      .connect(userThree)
      .test_redeem(params.asset, BigInt("874999854"), params.openTimestamp);

    let actualIpTokenBalanceForUserThree = BigInt(
      await testData.ipTokenUsdt.balanceOf(userThree.address)
    );
    let actualExchangeRate = BigInt(
      await data.milton.calculateExchangeRate(
        params.asset,
        params.openTimestamp
      )
    );

    //then
    expect(
      expectedIpTokenBalanceForUserThree,
      `Incorrect ipToken Balance for USDT asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
             expected: ${expectedIpTokenBalanceForUserThree}`
    ).to.be.eql(actualIpTokenBalanceForUserThree);

    expect(
      expectedExchangeRate,
      `Incorrect exchange rate before providing liquidity for USDT, actual:  ${exchangeRateBeforeProvideLiquidity},
            expected: ${expectedExchangeRate}`
    ).to.be.eql(exchangeRateBeforeProvideLiquidity);

    expect(
      expectedExchangeRate,
      `Incorrect exchange rate after providing liquidity for USDT, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`
    ).to.be.eql(actualExchangeRate);

    await testData.iporAssetConfigurationUsdt.setOpeningFeePercentage(
      oldOpeningFeePercentage
    );
  });

  it("should NOT redeem ipTokens because of empty Liquidity Pool", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        params.totalAmount,
        params.openTimestamp
      );

    //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
    await data.iporConfiguration.setJoseph(userOne.address);
    await testData.miltonStorage
      .connect(userOne)
      .subtractLiquidity(params.asset, params.totalAmount);
    await data.iporConfiguration.setJoseph(data.joseph.address);

    //when
    await assertError(
      //when
      data.joseph
        .connect(liquidityProvider)
        .test_redeem(
          params.asset,
          BigInt("1000000000000000000000"),
          params.openTimestamp
        ),
      //then
      "IPOR_45"
    );
  });

  it("should NOT provide liquidity because of empty Liquidity Pool", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        params.totalAmount,
        params.openTimestamp
      );

    //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
    await data.iporConfiguration.setJoseph(userOne.address);
    await testData.miltonStorage
      .connect(userOne)
      .subtractLiquidity(params.asset, params.totalAmount);
    await data.iporConfiguration.setJoseph(data.joseph.address);

    //when
    await assertError(
      //when
      data.joseph
        .connect(liquidityProvider)
        .test_provideLiquidity(
          params.asset,
          params.totalAmount,
          params.openTimestamp
        ),
      //then
      "IPOR_45"
    );
  });

  it("should NOT redeem ipTokens because redeem value higher than Liquidity Pool Balance", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        params.totalAmount,
        params.openTimestamp
      );

    //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
    await data.iporConfiguration.setJoseph(userOne.address);
    await testData.miltonStorage
      .connect(userOne)
      .subtractLiquidity(params.asset, USD_10_18DEC);
    await data.iporConfiguration.setJoseph(data.joseph.address);

    //when
    await assertError(
      //when
      data.joseph
        .connect(liquidityProvider)
        .test_redeem(params.asset, params.totalAmount, params.openTimestamp),
      //then
      "IPOR_43"
    );
  });

  it("should NOT redeem ipTokens because after redeem Liquidity Pool will be empty", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const params = getStandardDerivativeParamsDAI(userTwo, testData);

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        params.asset,
        params.totalAmount,
        params.openTimestamp
      );

    //when
    await assertError(
      //when
      data.joseph
        .connect(liquidityProvider)
        .test_redeem(params.asset, params.totalAmount, params.openTimestamp),
      //then
      "IPOR_43"
    );
  });

  it("should redeem ipTokens because NO validation for cool off period", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);

    const liquidityAmount = USD_14_000_18DEC;
    const withdrawAmount = USD_10_000_18DEC;

    const timestamp = Math.floor(Date.now() / 1000);

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        testData.tokenDai.address,
        liquidityAmount,
        timestamp
      );

    //when
    await data.joseph
      .connect(liquidityProvider)
      .test_redeem(testData.tokenDai.address, withdrawAmount, timestamp);

    const expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
    const expectedStableBalanceMilton = BigInt("4000000000000000000000");
    const expectedLiquidityProviderStableBalance = BigInt(
      "9996000000000000000000000"
    );
    const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

    //then
    const actualIpTokenBalanceSender = BigInt(
      await testData.ipTokenDai.balanceOf(liquidityProvider.address)
    );

    const actualUnderlyingBalanceMilton = BigInt(
      await testData.tokenDai.balanceOf(data.milton.address)
    );
    const actualLiquidityPoolBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(testData.tokenDai.address)
      ).liquidityPool
    );
    const actualUnderlyingBalanceSender = BigInt(
      await testData.tokenDai.balanceOf(liquidityProvider.address)
    );

    expect(
      expectedIpTokenBalanceSender,
      `Incorrect ipToken balance on user for asset ${testData.tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
    ).to.be.eql(actualIpTokenBalanceSender);

    expect(
      expectedStableBalanceMilton,
      `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
    ).to.be.eql(actualUnderlyingBalanceMilton);

    expect(
      expectedLiquidityPoolBalanceMilton,
      `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolBalanceMilton);

    expect(
      expectedLiquidityProviderStableBalance,
      `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
    ).to.be.eql(actualUnderlyingBalanceSender);
  });

  it("should redeem ipTokens, two times provided liquidity", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const timestamp = Math.floor(Date.now() / 1000);
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        testData.tokenDai.address,
        USD_10_000_18DEC,
        timestamp
      );
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        testData.tokenDai.address,
        USD_10_000_18DEC,
        timestamp
      );

    //when
    await data.joseph
      .connect(liquidityProvider)
      .test_redeem(testData.tokenDai.address, USD_14_000_18DEC, timestamp);

    //then
    const expectedIpTokenBalanceSender = BigInt("6000000000000000000000");
    const expectedStableBalanceMilton = BigInt("6000000000000000000000");
    const expectedLiquidityProviderStableBalance = BigInt(
      "9994000000000000000000000"
    );
    const expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

    const actualIpTokenBalanceSender = BigInt(
      await testData.ipTokenDai.balanceOf(liquidityProvider.address)
    );

    const actualUnderlyingBalanceMilton = BigInt(
      await testData.tokenDai.balanceOf(data.milton.address)
    );
    const actualLiquidityPoolBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(testData.tokenDai.address)
      ).liquidityPool
    );
    const actualUnderlyingBalanceSender = BigInt(
      await testData.tokenDai.balanceOf(liquidityProvider.address)
    );

    expect(
      expectedIpTokenBalanceSender,
      `Incorrect ipToken balance on user for asset ${testData.tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`
    ).to.be.eql(actualIpTokenBalanceSender);

    expect(
      expectedStableBalanceMilton,
      `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`
    ).to.be.eql(actualUnderlyingBalanceMilton);

    expect(
      expectedLiquidityPoolBalanceMilton,
      `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolBalanceMilton);

    expect(
      expectedLiquidityProviderStableBalance,
      `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`
    ).to.be.eql(actualUnderlyingBalanceSender);
  });

  it("should redeem ipDAI, should redeem ipUSDT - simple case 1", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI", "USDT"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "USDT",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupTokenUsdtInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    await setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);

    const liquidityAmountDAI = USD_14_000_18DEC;
    const withdrawAmountDAI = USD_10_000_18DEC;

    const liquidityAmountUSDT = USD_14_000_6DEC;
    const withdrawAmountUSDT = USD_10_000_6DEC;

    const expectedipDAIBalanceSender = BigInt("4000000000000000000000");
    const expectedDAIBalanceMilton = BigInt("4000000000000000000000");
    const expectedLiquidityProviderDAIBalance = BigInt(
      "9996000000000000000000000"
    );
    const expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

    const expectedipUSDTBalanceSender = BigInt("4000000000");
    const expectedUSDTBalanceMilton = BigInt("4000000000");
    const expectedLiquidityProviderUSDTBalance = BigInt("9996000000000");
    const expectedLiquidityPoolUSDTBalanceMilton = expectedUSDTBalanceMilton;

    const timestamp = Math.floor(Date.now() / 1000);

    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        testData.tokenDai.address,
        liquidityAmountDAI,
        timestamp
      );
    await data.joseph
      .connect(liquidityProvider)
      .test_provideLiquidity(
        testData.tokenUsdt.address,
        liquidityAmountUSDT,
        timestamp
      );

    //when
    await data.joseph
      .connect(liquidityProvider)
      .test_redeem(testData.tokenDai.address, withdrawAmountDAI, timestamp);
    await data.joseph
      .connect(liquidityProvider)
      .test_redeem(testData.tokenUsdt.address, withdrawAmountUSDT, timestamp);

    //then
    const actualIpDAIBalanceSender = BigInt(
      await testData.ipTokenDai.balanceOf(liquidityProvider.address)
    );
    const actualDAIBalanceMilton = BigInt(
      await testData.tokenDai.balanceOf(data.milton.address)
    );
    const actualLiquidityPoolDAIBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(testData.tokenDai.address)
      ).liquidityPool
    );
    const actualDAIBalanceSender = BigInt(
      await testData.tokenDai.balanceOf(liquidityProvider.address)
    );

    expect(
      expectedipDAIBalanceSender,
      `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`
    ).to.be.eql(actualIpDAIBalanceSender);

    expect(
      expectedDAIBalanceMilton,
      `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
    ).to.be.eql(actualDAIBalanceMilton);

    expect(
      expectedLiquidityPoolDAIBalanceMilton,
      `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolDAIBalanceMilton);

    expect(
      expectedLiquidityProviderDAIBalance,
      `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`
    ).to.be.eql(actualDAIBalanceSender);

    const actualIpUSDTBalanceSender = BigInt(
      await testData.ipTokenUsdt.balanceOf(liquidityProvider.address)
    );
    const actualUSDTBalanceMilton = BigInt(
      await testData.tokenUsdt.balanceOf(data.milton.address)
    );

    const actualLiquidityPoolUSDTBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(testData.tokenUsdt.address)
      ).liquidityPool
    );
    const actualUSDTBalanceSender = BigInt(
      await testData.tokenUsdt.balanceOf(liquidityProvider.address)
    );

    expect(
      expectedipUSDTBalanceSender,
      `Incorrect ipToken USDT balance on user for asset ${testData.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedipUSDTBalanceSender}`
    ).to.be.eql(actualIpUSDTBalanceSender);

    expect(
      expectedUSDTBalanceMilton,
      `Incorrect USDT balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`
    ).to.be.eql(actualUSDTBalanceMilton);

    expect(
      expectedLiquidityPoolUSDTBalanceMilton,
      `Incorrect USDT Liquidity Pool Balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolUSDTBalanceMilton);

    expect(
      expectedLiquidityProviderUSDTBalance,
      `Incorrect USDT balance on Liquidity Provider for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`
    ).to.be.eql(actualUSDTBalanceSender);
  });

  it("should redeem ipDAI, should redeem ipUSDT, two users - simple case 1", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI", "USDT"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "USDT",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupTokenUsdtInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    await setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);

    const liquidityAmountDAI = USD_14_000_18DEC;
    const withdrawAmountDAI = USD_10_000_18DEC;
    const liquidityAmountUSDT = USD_14_000_6DEC;
    const withdrawAmountUSDT = USD_10_000_6DEC;

    const expectedipDAIBalanceSender = BigInt("4000000000000000000000");
    const expectedDAIBalanceMilton = BigInt("4000000000000000000000");
    const expectedLiquidityProviderDAIBalance = BigInt(
      "9996000000000000000000000"
    );
    const expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

    const expectedipUSDTBalanceSender = BigInt("4000000000");
    const expectedUSDTBalanceMilton = BigInt("4000000000");
    const expectedLiquidityProviderUSDTBalance = BigInt("9996000000000");
    const expectedLiquidityPoolUSDTBalanceMilton = expectedUSDTBalanceMilton;

    const daiUser = userOne;
    const usdtUser = userTwo;

    const timestamp = Math.floor(Date.now() / 1000);

    await data.joseph.connect(daiUser).test_provideLiquidity(
      testData.tokenDai.address,
      liquidityAmountDAI,
      timestamp
    );
    await data.joseph.connect(usdtUser).test_provideLiquidity(
      testData.tokenUsdt.address,
      liquidityAmountUSDT,
      timestamp
    );

    //when
    await data.joseph.connect(daiUser).test_redeem(
      testData.tokenDai.address,
      withdrawAmountDAI,
      timestamp
    );
    await data.joseph.connect(usdtUser).test_redeem(
      testData.tokenUsdt.address,
      withdrawAmountUSDT,
      timestamp
    );

    //then
    const actualIpDAIBalanceSender = BigInt(
      await testData.ipTokenDai.balanceOf(daiUser.address)
    );
    const actualDAIBalanceMilton = BigInt(
      await testData.tokenDai.balanceOf(data.milton.address)
    );
    const actualLiquidityPoolDAIBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(testData.tokenDai.address)
      ).liquidityPool
    );
    const actualDAIBalanceSender = BigInt(
      await testData.tokenDai.balanceOf(daiUser.address)
    );

    expect(
      expectedipDAIBalanceSender,
      `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`
    ).to.be.eql(actualIpDAIBalanceSender);

    expect(
      expectedDAIBalanceMilton,
      `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
    ).to.be.eql(actualDAIBalanceMilton);

    expect(
      expectedLiquidityPoolDAIBalanceMilton,
      `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolDAIBalanceMilton);

    expect(
      expectedLiquidityProviderDAIBalance,
      `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`
    ).to.be.eql(actualDAIBalanceSender);

    const actualIpUSDTBalanceSender = BigInt(
      await testData.ipTokenUsdt.balanceOf(usdtUser.address)
    );
    const actualUSDTBalanceMilton = BigInt(
      await testData.tokenUsdt.balanceOf(data.milton.address)
    );

    const actualLiquidityPoolUSDTBalanceMilton = BigInt(
      await (
        await testData.miltonStorage.balances(testData.tokenUsdt.address)
      ).liquidityPool
    );
    const actualUSDTBalanceSender = BigInt(
      await testData.tokenUsdt.balanceOf(usdtUser.address)
    );

    expect(
      expectedipUSDTBalanceSender,
      `Incorrect ipToken USDT balance on user for asset ${testData.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedipUSDTBalanceSender}`
    ).to.be.eql(actualIpUSDTBalanceSender);

    expect(
      expectedUSDTBalanceMilton,
      `Incorrect USDT balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`
    ).to.be.eql(actualUSDTBalanceMilton);

    expect(
      expectedLiquidityPoolUSDTBalanceMilton,
      `Incorrect USDT Liquidity Pool Balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`
    ).to.be.eql(actualLiquidityPoolUSDTBalanceMilton);

    expect(
      expectedLiquidityProviderUSDTBalance,
      `Incorrect USDT balance on Liquidity Provider for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`
    ).to.be.eql(actualUSDTBalanceSender);
  });

  it("should redeem - Liquidity Provider can transfer tokens to other user, user can redeem tokens", async () => {
    //given
    const testData = await prepareTestData(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      ["DAI"],
      data,
      libraries
    );
    await prepareApproveForUsers(
      [userOne, userTwo, userThree, liquidityProvider],
      "DAI",
      data,
      testData
    );
    await setupTokenDaiInitialValuesForUsers(
      [admin, userOne, userTwo, userThree, liquidityProvider],
      testData
    );
    await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
    const timestamp = Math.floor(Date.now() / 1000);
    await data.joseph.connect(liquidityProvider).test_provideLiquidity(
      testData.tokenDai.address,
      USD_10_400_18DEC,
      timestamp
    );

    await testData.ipTokenDai.connect(liquidityProvider).transfer(userThree.address, USD_10_000_18DEC);

    await data.joseph.connect(userThree).test_redeem(
      testData.tokenDai.address,
      USD_10_000_18DEC,
      timestamp
    );

    const expectedDAIBalanceMilton = BigInt("400000000000000000000");
    const expectedDAIBalanceMiltonLiquidityPool = expectedDAIBalanceMilton;

    const expectedIpDAIBalanceLiquidityProvider = BigInt("400000000000000000000");
    const expectedDAIBalanceLiquidityProvider = BigInt(
      "9989600000000000000000000"
    );

    const expectedIpDAIBalanceUserThree = BigInt("0");
    const expectedDAIBalanceUserThree = BigInt("10010000000000000000000000");

    const actualDAIBalanceMilton = BigInt(
      await testData.tokenDai.balanceOf(data.milton.address)
    );
    const actualDAIBalanceMiltonLiquidityPool = BigInt(
      await (
        await testData.miltonStorage.balances(testData.tokenDai.address)
      ).liquidityPool
    );

    const actualIpDAIBalanceLiquidityProvider = BigInt(
      await testData.ipTokenDai.balanceOf(liquidityProvider.address)
    );
    const actualDAIBalanceLiquidityProvider = BigInt(
      await testData.tokenDai.balanceOf(liquidityProvider.address)
    );

    const actualIpDAIBalanceUserThree = BigInt(
      await testData.ipTokenDai.balanceOf(userThree.address)
    );
    const actualDAIBalanceUserThree = BigInt(
      await testData.tokenDai.balanceOf(userThree.address)
    );

    expect(
      expectedDAIBalanceMilton,
      `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`
    ).to.be.eql(actualDAIBalanceMilton);
    expect(
      expectedDAIBalanceMiltonLiquidityPool,
      `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMiltonLiquidityPool}, expected: ${expectedDAIBalanceMiltonLiquidityPool}`
    ).to.be.eql(actualDAIBalanceMiltonLiquidityPool);

    expect(
      expectedIpDAIBalanceLiquidityProvider,
      `Incorrect ipToken DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceLiquidityProvider}, expected: ${expectedIpDAIBalanceLiquidityProvider}`
    ).to.be.eql(actualIpDAIBalanceLiquidityProvider);
    expect(
      expectedDAIBalanceLiquidityProvider,
      `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceLiquidityProvider}, expected: ${expectedDAIBalanceLiquidityProvider}`
    ).to.be.eql(actualDAIBalanceLiquidityProvider);

    expect(
      expectedIpDAIBalanceUserThree,
      `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceUserThree}, expected: ${expectedIpDAIBalanceUserThree}`
    ).to.be.eql(actualIpDAIBalanceUserThree);
    expect(
      expectedDAIBalanceUserThree,
      `Incorrect DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceUserThree}, expected: ${expectedDAIBalanceUserThree}`
    ).to.be.eql(actualDAIBalanceUserThree);
  });
});
