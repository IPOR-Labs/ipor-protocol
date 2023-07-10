// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../../contracts/amm/AmmStorage.sol";

contract AmmUnwindSwap is TestCommons {
    address internal _buyer;

    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    event SwapUnwind(
        uint256 indexed swapId,
        int256 swapPnlValueToDate,
        int256 swapUnwindAmount,
        uint256 openingFeeLPAmount,
        uint256 openingFeeTreasuryAmount
    );

    function setUp() public {
        _admin = address(this);
        _buyer = _getUserAddress(1);
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
        _cfg.iporOracleUpdater = _admin;
        _cfg.iporRiskManagementOracleUpdater = _admin;
    }

    function testShouldUnwindPayFixedSimple() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        int256 expectedSwapPnlValueToDate = -254213052927823196669;
        int256 expectedSwapUnwindAmount = -1169961640683441257416;
        uint256 expectedOpeningFeeLpAmount = 29145104043000041192;
        uint256 expectedOpeningFeeTreasuryAmount = 14579841942471256;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(5 days);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 pnlValue = _iporProtocol.ammSwapsLens.getPnlPayFixed(address(_iporProtocol.asset), 1);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            swap.id,
            expectedSwapPnlValueToDate,
            expectedSwapUnwindAmount,
            expectedOpeningFeeLpAmount,
            expectedOpeningFeeTreasuryAmount
        );
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds);

        //then
        assertGe(pnlValue, expectedSwapUnwindAmount);
    }

    function testShouldUnwindPayFixedWhenCloseTwoPositionInDifferentMoment() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        int256 expectedSwapPnlValueToDateOne = -13299129121611997911;
        int256 expectedSwapUnwindAmountOne = -119662692291211422847;
        uint256 expectedOpeningFeeLpAmountOne = 29145104043000041192;
        uint256 expectedOpeningFeeTreasuryAmountOne = 14579841942471256;

        int256 expectedSwapPnlValueToDateTwo = -43675964363614309616;
        int256 expectedSwapUnwindAmountTwo = -70953638111401068366;
        uint256 expectedOpeningFeeLpAmountTwo = 16473326053178158123;
        uint256 expectedOpeningFeeTreasuryAmountTwo = 8240783418298228;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, 2 * totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), 2 * totalAmount);

        vm.prank(_admin);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_2_5_18DEC);

        vm.prank(_buyer);
        uint256 swapIdOne = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_buyer);
        uint256 swapIdTwo = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        AmmTypes.Swap memory swapOne = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        AmmTypes.Swap memory swapTwo = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            2
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);

        //when/then
        vm.warp(5 days);
        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            swapOne.id,
            expectedSwapPnlValueToDateOne,
            expectedSwapUnwindAmountOne,
            expectedOpeningFeeLpAmountOne,
            expectedOpeningFeeTreasuryAmountOne
        );
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds);

        vm.warp(15 days);
        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            swapTwo.id,
            expectedSwapPnlValueToDateTwo,
            expectedSwapUnwindAmountTwo,
            expectedOpeningFeeLpAmountTwo,
            expectedOpeningFeeTreasuryAmountTwo
        );

        swapPfIds[0] = 2;

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds);
    }

    function testShouldUnwindReceiveFixedWhenCloseTwoPositionInDifferentMoment() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        int256 expectedSwapPnlValueToDateOne = -13298938086225219915;
        int256 expectedSwapUnwindAmountOne = -119662325687633544168;
        uint256 expectedOpeningFeeLpAmountOne = 29145104043000041192;
        uint256 expectedOpeningFeeTreasuryAmountOne = 14579841942471256;

        int256 expectedSwapPnlValueToDateTwo = -43673905437684851567;
        int256 expectedSwapUnwindAmountTwo = -70953275080543619994;
        uint256 expectedOpeningFeeLpAmountTwo = 16473326053178158123;
        uint256 expectedOpeningFeeTreasuryAmountTwo = 8240783418298228;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, 2 * totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), 2 * totalAmount);

        vm.prank(_admin);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_2_5_18DEC);

        vm.prank(_buyer);
        uint256 swapIdOne = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_buyer);
        uint256 swapIdTwo = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        AmmTypes.Swap memory swapOne = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        AmmTypes.Swap memory swapTwo = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            2
        );

        //when/then
        vm.warp(5 days);
        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);

        emit SwapUnwind(
            swapOne.id,
            expectedSwapPnlValueToDateOne,
            expectedSwapUnwindAmountOne,
            expectedOpeningFeeLpAmountOne,
            expectedOpeningFeeTreasuryAmountOne
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds);

        vm.warp(15 days);
        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            swapTwo.id,
            expectedSwapPnlValueToDateTwo,
            expectedSwapUnwindAmountTwo,
            expectedOpeningFeeLpAmountTwo,
            expectedOpeningFeeTreasuryAmountTwo
        );

        swapRfIds[0] = 2;

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds);
    }
}
