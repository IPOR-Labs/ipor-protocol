const hre = require("hardhat");
import chai from "chai";
const keccak256 = require("keccak256");
import { constants, BigNumber } from "ethers";

const { MaxUint256 } = constants;
import { solidity } from "ethereum-waffle";
import daiAbi from "../../../../artifacts/contracts/vault/mocks/aave/MockDAI.sol/MockDAI.json";
// import daiAbi from "../../../../"
import {
    AaveStrategy,
    CompoundStrategy,
    TestERC20,
    MockADAI,
    MockAaveLendingPoolProvider,
    MockAaveLendingPoolCore,
    AaveInterestRateMockStrategyV2,
    MockAaveStableDebtToken,
    MockAaveVariableDebtToken,
    MockAaveLendingPoolV2,
    MockStakedAave,
    MockAaveIncentivesController,
    Stanley,
    MockCDAI,
    MockWhitePaper,
    MockComptroller,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;
// todo: fix it
describe.skip("#Claim Localhost test", () => {
    // let wallet: Wallet
    let one: any;
    let oneRay: any;
    let maxValue: any;
    let stanley: Stanley;
    let DAI: TestERC20;
    let accounts: any;
    let tokenFactory: any;

    let aDAI: MockADAI;
    let AAVE: TestERC20;
    let aaveNewStartegyInstance: AaveStrategy;
    let lendingPool: MockAaveLendingPoolV2;
    let stakedAave: MockStakedAave;

    let cDAI: MockCDAI;
    let compoundStartegyInstance: CompoundStrategy;
    let _exchangeRate: any;
    let comptroller: MockComptroller;
    let COMP: TestERC20;

    if (process.env.FORK_ENABLED != "false") {
        return;
    }

    // beforeEach(async () => {
    //     maxValue =
    //         "115792089237316195423570985008687907853269984665640564039457584007913129639935";
    //     one = BigNumber.from("1000000000000000000");
    //     oneRay = BigNumber.from("1000000000000000000000000000");

    //     accounts = await hre.ethers.getSigners();

    //     tokenFactory = await hre.ethers.getContractFactory("TestERC20");
    //     const MockADAIFactory = await hre.ethers.getContractFactory("MockADAI");

    //     DAI = (await tokenFactory.deploy(
    //         BigNumber.from(2).pow(255)
    //     )) as TestERC20;

    //     aDAI = (await MockADAIFactory.deploy(
    //         DAI.address,
    //         accounts[0].address
    //     )) as MockADAI;
    //     DAI.mint(aDAI.address, one.mul(10000));

    //     AAVE = (await tokenFactory.deploy(
    //         BigNumber.from(2).pow(255)
    //     )) as TestERC20;
    //     const stkAAVE = (await tokenFactory.deploy(
    //         BigNumber.from(2).pow(255)
    //     )) as TestERC20;

    //     const MockAaveLendingPoolProvider = await hre.ethers.getContractFactory(
    //         "MockAaveLendingPoolProvider"
    //     );
    //     const MockAaveLendingPoolCore = await hre.ethers.getContractFactory(
    //         "MockAaveLendingPoolCore"
    //     );
    //     const aaveInterestRateMockStrategyV2 =
    //         await hre.ethers.getContractFactory(
    //             "AaveInterestRateMockStrategyV2"
    //         );
    //     const MockAaveStableDebtToken = await hre.ethers.getContractFactory(
    //         "MockAaveStableDebtToken"
    //     );
    //     const MockAaveVariableDebtToken = await hre.ethers.getContractFactory(
    //         "MockAaveVariableDebtToken"
    //     );
    //     const MockAaveLendingPool = await hre.ethers.getContractFactory(
    //         "MockAaveLendingPoolV2"
    //     );
    //     const MockStakedAave = await hre.ethers.getContractFactory(
    //         "MockStakedAave"
    //     );
    //     const MockAaveIncentivesController =
    //         await hre.ethers.getContractFactory("MockAaveIncentivesController");

    //     const addressProvider =
    //         (await MockAaveLendingPoolProvider.deploy()) as MockAaveLendingPoolProvider;
    //     const lendingPoolCore =
    //         (await MockAaveLendingPoolCore.deploy()) as MockAaveLendingPoolCore;
    //     const interestRateStrategyV2 =
    //         (await aaveInterestRateMockStrategyV2.deploy()) as AaveInterestRateMockStrategyV2;
    //     const stableDebtToken = (await MockAaveStableDebtToken.deploy(
    //         0,
    //         0
    //     )) as MockAaveStableDebtToken;
    //     const variableDebtToken = (await MockAaveVariableDebtToken.deploy(
    //         0
    //     )) as MockAaveVariableDebtToken;
    //     lendingPool = (await MockAaveLendingPool.deploy(
    //         DAI.address,
    //         aDAI.address
    //     )) as MockAaveLendingPoolV2;
    //     stakedAave = (await MockStakedAave.deploy(
    //         AAVE.address
    //     )) as MockStakedAave;
    //     const aaveIncentivesController =
    //         (await MockAaveIncentivesController.deploy(
    //             stakedAave.address
    //         )) as MockAaveIncentivesController;
    //     await stakedAave.transfer(
    //         aaveIncentivesController.address,
    //         one.mul(1000)
    //     );
    //     await AAVE.transfer(stakedAave.address, one.mul(1000));

    //     await addressProvider._setLendingPoolCore(lendingPoolCore.address);
    //     await addressProvider._setLendingPool(lendingPool.address);
    //     await lendingPoolCore._setReserve(interestRateStrategyV2.address);

    //     await lendingPoolCore.setReserveCurrentLiquidityRate(
    //         oneRay.div("100").mul("2")
    //     );
    //     await interestRateStrategyV2._setSupplyRate(oneRay.div("100").mul("2"));
    //     await interestRateStrategyV2._setBorrowRate(oneRay.div("100").mul("3"));

    //     // const stableDebtToken = await StableDebtToken.new(0, 0);
    //     // const variableDebtToken = await VariableDebtToken.new(0);

    //     await lendingPool.setStableDebtTokenAddress(stableDebtToken.address);
    //     await lendingPool.setVariableDebtTokenAddress(
    //         variableDebtToken.address
    //     );
    //     await lendingPool.setInterestRateStrategyAddress(
    //         interestRateStrategyV2.address
    //     );
    //     await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("2"));

    //     aDAI.connect(accounts[0]).transfer(lendingPool.address, one.mul(1000));

    //     const aaveNewStartegy = await hre.ethers.getContractFactory(
    //         "AaveStrategy"
    //     );
    //     aaveNewStartegyInstance = (await aaveNewStartegy.deploy(
    //         DAI.address,
    //         aDAI.address,
    //         addressProvider.address,
    //         stakedAave.address,
    //         aaveIncentivesController.address,
    //         AAVE.address
    //     )) as AaveStrategy;

    //     // Compound
    //     _exchangeRate = BigNumber.from("200000000000000000000000000");
    //     const MockCDAIFactory = await hre.ethers.getContractFactory("MockCDAI");
    //     COMP = (await tokenFactory.deploy(
    //         BigNumber.from(2).pow(255)
    //     )) as TestERC20;

    //     const MockWhitePaper = await hre.ethers.getContractFactory(
    //         "MockWhitePaper"
    //     );
    //     let MockWhitePaperInstance =
    //         (await MockWhitePaper.deploy()) as MockWhitePaper;

    //     cDAI = (await MockCDAIFactory.deploy(
    //         DAI.address,
    //         accounts[0].address,
    //         MockWhitePaperInstance.address
    //     )) as MockCDAI;
    //     DAI.mint(cDAI.address, one.mul(10000));

    //     const MockComptroller = await hre.ethers.getContractFactory(
    //         "MockComptroller"
    //     );
    //     comptroller = (await MockComptroller.deploy(
    //         COMP.address,
    //         cDAI.address
    //     )) as MockComptroller;
    //     await COMP.transfer(comptroller.address, one.mul(1000));

    //     const compoundNewStartegy = await hre.ethers.getContractFactory(
    //         "CompoundStrategy"
    //     );
    //     compoundStartegyInstance = (await compoundNewStartegy.deploy(
    //         DAI.address,
    //         cDAI.address,
    //         comptroller.address,
    //         COMP.address
    //     )) as CompoundStrategy;

    //     const tokenFactoryIvToken = await hre.ethers.getContractFactory(
    //         "IvToken"
    //     );
    //     const ivToken = await tokenFactoryIvToken.deploy("IvToken", "IVT");
    //     const IPORVaultFactory = await hre.ethers.getContractFactory(
    //         "Stanley"
    //     );
    //     stanley = (await IPORVaultFactory.deploy(
    //         DAI.address,
    //         ivToken.address,
    //         aaveNewStartegyInstance.address,
    //         compoundStartegyInstance.address
    //     )) as Stanley;
    //     await aaveNewStartegyInstance.transferOwnership(stanley.address);
    //     await compoundStartegyInstance.transferOwnership(stanley.address);
    // });

    // describe("Claim Aave Governance Token", async () => {
    //     let amount: any;
    //     let bal: any;
    //     let shareTokenInstance: any;
    //     let currentStrategy: any;
    //     beforeEach(async () => {
    //         amount = one.mul(10);
    //         await stanley.grantRole(
    //             keccak256("GOVERNANCE_ROLE"),
    //             accounts[0].address
    //         );
    //         await DAI.connect(accounts[0]).approve(stanley.address, maxValue);
    //         await stanley.grantRole(
    //             keccak256("DEPOSIT_ROLE"),
    //             accounts[0].address
    //         );
    //         await stanley.connect(accounts[0]).deposit(amount);
    //         // const shareToken
    //         // = await stanley.strategyShareToken(
    //         //     currentStrategy
    //         // );
    //         shareTokenInstance = new hre.ethers.Contract(
    //             shareToken,
    //             daiAbi.abi,
    //             accounts[0]
    //         );
    //         bal = await shareTokenInstance.balanceOf(currentStrategy);

    //         //TODO:[mario] one test should contain exactly one path why here is if condition?
    //         if (currentStrategy == compoundStartegyInstance.address) {
    //             const cDaiAmt = BigNumber.from(amount)
    //                 .mul(BigNumber.from("1000000000000000000"))
    //                 .div(_exchangeRate);
    //             expect(bal).to.eq(cDaiAmt);
    //         } else {
    //             expect(bal).to.eq(amount);
    //         }
    //     });

    //     it("Claim aave token", async () => {
    //         let maxValue =
    //             "115792089237316195423570985008687907853269984665640564039457584007913129639935";
    //         const aaveStartegyData =
    //             aaveNewStartegyInstance.interface.encodeFunctionData(
    //                 "beforeClaim",
    //                 [[aaveNewStartegyInstance.address], MaxUint256.toString()]
    //             );
    //         await stanley.grantRole(
    //             keccak256("CLAIM_ROLE"),
    //             accounts[0].address
    //         );
    //         await stanley.beforeClaim(
    //             aaveNewStartegyInstance.address,
    //             aaveStartegyData
    //         );
    //         await stakedAave.setCooldowns();
    //         const bal = await AAVE.balanceOf(accounts[1].address);
    //         const timestamp = Math.floor(Date.now() / 1000) + 86600;

    //         await hre.network.provider.send("evm_setNextBlockTimestamp", [
    //             timestamp,
    //         ]);
    //         await hre.network.provider.send("evm_mine");

    //         await stanley.doClaim(
    //             aaveNewStartegyInstance.address,
    //             accounts[1].address
    //         );
    //         const bal2 = await AAVE.balanceOf(accounts[1].address);
    //         expect(bal2).to.eq(one.mul(100));
    //         //TODO:[mario] add assertions for every token balances before and after (underlying token, share token, aave, stk_aave)  of all actors participating in the test (msg.sender, old strategy, new strategy, vault, staked token)
    //     });
    // });

    // describe("Claim Comp Governance Token", async () => {
    //     let amount: any;
    //     let bal: any;
    //     let shareTokenInstance: any;
    //     let currentStrategy: any;
    //     beforeEach(async () => {
    //         amount = one.mul(10);
    //         await stanley.grantRole(
    //             keccak256("GOVERNANCE_ROLE"),
    //             accounts[0].address
    //         );

    //         await DAI.connect(accounts[0]).approve(stanley.address, maxValue);
    //         await stanley.grantRole(
    //             keccak256("DEPOSIT_ROLE"),
    //             accounts[0].address
    //         );
    //         await stanley.connect(accounts[0]).deposit(amount);
    //         const shareToken = await stanley.strategyShareToken(
    //             currentStrategy
    //         );
    //         shareTokenInstance = new hre.ethers.Contract(
    //             shareToken,
    //             daiAbi.abi,
    //             accounts[0]
    //         );
    //         bal = await shareTokenInstance.balanceOf(currentStrategy);

    //         //TODO:[mario] one test should contain exactly one path why here is if condition?
    //         if (currentStrategy == compoundStartegyInstance.address) {
    //             const cDaiAmt = BigNumber.from(amount)
    //                 .mul(BigNumber.from("1000000000000000000"))
    //                 .div(_exchangeRate);
    //             expect(bal).to.eq(cDaiAmt);
    //         } else {
    //             expect(bal).to.eq(amount);
    //         }
    //     });

    //     it("Claim comp token", async () => {
    //         await comptroller.setAmount(one.mul(100));
    //         await stanley.grantRole(
    //             keccak256("CLAIM_ROLE"),
    //             accounts[0].address
    //         );
    //         await stanley.doClaim(
    //             compoundStartegyInstance.address,
    //             accounts[1].address
    //         );
    //         const bal = await COMP.balanceOf(accounts[1].address);
    //         //TODO:[mario] add assertions for every token balances before and after (underlying token, share token, comp)  of all actors participating in the test (msg.sender, old strategy, new strategy, vault, staked token)
    //         expect(bal).to.eq(one.mul(100));
    //     });
    // });
});
