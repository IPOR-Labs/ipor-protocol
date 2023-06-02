// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "contracts/interfaces/types/AmmFacadeTypes.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/interfaces/IAmmTreasuryFacadeDataProvider.sol";
import "../utils/builder/BuilderUtils.sol";

contract AmmTreasuryFacadeDataProviderTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);

        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;

        _ammCfg.iporOracleUpdater = _userOne;
        _ammCfg.iporRiskManagementOracleUpdater = _userOne;
        _ammCfg.ammTreasuryDaiTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _ammCfg.ammTreasuryUsdtTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _ammCfg.ammTreasuryUsdcTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
    }

    function prepareAmmTreasuryFacadeDataProvider(IporProtocolFactory.Amm memory amm)
        public
        returns (IAmmTreasuryFacadeDataProvider)
    {
        _iporProtocolFactory.setupUsers(_cfg, amm.usdt);
        _iporProtocolFactory.setupUsers(_cfg, amm.usdc);
        _iporProtocolFactory.setupUsers(_cfg, amm.dai);

        address[] memory assets = new address[](3);
        assets[0] = address(amm.dai.asset);
        assets[1] = address(amm.usdt.asset);
        assets[2] = address(amm.usdc.asset);

        address[] memory ammTreasurys = new address[](3);
        ammTreasurys[0] = address(amm.dai.ammTreasury);
        ammTreasurys[1] = address(amm.usdt.ammTreasury);
        ammTreasurys[2] = address(amm.usdc.ammTreasury);

        address[] memory ammStorages = new address[](3);
        ammStorages[0] = address(amm.dai.ammStorage);
        ammStorages[1] = address(amm.usdt.ammStorage);
        ammStorages[2] = address(amm.usdc.ammStorage);

        address[] memory josephs = new address[](3);
        josephs[0] = address(amm.dai.joseph);
        josephs[1] = address(amm.usdt.joseph);
        josephs[2] = address(amm.usdc.joseph);

        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = getAmmTreasuryFacadeDataProvider(
            address(amm.iporOracle),
            assets,
            ammTreasurys,
            ammStorages,
            josephs
        );
        return ammTreasuryFacadeDataProvider;
    }

    function testShouldListConfigurationUsdtUsdcDai() public {
        //given
        _ammCfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _ammCfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE6;

        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);

        amm.usdt.spreadModel.setCalculateQuotePayFixed(0);
        amm.usdc.spreadModel.setCalculateQuotePayFixed(0);
        amm.dai.spreadModel.setCalculateQuotePayFixed(0);

        amm.usdt.spreadModel.setCalculateQuoteReceiveFixed(0);
        amm.usdc.spreadModel.setCalculateQuoteReceiveFixed(0);
        amm.dai.spreadModel.setCalculateQuoteReceiveFixed(0);

        amm.usdt.spreadModel.setCalculateSpreadPayFixed(1 * TestConstants.D16_INT);
        amm.usdc.spreadModel.setCalculateSpreadPayFixed(1 * TestConstants.D16_INT);
        amm.dai.spreadModel.setCalculateSpreadPayFixed(1 * TestConstants.D16_INT);

        amm.usdt.spreadModel.setCalculateSpreadReceiveFixed(1 * TestConstants.D16_INT);
        amm.usdc.spreadModel.setCalculateSpreadReceiveFixed(1 * TestConstants.D16_INT);
        amm.dai.spreadModel.setCalculateSpreadReceiveFixed(1 * TestConstants.D16_INT);
        vm.startPrank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.usdt.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        amm.iporOracle.itfUpdateIndex(address(amm.usdc.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.stopPrank();

        vm.startPrank(_liquidityProvider);
        amm.usdt.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);
        amm.usdc.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);
        vm.stopPrank();

        // when
        AmmFacadeTypes.AssetConfiguration[] memory assetConfigurations = ammTreasuryFacadeDataProvider.getConfiguration();
        // then
        for (uint256 i; i < assetConfigurations.length; ++i) {
            assertEq(TestConstants.LEVERAGE_18DEC, assetConfigurations[i].minLeverage);
            assertEq(TestConstants.LEVERAGE_1000_18DEC, assetConfigurations[i].maxLeveragePayFixed);
            assertEq(TestConstants.LEVERAGE_1000_18DEC, assetConfigurations[i].maxLeverageReceiveFixed);
            assertEq(3 * TestConstants.D14, assetConfigurations[i].openingFeeRate);
            assertEq(TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC, assetConfigurations[i].iporPublicationFeeAmount);
            assertEq(
                TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
                assetConfigurations[i].liquidationDepositAmount
            );
            assertEq(1 * TestConstants.D16_INT, assetConfigurations[i].spreadPayFixed);
            assertEq(1 * TestConstants.D16_INT, assetConfigurations[i].spreadReceiveFixed);
            assertEq(8 * TestConstants.D17, assetConfigurations[i].maxLpCollateralRatio);
            assertEq(48 * TestConstants.D16, assetConfigurations[i].maxLpCollateralRatioPayFixed);
            assertEq(48 * TestConstants.D16, assetConfigurations[i].maxLpCollateralRatioReceiveFixed);
        }
    }

    function testShouldListCorrectNumberItemsUsdtUsdcDai() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);

        amm.usdt.spreadModel.setCalculateSpreadPayFixed(6 * TestConstants.D16_INT);
        amm.usdc.spreadModel.setCalculateSpreadPayFixed(6 * TestConstants.D16_INT);
        amm.dai.spreadModel.setCalculateSpreadPayFixed(6 * TestConstants.D16_INT);

        vm.startPrank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.usdt.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        amm.iporOracle.itfUpdateIndex(address(amm.usdc.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.stopPrank();

        vm.prank(_liquidityProvider);
        amm.usdt.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);
        amm.usdc.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);
        vm.stopPrank();

        // when
        vm.startPrank(_userTwo);
        amm.usdt.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        amm.usdc.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
        amm.dai.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

