// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../../contracts/libraries/math/IporMath.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonUsdc.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/itf/ItfJosephUsdt.sol";
import "../../contracts/itf/ItfJosephUsdc.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";

contract MiltonClosingSwaps is Test, TestCommons, DataUtils {
    address internal _buyer;
    address internal _community;
    address internal _liquidator;

    IporProtocol private _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _buyer = _getUserAddress(1);
        _community = _getUserAddress(2);
        _liquidator = _getUserAddress(3);
    }

    function testShouldAddSwapLiquiditatorAsIporOwner() public {
        //given
        _iporProtocol = setupIporProtocolForUsdt();
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
        _iporProtocol = setupIporProtocolForUsdt();
        ItfMilton milton = _iporProtocol.milton;

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_admin);
        milton.removeSwapLiquidator(_liquidator);

        //then
        bool isLiquidator = milton.isSwapLiquidator(_liquidator);
        assertEq(isLiquidator, false);
    }

    function testShouldNotAddLiquiditatorAsNotIporOwner() public {
        //given
        _iporProtocol = setupIporProtocolForUsdt();
        ItfMilton milton = _iporProtocol.milton;

        //when
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(_buyer);
        milton.addSwapLiquidator(_liquidator);
    }

    function testShouldNotRemoveLiquidatorAsNotIporOwner() public {
        //given
        _iporProtocol = setupIporProtocolForUsdt();
        ItfMilton milton = _iporProtocol.milton;

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(_buyer);
        milton.removeSwapLiquidator(_liquidator);
    }

    function testShouldClosePayFixedSwapAsIporOwnerBeforeMaturity() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapAsBuyerInLast24hours() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap20hoursInSeconds = 24 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap20hoursInSeconds);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapAsBuyerInLast20hours() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap20hoursInSeconds = 20 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap20hoursInSeconds);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedAsCommunityInLastOneHour() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap1hourInSeconds = 1 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap1hourInSeconds);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_community);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedAsCommunityInLast30Minutes() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap30MinutesInSeconds = 30 * 60;
        vm.warp(100 + swap28daysInSeconds - swap30MinutesInSeconds);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_community);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedAsLiquidatorAfterMaturity() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds + 1);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldNotClosePayFixedSwapAsBuyerInMoreThanLast24hours() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap25hoursInSeconds = 25 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap25hoursInSeconds);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_332"));
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapAsBuyerAfterMaturity() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds + 1);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 108663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapAsCommunityInMoreThanLastOneHourBelow100Percentage() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap61minutesInSeconds = 61 * 60;
        vm.warp(100 + swap28daysInSeconds - swap61minutesInSeconds);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_331"));
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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds + 1);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_321"));
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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap25hoursInSeconds = 25 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds - swap25hoursInSeconds);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_331"));
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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapAsBuyerInLast24hours() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap20hoursInSeconds = 24 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap20hoursInSeconds);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapAsBuyerInLast20hours() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap20hoursInSeconds = 20 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap20hoursInSeconds);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedAsAnyoneInLastOneHour() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap1hourInSeconds = 1 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap1hourInSeconds);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_community);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedAsAnyoneInLast30Minutes() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap30MinutesInSeconds = 30 * 60;
        vm.warp(100 + swap28daysInSeconds - swap30MinutesInSeconds);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_community);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedAsLiquiditatorAfterMaturity() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds + 1);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldNotCloseReceiveFixedSwapAsBuyerInMoreThanLast24hours() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap25hoursInSeconds = 25 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap25hoursInSeconds);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_332"));
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 10000000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapAsBuyerAfterMaturity() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds + 1);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 108663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapAsAnyoneInMoreThanLastOneHour() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap61minutesInSeconds = 61 * 60;
        vm.warp(100 + swap28daysInSeconds - swap61minutesInSeconds);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_331"));
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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds + 1);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_321"));
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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap25hoursInSeconds = 25 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds - swap25hoursInSeconds);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_331"));
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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 50 * 60;

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityMoreThanOneHourFrom99to100PercentagePayoffBuyerEarned() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);


        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThanOneHourInSeconds = 70 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1299e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);


        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18699537735);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);

    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityLessThanOneHourFrom99to100PercentagePayoffBuyerEanred() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);


        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 40 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);


        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18678901210);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityMoreThan24HoursFrom99to100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);


        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThan24HoursInSeconds = 25 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1344e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThan24HoursInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);


        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18705840689);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityLessThan24HoursFrom99to100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);


        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThan24HoursInSeconds = 23 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1340e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThan24HoursInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18706773261);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18666669656);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByBuyerAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18691669656);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByCommunityBeforeMaturityMoreThanOneHourFrom99HalfTo100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThanOneHourInSeconds = 2 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1305e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18729314136);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByCommunityBeforeMaturityLessThanOneHourFrom99HalfTo100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 50 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18710730283);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThanOneHourInSeconds = 65 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18746039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityLessThanOneHour100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 55 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18746039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityMoreThan24Hours100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThan24HoursInSeconds = 25 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThan24HoursInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18771039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityLessThan24Hours100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThan24HoursInSeconds = 20 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThan24HoursInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18771039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorAfterMaturity100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18746039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerAfterMaturity100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18771039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityAfterMaturity100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_321"));
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityBeforeMaturityLessThanOneHour100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 50 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_321"));
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThanOneHourInSeconds = 70 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_321"));
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByCommunityAfterMaturityFrom99HalfTo100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapPayFixed(1);

        int256 payoff = milton.calculatePayoffPayFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapPayFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter > buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18734889292);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }


    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityMoreThanOneHourFrom99to100PercentagePayoffBuyerLost() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThanOneHourInSeconds = 70 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 81890969);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityLessThanOneHourFrom99to100PercentagePayoffBuyerLost() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 40 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 74598215);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityMoreThan24HoursFrom99to100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThan24HoursInSeconds = 25 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1344e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThan24HoursInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 97443239);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityLessThan24HoursFrom99to100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThan24HoursInSeconds = 23 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1340e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThan24HoursInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 96407048);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 88188831);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByBuyerAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

        asset.approve(address(_iporProtocol.joseph), liquidityAmount);
        _iporProtocol.joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff < minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 113188831);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByCommunityAfterMaturityFrom99HalfTo100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;


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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 12389235);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByCommunityBeforeMaturityMoreThanOneHourFrom99HalfTo100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThanOneHourInSeconds = 2 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1305e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 18583853);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByCommunityBeforeMaturityLessThanOneHourFrom99HalfTo100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 50 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);


        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceAfter < buyerBalanceBefore, true);
        assertEq(buyerBalanceAfter, 39232579);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThanOneHourInSeconds = 65 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 55 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThan24HoursInSeconds = 25 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThan24HoursInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThan24HoursInSeconds = 20 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThan24HoursInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.prank(_liquidator);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

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
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_321"));
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);


        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapByCommunityBeforeMaturityLessThanOneHour100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapLessThanOneHourInSeconds = 50 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapLessThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_321"));
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapByCommunityBeforeMaturityMoreThanOneHour100PercentagePayoff() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swapMoreThanOneHourInSeconds = 70 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + swap28daysInSeconds - swapMoreThanOneHourInSeconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.expectRevert(abi.encodePacked("IPOR_321"));
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff == iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true);
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }


    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityLessThanOneHour() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1000000 * 10 ** 6;
        uint256 totalAmount = 10000 * 10 ** 6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        ///@dev 99% of payoff
        uint256 minPayoffToCloseBeforeMaturityByBuyer = 9767673267326732673268;

        ///@dev 99.5% of payoff
        uint256 minPayoffToCloseBeforeMaturityByCommunity = 9817004950495049504951;

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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + swap28daysInSeconds + 60 * 60);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(1);

        int256 payoff = milton.calculatePayoffReceiveFixed(iporSwap);
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        //when
        vm.prank(_community);
        milton.closeSwapReceiveFixed(1);

        //then
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByBuyer, true);
        assertEq(absPayoff >= minPayoffToCloseBeforeMaturityByCommunity, true);
        assertEq(absPayoff < iporSwap.collateral, true);

        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 communityBalanceAfter = _iporProtocol.asset.balanceOf(_community);
        uint256 liquidatorBalanceAfter = _iporProtocol.asset.balanceOf(_liquidator);

        assertEq(buyerBalanceBefore > buyerBalanceAfter, true);
        assertEq(buyerBalanceAfter, 12389235);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

}
