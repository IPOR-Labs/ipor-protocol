// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract AmmPoolsExchangeRateAndSoap is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            70,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_60_000_18DEC);

        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            26000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertLt(soap, TestConstants.ZERO_INT);
        assertLt(soap * -1, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 1003786189694418343);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            70,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(address(_liquidityProvider));
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_60_000_18DEC);

        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            1 * TestConstants.D16,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 1)
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertLt(soap, TestConstants.ZERO_INT);
        assertLt(soap * -1, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 1012607618867506728);
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            70,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(address(_liquidityProvider));
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_60_000_18DEC);

        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_8_18DEC);

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertLt(soap, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 991151961414231077);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE8;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            70,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_8_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_60_000_18DEC);

        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            1 * TestConstants.D16,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 1)
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertLt(soap, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 991160362216808713);
    }

    function testShouldNotCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            70,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_60_000_18DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );
        vm.stopPrank();

        // BEGIN HACK - subtract liquidity without  burn ipToken
        vm.startPrank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(55000 * TestConstants.D18);
        vm.stopPrank();
        // END HACK - subtract liquidity without  burn ipToken

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_50_18DEC);

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // Notice! |SOAP| > Liquidity Pool Balance
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // when
        vm.expectRevert("IPOR_316");
        _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertGt(soap, int256(balance.liquidityPool));
        assertEq(soap, 8588868952376678505112);
        assertEq(balance.liquidityPool, 5205280043501903214450);
    }

    function testShouldNotCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE9;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            70,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_50_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_60_000_18DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            1 * TestConstants.D16,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 1)
        );
        vm.stopPrank();

        // BEGIN HACK - subtract liquidity without  burn ipToken
        vm.startPrank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(55000 * TestConstants.D18);
        vm.stopPrank();
        // END HACK - subtract liquidity without  burn ipToken

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // Notice! |SOAP| > Liquidity Pool Balance
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // when
        vm.expectRevert("IPOR_316");
        _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertGt(soap, int256(balance.liquidityPool));
        assertEq(soap, 8582988179616174609032);
        assertEq(balance.liquidityPool, 5205280043501903214450);
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE10;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            70,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_50_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_60_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );

        //BEGIN HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!
        vm.startPrank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(55000 * TestConstants.D18);
        vm.stopPrank();
        //END HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // Notice! |SOAP| > Liquidity Pool Balance
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(actualExchangeRate, 236126850257564954);
        assertEq(soap, -8962330971951994053936);
        assertEq(balance.liquidityPool, 5205280043501903214450);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance()
        public
    {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            0,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_60_000_18DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 1)
        );
        vm.stopPrank();

        //BEGIN HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!
        vm.startPrank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(55000 * TestConstants.D18);
        vm.stopPrank();
        //END HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_50_18DEC);

        vm.warp(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // Notice! |SOAP| > Liquidity Pool Balance
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(actualExchangeRate, 236024575572848574);
        assertEq(soap, -8956194490869011225739);
        assertEq(balance.liquidityPool, 5205280043501903214450);
    }

    function testShouldCalculateExchangeRatePositionValuesAndSoapWhenTwoPayFixedSwapsAreClosedAfter60Days() public {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            0,
            5000
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_1_000_000_18DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.USD_100_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.USD_100_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_4_5_18DEC);

        (, , int256 initialSoap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        ExchangeRateAndPnl memory exchangeRateAndPnl;
        exchangeRateAndPnl.initialExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );

        vm.warp(block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        (, , int256 soapAfter28Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        exchangeRateAndPnl.exchangeRateAfter28Days = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );
        exchangeRateAndPnl.pnlValue1After28Days = _iporProtocol.ammSwapsLens.getPnlPayFixed(
            address(_iporProtocol.asset),
            1
        );
        exchangeRateAndPnl.pnlValue2After28Days = _iporProtocol.ammSwapsLens.getPnlPayFixed(
            address(_iporProtocol.asset),
            2
        );

        vm.warp(block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        (, , int256 soapAfter56DaysBeforeClose) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        exchangeRateAndPnl.exchangeRateAfter56DaysBeforeClose = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );
        exchangeRateAndPnl.pnlValue1After56Days = _iporProtocol.ammSwapsLens.getPnlPayFixed(
            address(_iporProtocol.asset),
            1
        );
        exchangeRateAndPnl.pnlValue2After56Days = _iporProtocol.ammSwapsLens.getPnlPayFixed(
            address(_iporProtocol.asset),
            2
        );
        IporTypes.AmmBalancesMemory memory liquidityPoolBalanceBeforeClose = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );
        int256 actualSOAPPlusLiquidityPoolBalanceBeforeClose = int256(liquidityPoolBalanceBeforeClose.liquidityPool) -
            soapAfter56DaysBeforeClose;

        uint256[] memory swapPfIds = new uint256[](2);
        swapPfIds[0] = 1;
        swapPfIds[1] = 2;
        uint256[] memory swapRfIds = new uint256[](0);

        // when
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));

        // then
        (, , int256 soapAfter56DaysAfterClose) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        IporTypes.AmmBalancesMemory memory liquidityPoolBalanceAfterClose = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );
        uint256 exchangeRate56DaysAfterClose = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );
        assertEq(initialSoap, TestConstants.ZERO_INT);
        assertEq(exchangeRateAndPnl.initialExchangeRate, 1086791317829457364, "incorrect initial exchange rate");
        assertEq(
            liquidityPoolBalanceBeforeClose.liquidityPool,
            1086791317829457364359504,
            "incorrect liquidity pool balance before close"
        );
        assertEq(soapAfter28Days, 43537371804356688432372, "incorrect SOAP after 28 days");
        assertEq(
            exchangeRateAndPnl.exchangeRateAfter28Days,
            1043253946025100676,
            "incorrect exchange rate after 28 days"
        );
        assertEq(exchangeRateAndPnl.pnlValue1After28Days, 21768685902178344216186, "incorrect pnl1After28Days");
        assertEq(exchangeRateAndPnl.pnlValue2After28Days, 21768685902178344216186, "incorrect pnl2After28Days");
        assertEq(soapAfter56DaysBeforeClose, 87359096014382786307122, "incorrect SOAP after 56 days before close");
        assertEq(
            exchangeRateAndPnl.exchangeRateAfter56DaysBeforeClose,
            999432221815074578,
            "incorrect exchange rate after 56 days before close"
        );
        assertEq(exchangeRateAndPnl.pnlValue1After56Days, 43679548007191393153560, "incorrect pnlValue1After56Days");
        assertEq(exchangeRateAndPnl.pnlValue2After56Days, 43679548007191393153560, "incorrect pnl2After56Days");
        assertEq(soapAfter56DaysAfterClose, TestConstants.ZERO_INT, "incorrect SOAP after close");
        assertEq(exchangeRate56DaysAfterClose, 999432221815074578, "incorrect exchange rate after close");
        assertEq(
            liquidityPoolBalanceAfterClose.liquidityPool,
            999432221815074578052384,
            "incorrect Liquidity Pool balance after close"
        );
        // SOAP + Liquidity Pool balance before close should be equal to Liquidity Pool balance after close swaps
        assertEq(
            actualSOAPPlusLiquidityPoolBalanceBeforeClose,
            999432221815074578052382,
            "incorrect SOAP + Liquidity Pool balance before close"
        );
    }

    struct ExchangeRateAndPnl {
        uint256 initialExchangeRate;
        uint256 exchangeRateAfter28Days;
        uint256 exchangeRateAfter56DaysBeforeClose;
        int256 pnlValue1After28Days;
        int256 pnlValue2After28Days;
        int256 pnlValue1After56Days;
        int256 pnlValue2After56Days;
    }
}
