const hre = require("hardhat");
import chai from "chai";
import { BigNumber, Signer } from "ethers";

import { solidity } from "ethereum-waffle";
import {
    StrategyAave,
    ERC20,
    DaiMockedToken,
    MockStakedAave,
    MockAaveIncentivesController,
} from "../../../../types";

import { assertError } from "../../../utils/AssertUtils";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";
const totalSupply6Decimals = "100000000000000000000";
const TC_1000_USD_18DEC = BigNumber.from("1000000000000000000000");

describe("AAVE strategy pauseable", () => {
    let strategy: StrategyAave;
    let DAI: DaiMockedToken;
    let USDC: DaiMockedToken;
    let USDT: DaiMockedToken;
    let aDAI: ERC20;
    let aUSDC: ERC20;
    let aUSDT: ERC20;
    let AAVE: ERC20;
    let stakedAave: MockStakedAave;
    let admin: Signer, userOne: Signer, userTwo: Signer;
    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        // #################################################################################
        // #####################        USDC / aUSDC     ###################################
        // #################################################################################

        const UsdcMockedToken = await hre.ethers.getContractFactory("UsdcMockedToken");
        USDC = await UsdcMockedToken.deploy(totalSupply6Decimals, 6);
        const AUSDCFactory = await hre.ethers.getContractFactory("MockAUsdc");
        aUSDC = await AUSDCFactory.deploy();

        // #################################################################################
        // #####################        USDT / aUSDT     ###################################
        // #################################################################################

        const UsdtMockedToken = await hre.ethers.getContractFactory("UsdtMockedToken");
        USDT = await UsdtMockedToken.deploy(totalSupply6Decimals, 6);
        const AUSDTFactory = await hre.ethers.getContractFactory("MockAUsdt");
        aUSDT = await AUSDTFactory.deploy();

        // #################################################################################
        // #####################         DAI / aDAI      ###################################
        // #################################################################################

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        DAI = (await DAIFactory.deploy(stableTotalSupply18Decimals, 18)) as DaiMockedToken;

        const ADAIFactory = await hre.ethers.getContractFactory("MockADai");
        aDAI = await ADAIFactory.deploy();

        AAVE = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        await AAVE.deployed();

        // #################################################################################
        // #####################         AAVE MOCK       ###################################
        // #################################################################################

        const MockLendingPoolAave = await hre.ethers.getContractFactory("MockLendingPoolAave");
        const lendingPool = await MockLendingPoolAave.deploy(
            DAI.address,
            aDAI.address,
            BigNumber.from("100000"),
            USDC.address,
            aUSDC.address,
            BigNumber.from("200000"),
            USDT.address,
            aUSDT.address,
            BigNumber.from("200000")
        );

        const MockProviderAave = await hre.ethers.getContractFactory("MockProviderAave");
        const addressProvider = await MockProviderAave.deploy(lendingPool.address);

        const MockStakedAave = await hre.ethers.getContractFactory("MockStakedAave");
        stakedAave = (await MockStakedAave.deploy(AAVE.address)) as MockStakedAave;
        const MockAaveIncentivesController = await hre.ethers.getContractFactory(
            "MockAaveIncentivesController"
        );

        const aaveIncentivesController = (await MockAaveIncentivesController.deploy(
            stakedAave.address
        )) as MockAaveIncentivesController;

        // #################################################################################
        // #####################         AAVE Strategy   ###################################
        // #################################################################################

        const StrategyAaveInstance = await hre.ethers.getContractFactory("StrategyAave");

        strategy = await upgrades.deployProxy(StrategyAaveInstance, [
            USDT.address,
            aUSDT.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ]);
    });

    it("Should be able to pause contract when sender is owner", async () => {
        //given
        //when
        await strategy.pause();
        //then
        expect(await strategy.paused()).to.be.true;
    });

    it("Should be able to unpause contract when sender is owner", async () => {
        //given
        await strategy.pause();
        expect(await strategy.paused()).to.be.true;
        //when
        await strategy.unpause();
        //then
        expect(await strategy.paused()).to.be.false;
    });

    it("Should not be able to unpause contract when sender is not owner", async () => {
        //given
        await strategy.pause();
        expect(await strategy.paused()).to.be.true;
        //when
        await assertError(
            strategy.connect(userOne).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        //when
        await strategy.pause();
        //then
        expect(await strategy.paused()).to.be.true;
        await strategy.getAsset();
        await strategy.getShareToken();
        await strategy.balanceOf();
        await strategy.getAsset();
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        //when
        await strategy.pause();
        //then
        const mockAddress = await userTwo.getAddress();

        expect(await strategy.paused()).to.be.true;
        await assertError(strategy.deposit(TC_1000_USD_18DEC), "Pausable: paused");
        await assertError(strategy.withdraw(TC_1000_USD_18DEC), "Pausable: paused");
        await assertError(strategy.beforeClaim(), "Pausable: paused");
        await assertError(strategy.doClaim(), "Pausable: paused");
        await assertError(strategy.setStanley(mockAddress), "Pausable: paused");
        await assertError(strategy.setTreasuryManager(mockAddress), "Pausable: paused");
        await assertError(strategy.setTreasury(mockAddress), "Pausable: paused");
        await assertError(strategy.setStkAave(mockAddress), "Pausable: paused");
    });
});
