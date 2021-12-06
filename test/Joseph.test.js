const { expect } = require("chai");
const { ethers } = require("hardhat");
const itParam = require("mocha-param");

const keccak256 = require("keccak256");

const TOTAL_SUPPLY_18_DECIMALS = BigInt("10000000000000000000000000000000000");
const TOTAL_SUPPLY_6_DECIMALS = BigInt("100000000000000000000");
const USER_SUPPLY_18_DECIMALS = BigInt("10000000000000000000000000");
const ZERO = BigInt("0");
const COLLATERALIZATION_FACTOR_18DEC = BigInt("10000000000000000000");
const USD_10_000_18DEC = BigInt("10000000000000000000000");
const USD_14_000_18DEC = BigInt("14000000000000000000000");
const USD_10_000_6DEC = BigInt("10000000000");
const USD_14_000_6DEC = BigInt("14000000000");
const USER_SUPPLY_6_DECIMALS = BigInt("10000000000000");
const PERCENTAGE_3_18DEC = BigInt("30000000000000000");

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

      IporAssetConfigurationDai = await ethers.getContractFactory(
        "IporAssetConfiguration"
      );
      iporAssetConfigurationDai = await IporAssetConfigurationDai.deploy(
        tokenDai.address,
        ipTokenDai.address
      );

      await data.iporConfiguration.setIporAssetConfiguration(
        tokenDai.address,
        await iporAssetConfigurationDai.address
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

    await data.joseph.connect(liquidityProvider).test_provideLiquidity(
      params.asset,
      USD_10_000_18DEC,
      params.openTimestamp
    );

    //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
    await data.iporConfiguration.setJoseph(userOne.address);
    await testData.miltonStorage.connect(userOne).subtractLiquidity(
      params.asset,
      USD_10_000_18DEC
    );
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

  // it.only('should calculate Exchange Rate, Exchange Rate greater than 1, DAI 18 decimals', async () => {
  //   //given
  //   let testData = await prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data, libraries);
  //   await prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
  //   await setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
  //   await setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
  //   const params = getStandardDerivativeParamsDAI(userTwo, testData);

  //   let expectedExchangeRate = BigInt("1000747756729810568");

  //   await data.warren.connect(userOne).test_updateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
  //   await data.joseph.connect(liquidityProvider).test_provideLiquidity(params.asset, BigInt("40000000000000000000"), params.openTimestamp)

  //   //open position to have something in Liquidity Pool
  //   await data.milton.connect(userTwo).test_openPosition(
  //       params.openTimestamp, params.asset, BigInt("40000000000000000000"),
  //       params.slippageValue, params.collateralizationFactor,
  //       params.direction);

    // //when
    // let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(testData.tokenDai.address, params.openTimestamp));

    // //then
    // assert(expectedExchangeRate === actualExchangeRate,
    //     `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
    //     expected: ${expectedExchangeRate}`)
// });


});
