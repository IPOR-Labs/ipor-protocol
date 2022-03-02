const hre = require("hardhat");
import chai from "chai";
const keccak256 = require("keccak256");
import { constants, BigNumber } from "ethers";

const { MaxUint256 } = constants;
import { solidity } from "ethereum-waffle";
import daiAbi from "../../../../artifacts/contracts/assetManagment/mocks/aave/DAIMock.sol/DAIMock.json";
// import daiAbi from "../../../../"
import {
    AaveStrategy,
    CompoundStrategy,
    TestERC20,
    ADAIMock,
    AaveLendingPoolProviderMock,
    AaveLendingPoolCoreMock,
    AaveInterestRateStrategyMockV2,
    AaveStableDebtTokenMock,
    AaveVariableDebtTokenMock,
    AaveLendingPoolMockV2,
    StakedAaveMock,
    AaveIncentivesControllerMock,
    Stanley,
    CDAIMock,
    WhitePaperMock,
    ComptrollerMock,
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

    let aDAI: ADAIMock;
    let AAVE: TestERC20;
    let aaveNewStartegyInstance: AaveStrategy;
    let lendingPool: AaveLendingPoolMockV2;
    let stakedAave: StakedAaveMock;

    let cDAI: CDAIMock;
    let compoundStartegyInstance: CompoundStrategy;
    let _exchangeRate: any;
    let comptroller: ComptrollerMock;
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
    //     const ADAIMockFactory = await hre.ethers.getContractFactory("aDAIMock");

    //     DAI = (await tokenFactory.deploy(
    //         BigNumber.from(2).pow(255)
    //     )) as TestERC20;

    //     aDAI = (await ADAIMockFactory.deploy(
    //         DAI.address,
    //         accounts[0].address
    //     )) as ADAIMock;
    //     DAI.mint(aDAI.address, one.mul(10000));

    //     AAVE = (await tokenFactory.deploy(
    //         BigNumber.from(2).pow(255)
    //     )) as TestERC20;
    //     const stkAAVE = (await tokenFactory.deploy(
    //         BigNumber.from(2).pow(255)
    //     )) as TestERC20;

    //     const aaveLendingPoolProviderMock = await hre.ethers.getContractFactory(
    //         "aaveLendingPoolProviderMock"
    //     );
    //     const aaveLendingPoolCoreMock = await hre.ethers.getContractFactory(
    //         "aaveLendingPoolCoreMock"
    //     );
    //     const aaveInterestRateStrategyMockV2 =
    //         await hre.ethers.getContractFactory(
    //             "AaveInterestRateStrategyMockV2"
    //         );
    //     const aaveStableDebtTokenMock = await hre.ethers.getContractFactory(
    //         "AaveStableDebtTokenMock"
    //     );
    //     const aaveVariableDebtTokenMock = await hre.ethers.getContractFactory(
    //         "AaveVariableDebtTokenMock"
    //     );
    //     const aaveLendingPoolMock = await hre.ethers.getContractFactory(
    //         "aaveLendingPoolMockV2"
    //     );
    //     const stakedAaveMock = await hre.ethers.getContractFactory(
    //         "StakedAaveMock"
    //     );
    //     const aaveIncentivesControllerMock =
    //         await hre.ethers.getContractFactory("AaveIncentivesControllerMock");

    //     const addressProvider =
    //         (await aaveLendingPoolProviderMock.deploy()) as AaveLendingPoolProviderMock;
    //     const lendingPoolCore =
    //         (await aaveLendingPoolCoreMock.deploy()) as AaveLendingPoolCoreMock;
    //     const interestRateStrategyV2 =
    //         (await aaveInterestRateStrategyMockV2.deploy()) as AaveInterestRateStrategyMockV2;
    //     const stableDebtToken = (await aaveStableDebtTokenMock.deploy(
    //         0,
    //         0
    //     )) as AaveStableDebtTokenMock;
    //     const variableDebtToken = (await aaveVariableDebtTokenMock.deploy(
    //         0
    //     )) as AaveVariableDebtTokenMock;
    //     lendingPool = (await aaveLendingPoolMock.deploy(
    //         DAI.address,
    //         aDAI.address
    //     )) as AaveLendingPoolMockV2;
    //     stakedAave = (await stakedAaveMock.deploy(
    //         AAVE.address
    //     )) as StakedAaveMock;
    //     const aaveIncentivesController =
    //         (await aaveIncentivesControllerMock.deploy(
    //             stakedAave.address
    //         )) as AaveIncentivesControllerMock;
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
    //     const CDAIMockFactory = await hre.ethers.getContractFactory("cDAIMock");
    //     COMP = (await tokenFactory.deploy(
    //         BigNumber.from(2).pow(255)
    //     )) as TestERC20;

    //     const whitePaperMock = await hre.ethers.getContractFactory(
    //         "WhitePaperMock"
    //     );
    //     let whitePaperMockInstance =
    //         (await whitePaperMock.deploy()) as WhitePaperMock;

    //     cDAI = (await CDAIMockFactory.deploy(
    //         DAI.address,
    //         accounts[0].address,
    //         whitePaperMockInstance.address
    //     )) as CDAIMock;
    //     DAI.mint(cDAI.address, one.mul(10000));

    //     const ComptrollerMock = await hre.ethers.getContractFactory(
    //         "ComptrollerMock"
    //     );
    //     comptroller = (await ComptrollerMock.deploy(
    //         COMP.address,
    //         cDAI.address
    //     )) as ComptrollerMock;
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
