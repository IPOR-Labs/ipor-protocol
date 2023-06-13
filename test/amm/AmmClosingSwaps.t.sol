// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "contracts/libraries/math/IporMath.sol";
import "contracts/libraries/Constants.sol";
import "contracts/itf/ItfIporOracle.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";

contract AmmClosingSwaps is Test, TestCommons, DataUtils {
    address internal _buyer;
    address internal _community;
    address internal _liquidator;
    address internal _updater;

    BuilderUtils.IporProtocol internal _iporProtocol;
    IporProtocolFactory.IporProtocolConfig private _cfg;

    function setUp() public {
        _admin = address(this);
        _buyer = _getUserAddress(1);
        _community = _getUserAddress(2);
        _liquidator = _getUserAddress(3);
        _updater = _getUserAddress(4);
        vm.warp(100);

        _cfg.iporOracleUpdater = _userOne;
        _cfg.iporRiskManagementOracleUpdater = _updater;
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
        _cfg.openSwapServiceTestCase = BuilderUtils.AmmOpenSwapServiceTestCase.CASE3;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE0;
    }

    function testShouldAddSwapLiquidatorAsIporOwner() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        //when
        vm.prank(_admin);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //then
        bool isLiquidator = _iporProtocol.ammGovernanceLens.isSwapLiquidator(address(_iporProtocol.asset), _liquidator);
        assertEq(isLiquidator, true);
    }

    function testShouldRemoveSwapLiquidatorAsIporOwner() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_admin);
        _iporProtocol.ammGovernanceService.removeSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //then
        bool isLiquidator = _iporProtocol.ammGovernanceLens.isSwapLiquidator(address(_iporProtocol.asset), _liquidator);
        assertEq(isLiquidator, false);
    }

    function testShouldNotAddLiquidatorAsNotIporOwner() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        //when
        vm.expectRevert(abi.encodePacked(IporErrors.CALLER_NOT_OWNER));
        vm.prank(_buyer);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);
    }

    function testShouldNotRemoveLiquidatorAsNotIporOwner() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.expectRevert(abi.encodePacked(IporErrors.CALLER_NOT_OWNER));
        vm.prank(_buyer);
        _iporProtocol.ammGovernanceService.removeSwapLiquidator(address(_iporProtocol.asset), _liquidator);
    }

    function testShouldClosePayFixedSwapAsIporOwnerBeforeMaturity() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);

        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(200);

        //when
        vm.prank(_admin);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_admin, 1);

        //then
        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(uint256(swap.state), uint256(IporTypes.SwapState.INACTIVE));

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapAsBuyerInLast24hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 24 hours);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(uint256(swap.state), uint256(IporTypes.SwapState.INACTIVE));
    }

    function testShouldClosePayFixedSwapAsBuyerInLast20hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 20 hours);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedAsCommunityInLastOneHour() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_community);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 1 hours);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_community);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedAsCommunityInLast30Minutes() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_community);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 30 minutes);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_community);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedAsLiquidatorAfterMaturity() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days + 1 seconds);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldNotClosePayFixedSwapAsLiquidatorInMoreThanLast4hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 4 hours - 1 seconds);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapAsBuyerAfterMaturity() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days + 1 seconds);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 48075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapAsCommunityInMoreThanLastOneHourBelow100Percentage() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapAsAnyoneAfterMaturityBelow100Percentage() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days + 1 seconds);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapAsLiquidatorBeforeMaturityMoreThanOneHour() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapAsIporOwnerBeforeMaturity() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(200);

        //when
        vm.prank(_admin);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_admin, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapAsBuyerInLast24hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 24 hours);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapAsBuyerInLast20hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 20 hours);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedByCommunityInLastOneHour() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_community);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 1 hours);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_community, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_community);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedByCommunityInLast30Minutes() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_community);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 30 minutes);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_community, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_community);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedAsLiquidatorAfterMaturity() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days + 1 seconds);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldNotCloseReceiveFixedSwapAsLiquidatorInMoreThanLast4hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 4 hours - 1 seconds);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapAsBuyerAfterMaturity() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days + 1 seconds);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 48075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapAsAnyoneInMoreThanLastOneHour() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_community, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapAsAnyoneAfterMaturity() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days + 1 seconds);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_community, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapAsLiquidatorBeforeMaturityMoreThenOneHour() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 1 hours - 1);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityLessThanOneHour() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityMoreThanOneHourFrom99to100PercentagePayoffBuyerEarned()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19784498911);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityLessThanOneHourFrom99to100PercentagePayoffBuyerEanred()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19784507113);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityMoreThan24HoursFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1335e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19803662021);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityLessThan24HoursFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1333e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19788838452);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1285e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19775519014);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByBuyerAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1285e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19800519014);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByCommunityBeforeMaturityMoreThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1293e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19807537215);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByCommunityBeforeMaturityLessThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19822904613);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19853848253);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityLessThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19853848253);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityMoreThan24Hours100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19878848253);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityLessThan24Hours100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19878848253);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19853848253);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19878848253);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true, "Failed buyerBalanceBefore > buyerBalanceAfter");
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityBeforeMaturityLessThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true, "Failed buyerBalanceBefore > buyerBalanceAfter");
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true, "Failed buyerBalanceBefore > buyerBalanceAfter");
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByCommunityAfterMaturityFrom99HalfTo100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffPayFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapPayFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19814030604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityMoreThanOneHourFrom99to100PercentagePayoffBuyerLost()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true, "Failed buyerBalanceAfter < buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 69349343, "Incorrect buyerBalanceAfter");
        assertEq(
            liquidatorBalanceAfter - liquidatorBalanceBefore,
            25000000,
            "Incorrect liquidatorBalanceAfter - liquidatorBalanceBefore"
        );
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityLessThanOneHourFrom99to100PercentagePayoffBuyerLost()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1288e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 84699729);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityMoreThan24HoursFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1335e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 100186232);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityLessThan24HoursFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1335e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 100177744);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1285e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 78329240);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByBuyerAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1285e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff < minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff < minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 103329240);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByCommunityAfterMaturityFrom99HalfTo100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 39817650);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByCommunityBeforeMaturityMoreThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 30951874);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByCommunityBeforeMaturityLessThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        vm.warp(100);

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 30943640);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityLessThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1380e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityMoreThan24Hours100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 25000000);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityLessThan24Hours100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 25000000);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _liquidator);

        //when
        vm.prank(_liquidator);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByBuyerAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_buyer, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 25000000);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapByCommunityAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true, "Failed buyerBalanceBefore > buyerBalanceAfter");
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapByCommunityBeforeMaturityLessThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true, "Failed buyerBalanceBefore > buyerBalanceAfter");
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapByCommunityBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_liquidator, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff == swap.collateral, true, "Failed absPayoff == swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true, "Failed buyerBalanceBefore > buyerBalanceAfter");
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityLessThanOneHour() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(_iporProtocol.router), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage
        );

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        int256 payoff = _iporProtocol.ammSwapsLens.getPayoffReceiveFixed(address(_iporProtocol.asset), 1);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        _iporProtocol.ammCloseSwapService.closeSwapReceiveFixedUsdt(_community, 1);

        //then
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByBuyer,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByBuyer"
        );
        assertEq(
            absPayoff >= minPayoffToCloseBeforeMaturityByCommunity,
            true,
            "Failed absPayoff >= minPayoffToCloseBeforeMaturityByCommunity"
        );
        assertEq(absPayoff < swap.collateral, true, "Failed absPayoff < swap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true, "Failed buyerBalanceBefore > buyerBalanceAfter");
        assertEq(buyerBalanceAfter, 39817650);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }
}
