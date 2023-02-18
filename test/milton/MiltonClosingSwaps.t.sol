// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
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
    address internal _anyone;
    address internal _liquidator;

    IporProtocol private _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _buyer = _getUserAddress(1);
        _anyone = _getUserAddress(2);
        _liquidator = _getUserAddress(3);
    }

    function testShouldTresholdForAnyoneBeLowerThanForBuyer() public {}

    function testShouldAddLiquiditatorAsIporOwner() public {}

    function testShouldRemoveLiquidatorAsIporOwner() public {}

    function testShouldNotAddLiquiditatorAsNotIporOwner() public {}

    function testShouldNotRemoveLiquidatorAsNotIporOwner() public {}

    function testShouldClosePayFixedSwaoAsIporOwnerBeforeMaturity() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10**6;
        uint256 totalAmount = 10000 * 10**6;
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

        uint256 liquidityAmount = 1000000 * 10**6;
        uint256 totalAmount = 10000 * 10**6;
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

    function testShouldClosePayFixedAsAnyoneInLastOneHour() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10**6;
        uint256 totalAmount = 10000 * 10**6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_anyone);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap1hourInSeconds = 1 * 60 * 60;
        vm.warp(100 + swap28daysInSeconds - swap1hourInSeconds);

        //when
        vm.prank(_anyone);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_anyone);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedAsAnyoneInLast30Minutes() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10**6;
        uint256 totalAmount = 10000 * 10**6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceBefore = _iporProtocol.asset.balanceOf(_anyone);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;
        uint256 swap30MinutesInSeconds = 30 * 60;
        vm.warp(100 + swap28daysInSeconds - swap30MinutesInSeconds);

        //when
        vm.prank(_anyone);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);
        uint256 anyoneBalanceAfter = _iporProtocol.asset.balanceOf(_anyone);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedAsLiquiditatorAfterMaturity() public {
        //given
        vm.warp(100);

        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1000000 * 10**6;
        uint256 totalAmount = 10000 * 10**6;
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

        uint256 swap28daysInSeconds = 28 * 24 * 60 * 60;

        vm.warp(100 + swap28daysInSeconds + 1);

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

    function testShouldNotCloseAsBuyerInMoreThanLast24hours() public {}

    function testShouldNotCloseAsBuyerAfterMaturity() public {}

    function testShouldNotCloseAsAnyoneInMoreThanLastOneHour() public {}

    function testShouldNotCloseAsAnyoneAfterMaturity() public {}

    function testShouldNotCloseAsLiquiditatorBeforeMaturity() public {}
}
