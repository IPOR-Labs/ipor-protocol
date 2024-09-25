// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";

contract AmmSoapAndCloseSwapTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;

        _ammCfg.iporOracleUpdater = _userOne;
    }

    function testShouldOpenSwapWhenFixedInterestRateEqualOneIsHigherThanZero() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);

        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        /// @dev for this particular case fixedInterestRate is higher than 0 (is equal 1)
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), 1111516737937797));

        vm.startPrank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        uint256[] memory pfSwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);

        swapIds[0] = swap1;
        vm.prank(_userTwo);
        _iporProtocol.ammCloseSwapServiceUsdt.closeSwapsUsdt(_userOne, pfSwapIds, swapIds,getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));
    }

    function testShouldCloseSwapEvenIfAverageInterestRateIsEqualZero() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC));

        vm.startPrank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), 0));

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();
        vm.warp(30 days);

        uint256[] memory pfSwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;

        //when
        vm.prank(_userTwo);
        (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.ammCloseSwapServiceUsdt.closeSwapsUsdt(_userOne, pfSwapIds, swapIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));

        //then
        assertEq(closedReceiveFixedSwaps.length, 1, "closedPayFixedSwaps.length");
    }

    function testShouldCloseSwapEvenIfIncorrectHypotheticalInterestCase1() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC));

        vm.startPrank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), 1424808299999999));

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();
        vm.warp(30 days);

        uint256[] memory pfSwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;

        //when
        vm.prank(_userTwo);
        (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.ammCloseSwapServiceUsdt.closeSwapsUsdt(_userOne, pfSwapIds, swapIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));

        //then
        assertEq(closedReceiveFixedSwaps.length, 1, "closedPayFixedSwaps.length");
    }

    function testShouldCloseSwapEvenIfIncorrectHypotheticalInterestCase2() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC));

        vm.startPrank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), 1424808195385802));

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();
        vm.warp(30 days);

        uint256[] memory pfSwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;

        //when
        vm.prank(_userTwo);
        (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.ammCloseSwapServiceUsdt.closeSwapsUsdt(_userOne, pfSwapIds, swapIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));

        //then
        assertEq(closedReceiveFixedSwaps.length, 1, "closedPayFixedSwaps.length");
    }

    function testShouldPassUsdt() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC));

        vm.startPrank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), 1424808295385802));

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        uint256[] memory pfSwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;
        vm.warp(118 days);

        //when
        vm.prank(_userTwo);
        (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.ammCloseSwapServiceUsdt.closeSwapsUsdt(_userOne, pfSwapIds, swapIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));

        //then
        assertEq(closedReceiveFixedSwaps.length, 1, "closedPayFixedSwaps.length");
    }

    function testShouldPassDai() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC));

        vm.startPrank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), 1424808295385802));

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        uint256[] memory pfSwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;
        vm.warp(118 days);

        //when
        vm.prank(_userTwo);
        (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.ammCloseSwapServiceDai.closeSwapsDai(_userOne, pfSwapIds, swapIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));

        //then
        assertEq(closedReceiveFixedSwaps.length, 1, "closedPayFixedSwaps.length");
    }

    function testShouldCloseSwapEvenIfTotalNotionalMultiplyAverageInterestRateIsTooLow() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_1_18DEC));

        vm.startPrank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), 0));

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_100_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset),RECEIVE_FIXED)
        );
        vm.stopPrank();
        vm.warp(30 days);

        uint256[] memory pfSwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;

        //when
        vm.prank(_userTwo);
        (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        ) = _iporProtocol.ammCloseSwapServiceUsdt.closeSwapsUsdt(_userOne, pfSwapIds, swapIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));

        //then
        assertEq(closedPayFixedSwaps.length, 0, "closedPayFixedSwaps.length");
        assertEq(closedReceiveFixedSwaps.length, 1, "closedReceiveFixedSwaps.length");
    }
}