//        (uint256 totalCountUsdt, AmmFacadeTypes.IporSwap[] memory swapsUsdt) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.usdt.asset),
//            TestConstants.ZERO,
//            50
//        );
//        (uint256 totalCountUsdc, AmmFacadeTypes.IporSwap[] memory swapsUsdc) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.usdc.asset),
//            TestConstants.ZERO,
//            50
//        );
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            TestConstants.ZERO,
//            50
//        );
        vm.stopPrank();

        // then
//        assertEq(totalCountUsdt, 1);
//        assertEq(totalCountUsdc, 1);
//        assertEq(totalCountDai, 1);
//        assertEq(swapsUsdt.length, 1);
//        assertEq(swapsUsdc.length, 1);
//        assertEq(swapsDai.length, 1);
//        assertEq(swapsUsdt.length, totalCountUsdt);
//        assertEq(swapsUsdc.length, totalCountUsdc);
//        assertEq(swapsDai.length, totalCountDai);
//        assertEq(3, totalCountUsdt + totalCountUsdc + totalCountDai);
//        assertEq(3, swapsUsdt.length + swapsUsdc.length + swapsDai.length);
    }

    function testShouldFailWhenPageSizeIsZero() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);
        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);
        vm.prank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);

        // when
        vm.prank(_userTwo);
//        vm.expectRevert(abi.encodePacked("IPOR_009"));
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            0,
//            0
//        );
        // then
//        assertEq(totalCountDai, TestConstants.ZERO);
//        assertEq(swapsDai.length, TestConstants.ZERO);
//        assertEq(swapsDai.length, totalCountDai);
    }

    function testShouldFailWhenPageSizeIsGreaterThanFifty() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);
        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);
        vm.prank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);

        // when
        vm.prank(_userTwo);
