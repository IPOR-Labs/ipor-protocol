const script = require("../../libs/mocks/0001_deploy_mocks_and_faucet.js");
const func = require("../../libs/json_func.js");
const TestnetFaucet = artifacts.require("TestnetFaucet");

const UsdtTestnetMockedToken = artifacts.require("UsdtTestnetMockedToken");
const UsdcTestnetMockedToken = artifacts.require("UsdcTestnetMockedToken");
const DaiTestnetMockedToken = artifacts.require("DaiTestnetMockedToken");

const MockAUsdc = artifacts.require("MockAUsdc");
const MockAUsdt = artifacts.require("MockAUsdt");
const MockADai = artifacts.require("MockADai");

const MockLendingPoolAave = artifacts.require("MockLendingPoolAave");
const MockProviderAave = artifacts.require("MockProviderAave");
const MockStakedAave = artifacts.require("MockStakedAave");
const AAVEMockedToken = artifacts.require("AAVEMockedToken");
const MockAaveIncentivesController = artifacts.require("MockAaveIncentivesController");
const MockWhitePaper = artifacts.require("MockWhitePaper");
const MockedCOMPToken = artifacts.require("MockedCOMPToken");
const MockComptroller = artifacts.require("MockComptroller");
const MockCDai = artifacts.require("MockCDai");
const MockCUSDT = artifacts.require("MockCUSDT");
const MockCUSDC = artifacts.require("MockCUSDC");

const MockStrategyTestnetUsdt = artifacts.require("MockStrategyTestnetUsdt");
const MockStrategyTestnetUsdc = artifacts.require("MockStrategyTestnetUsdc");
const MockStrategyTestnetDai = artifacts.require("MockStrategyTestnetDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, [
        TestnetFaucet,
        UsdtTestnetMockedToken,
        UsdcTestnetMockedToken,
        DaiTestnetMockedToken,
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
		MockStrategyTestnetDai
    ]);
	await func.updateLastCompletedMigration();
};
