// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../../contracts/libraries/math/IporMath.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";

contract MiltonClosingSwaps is Test, TestCommons, DataUtils {
    address internal _buyer;
    address internal _community;
    address internal _liquidator;
    address internal _updater;

    IporProtocolBuilder.IporProtocol internal _iporProtocol;
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
    }

    function testShouldAddSwapLiquidatorAsIporOwner() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        ItfMilton milton = _iporProtocol.milton;

        //when
        vm.prank(_admin);
        milton.addSwapLiquidator(_liquidator);

        //then
        bool isLiquidator = milton.isSwapLiquidator(_liquidator);
        assertEq(isLiquidator, true);
    }

    function testShouldRemoveSwapLiquidatorAsIporOwner() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        ItfMilton milton = _iporProtocol.milton;

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_admin);
        milton.removeSwapLiquidator(_liquidator);

        //then
        bool isLiquidator = milton.isSwapLiquidator(_liquidator);
        assertEq(isLiquidator, false);
    }

    function testShouldNotAddLiquidatorAsNotIporOwner() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        ItfMilton milton = _iporProtocol.milton;

        //when
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(_buyer);
        milton.addSwapLiquidator(_liquidator);
    }

    function testShouldNotRemoveLiquidatorAsNotIporOwner() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        ItfMilton milton = _iporProtocol.milton;

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(_buyer);
        milton.removeSwapLiquidator(_liquidator);
    }

    function testShouldClosePayFixedSwapAsIporOwnerBeforeMaturity() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(200);

        //when
        vm.prank(_admin);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapAsBuyerInLast24hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 24 hours);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 73075873 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapAsBuyerInLast20hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 20 hours);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_community);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 1 hours);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_community);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 30 minutes);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days + 1 seconds);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 4 hours - 1 seconds);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days + 1 seconds);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days + 1 seconds);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(200);

        //when
        vm.prank(_admin);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 24 hours);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 20 hours);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_community);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 1 hours);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_community);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 30 minutes);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days + 1 seconds);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 4 hours - 1 seconds);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days + 1 seconds);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days + 1 seconds);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 1 hours - 1);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY));
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19773896175);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityLessThanOneHourFrom99to100PercentagePayoffBuyerEanred()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19773904328);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityMoreThan24HoursFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1344e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19821186272);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityLessThan24HoursFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1340e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19791821904);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19765117870);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByBuyerAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19790117870);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByCommunityBeforeMaturityMoreThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1305e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19849934569);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByCommunityBeforeMaturityLessThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19811923556);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true, "Failed buyerBalanceAfter > buyerBalanceBefore");
        assertEq(buyerBalanceAfter, 19841382938);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityMoreThanOneHourFrom99to100PercentagePayoffBuyerLost()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC; // TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC; //TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(buyerBalanceAfter, 79952078, "Incorrect buyerBalanceAfter");
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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(buyerBalanceAfter, 79943926);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityMoreThan24HoursFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1344e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 82661982);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityLessThan24HoursFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1340e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 112026350);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 88730383);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByBuyerAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 113730383);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByCommunityAfterMaturityFrom99HalfTo100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 12465316);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByCommunityBeforeMaturityMoreThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1305e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 3913684);
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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 41924697);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR));
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff == iporSwap.collateral, true, "Failed absPayoff == iporSwap.collateral");

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
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = TestConstants.TC_COLLATERAL_100LEV_99PERCENT_18DEC;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = TestConstants.TC_COLLATERAL_100LEV_99_5PERCENT_18DEC;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceBefore = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

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
        assertEq(absPayoff < iporSwap.collateral, true, "Failed absPayoff < iporSwap.collateral");

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true, "Failed buyerBalanceBefore > buyerBalanceAfter");
        assertEq(buyerBalanceAfter, 12465316);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }
}