//        vm.expectRevert(abi.encodePacked("IPOR_010"));
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            0,
//            51
//        );
        // then
//        assertEq(totalCountDai, TestConstants.ZERO);
//        assertEq(swapsDai.length, TestConstants.ZERO);
//        assertEq(swapsDai.length, totalCountDai);
    }

    function testShouldReceiveEmptyListOfSwaps() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);
        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);
        vm.prank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        vm.prank(_userTwo);
        // when
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            0,
//            10
//        );
        // then
//        assertEq(totalCountDai, TestConstants.ZERO);
//        assertEq(swapsDai.length, TestConstants.ZERO);
//        assertEq(swapsDai.length, totalCountDai);
    }

    function testShouldReceiveEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwap() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);
        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);
        vm.prank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        // when
        vm.prank(_userTwo);
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            10,
//            10
//        );
        // then
//        assertEq(totalCountDai, TestConstants.ZERO);
//        assertEq(swapsDai.length, TestConstants.ZERO);
//        assertEq(swapsDai.length, totalCountDai);
    }

    function testShouldReceiveLimitedSwapArray() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);
        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);

        amm.usdt.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.usdt.spreadModel.setCalculateQuoteReceiveFixed(20000047708334227);
        amm.usdc.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.usdc.spreadModel.setCalculateQuoteReceiveFixed(20000047708334227);
        amm.dai.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.dai.spreadModel.setCalculateQuoteReceiveFixed(20000047708334227);
        vm.prank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        iterateOpenSwapsPayFixed(
            _userTwo,
            amm.dai.ammTreasury,
            11,
            TestConstants.USD_100_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.prank(_userTwo);
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            0,
//            10
//        );
        // then
//        assertEq(totalCountDai, 11);
//        assertEq(swapsDai.length, 10);
    }

    function testShouldReceiveLimitedSwapArrayWithOffset() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);
        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);

        amm.usdt.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.usdt.spreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        amm.usdc.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.usdc.spreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        amm.dai.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.dai.spreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        vm.prank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        iterateOpenSwapsPayFixed(
            _userTwo,
            amm.dai.ammTreasury,
            22,
            TestConstants.USD_100_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.prank(_userTwo);
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            10,
//            10
//        );
        // then
//        assertEq(totalCountDai, 22);
//        assertEq(swapsDai.length, 10);
    }

    function testShouldReceiveRestOfSwapsOnly() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);
        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);

        amm.usdt.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.usdt.spreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        amm.usdc.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.usdc.spreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        amm.dai.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.dai.spreadModel.setCalculateQuoteReceiveFixed(20000023854167113);
        vm.prank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        iterateOpenSwapsPayFixed(
            _userTwo,
            amm.dai.ammTreasury,
            22,
            TestConstants.USD_100_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        // when
        vm.prank(_userTwo);
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            20,
//            10
//        );
        // then
//        assertEq(totalCountDai, 22);
//        assertEq(swapsDai.length, 2);
    }

    function testShouldReceiveEmptyListOfSwapsWhenOffsetIsEqualToNumberOfSwaps() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);
        IAmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProvider = prepareAmmTreasuryFacadeDataProvider(amm);

        amm.usdt.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.usdt.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        amm.usdc.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.usdc.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        amm.dai.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        amm.dai.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        vm.prank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(amm.dai.asset), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        amm.dai.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        iterateOpenSwapsPayFixed(
            _userTwo,
            amm.dai.ammTreasury,
            20,
            TestConstants.USD_100_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.prank(_userTwo);
//        (uint256 totalCountDai, AmmFacadeTypes.IporSwap[] memory swapsDai) = ammTreasuryFacadeDataProvider.getMySwaps(
//            address(amm.dai.asset),
//            20,
//            10
//        );
        // then
//        assertEq(totalCountDai, 20);
//        assertEq(0, swapsDai.length);
    }
}
