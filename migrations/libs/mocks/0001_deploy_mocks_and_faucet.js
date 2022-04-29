const keys = require("../json_keys.js");
const func = require("../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (
    deployer,
    _network,
    addresses,
    [
        TestnetFaucet,
        MockTestnetTokenUsdt,
        MockTestnetTokenUsdc,
        MockTestnetTokenDai,
        MockTestnetShareTokenAaveUsdt,
        MockTestnetShareTokenAaveUsdc,
        MockTestnetShareTokenAaveDai,
        MockTestnetShareTokenCompoundUsdt,
        MockTestnetShareTokenCompoundUsdc,
        MockTestnetShareTokenCompoundDai,
        MockTestnetStrategyAaveUsdt,
        MockTestnetStrategyAaveUsdc,
        MockTestnetStrategyAaveDai,
        MockTestnetStrategyCompoundUsdt,
        MockTestnetStrategyCompoundUsdc,
        MockTestnetStrategyCompoundDai,
    ]
) {
    let stableTotalSupply6Decimals = "1000000000000000000";
    let stableTotalSupply18Decimals = "1000000000000000000000000000000";

    await deployer.deploy(MockTestnetTokenUsdt, stableTotalSupply6Decimals);
    const mockedUsdt = await MockTestnetTokenUsdt.deployed();
    await func.update(keys.USDT, mockedUsdt.address);

    await deployer.deploy(MockTestnetTokenUsdc, stableTotalSupply6Decimals);
    const mockedUsdc = await MockTestnetTokenUsdc.deployed();
    await func.update(keys.USDC, mockedUsdc.address);

    await deployer.deploy(MockTestnetTokenDai, stableTotalSupply18Decimals);
    const mockedDai = await MockTestnetTokenDai.deployed();
    await func.update(keys.DAI, mockedDai.address);

    await deployer.deploy(MockTestnetShareTokenAaveUsdt, 0);
    const mockTestnetShareTokenAaveUsdt = await MockTestnetShareTokenAaveUsdt.deployed();
    await func.update(keys.aUSDT, mockTestnetShareTokenAaveUsdt.address);

    await deployer.deploy(MockTestnetShareTokenAaveUsdc, 0);
    const mockTestnetShareTokenAaveUsdc = await MockTestnetShareTokenAaveUsdc.deployed();
    await func.update(keys.aUSDC, mockTestnetShareTokenAaveUsdc.address);

    await deployer.deploy(MockTestnetShareTokenAaveDai, 0);
    const mockTestnetShareTokenAaveDai = await MockTestnetShareTokenAaveDai.deployed();
    await func.update(keys.aDAI, mockTestnetShareTokenAaveDai.address);

    await deployer.deploy(MockTestnetShareTokenCompoundUsdt, 0);
    const mockTestnetShareTokenCompoundUsdt = await MockTestnetShareTokenCompoundUsdt.deployed();
    await func.update(keys.cUSDT, mockTestnetShareTokenCompoundUsdt.address);

    await deployer.deploy(MockTestnetShareTokenCompoundUsdc, 0);
    const mockTestnetShareTokenCompoundUsdc = await MockTestnetShareTokenCompoundUsdc.deployed();
    await func.update(keys.cUSDC, mockTestnetShareTokenCompoundUsdc.address);

    await deployer.deploy(MockTestnetShareTokenCompoundDai, 0);
    const mockTestnetShareTokenCompoundDai = await MockTestnetShareTokenCompoundDai.deployed();
    await func.update(keys.cDAI, mockTestnetShareTokenCompoundDai.address);

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

    const mockTestnetStrategyAaveUsdtProxy = await deployProxy(
        MockTestnetStrategyAaveUsdt,
        [mockedUsdt.address, mockTestnetShareTokenAaveUsdt.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const mockTestnetStrategyAaveUsdtImpl = await erc1967.getImplementationAddress(
        mockTestnetStrategyAaveUsdtProxy.address
    );
    await func.update(keys.AaveStrategyProxyUsdt, mockTestnetStrategyAaveUsdtProxy.address);
    await func.update(keys.AaveStrategyImplUsdt, mockTestnetStrategyAaveUsdtImpl);

    const mockTestnetStrategyAaveUsdcProxy = await deployProxy(
        MockTestnetStrategyAaveUsdc,
        [mockedUsdc.address, mockTestnetShareTokenAaveUsdc.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );
    const mockTestnetStrategyAaveUsdcImpl = await erc1967.getImplementationAddress(
        mockTestnetStrategyAaveUsdcProxy.address
    );
    await func.update(keys.AaveStrategyProxyUsdc, mockTestnetStrategyAaveUsdcProxy.address);
    await func.update(keys.AaveStrategyImplUsdc, mockTestnetStrategyAaveUsdcImpl);

    const mockTestnetStrategyAaveDaiProxy = await deployProxy(
        MockTestnetStrategyAaveDai,
        [mockedDai.address, mockTestnetShareTokenAaveDai.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );
    const mockTestnetStrategyAaveDaiImpl = await erc1967.getImplementationAddress(
        mockTestnetStrategyAaveDaiProxy.address
    );

    await func.update(keys.AaveStrategyProxyDai, mockTestnetStrategyAaveDaiProxy.address);
    await func.update(keys.AaveStrategyImplDai, mockTestnetStrategyAaveDaiImpl);

    const mockTestnetStrategyCompoundUsdtProxy = await deployProxy(
        MockTestnetStrategyCompoundUsdt,
        [mockedUsdt.address, mockTestnetShareTokenCompoundUsdt.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );
    const mockTestnetStrategyCompoundUsdtImpl = await erc1967.getImplementationAddress(
        mockTestnetStrategyCompoundUsdtProxy.address
    );

    await func.update(keys.CompoundStrategyProxyUsdt, mockTestnetStrategyCompoundUsdtProxy.address);
    await func.update(keys.CompoundStrategyImplUsdt, mockTestnetStrategyCompoundUsdtImpl);

    const mockTestnetStrategyCompoundUsdcProxy = await deployProxy(
        MockTestnetStrategyCompoundUsdc,
        [mockedUsdc.address, mockTestnetShareTokenCompoundUsdc.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );
    const mockTestnetStrategyCompoundUsdcImpl = await erc1967.getImplementationAddress(
        mockTestnetStrategyCompoundUsdcProxy.address
    );
    await func.update(keys.CompoundStrategyProxyUsdc, mockTestnetStrategyCompoundUsdcProxy.address);
    await func.update(keys.CompoundStrategyImplUsdc, mockTestnetStrategyCompoundUsdcImpl);

    const mockTestnetStrategyCompoundDaiProxy = await deployProxy(
        MockTestnetStrategyCompoundDai,
        [mockedDai.address, mockTestnetShareTokenCompoundDai.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );
    const mockTestnetStrategyCompoundDaiImpl = await erc1967.getImplementationAddress(
        mockTestnetStrategyCompoundDaiProxy.address
    );

    await func.update(keys.CompoundStrategyProxyDai, mockTestnetStrategyCompoundDaiProxy.address);
    await func.update(keys.CompoundStrategyImplDai, mockTestnetStrategyCompoundDaiImpl);
};
