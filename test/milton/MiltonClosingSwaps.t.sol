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
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";

contract MiltonClosingSwaps is Test, TestCommons, DataUtils {
    address internal _buyer;
    address internal _community;
    address internal _liquidator;

    IporProtocolBuilder.IporProtocol internal _iporProtocol;
    IporProtocolFactory.TestCaseConfig private _cfg;

    function setUp() public {
        _admin = address(this);
        _buyer = _getUserAddress(1);
        _community = _getUserAddress(2);
        _liquidator = _getUserAddress(3);
        vm.warp(100);

        _cfg.iporOracleUpdater = _userOne;
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        ItfMilton milton = _iporProtocol.milton;

        //when
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(_buyer);
        milton.addSwapLiquidator(_liquidator);
    }

    function testShouldNotRemoveLiquidatorAsNotIporOwner() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        ItfMilton milton = _iporProtocol.milton;

        milton.addSwapLiquidator(_liquidator);

        //when
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(_buyer);
        milton.removeSwapLiquidator(_liquidator);
    }

    function testShouldClosePayFixedSwapAsIporOwnerBeforeMaturity() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapAsBuyerInLast24hours() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapAsBuyerInLast20hours() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldClosePayFixedAsCommunityInLastOneHour() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedAsCommunityInLast30Minutes() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedAsLiquidatorAfterMaturity() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }


    function testShouldNotClosePayFixedSwapAsLiquidatorInMoreThanLast4hours() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 108663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapAsCommunityInMoreThanLastOneHourBelow100Percentage()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapAsBuyerInLast24hours() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapAsBuyerInLast20hours() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366 - 25000000);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedByCommunityInLastOneHour() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedByCommunityInLast30Minutes() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(anyoneBalanceAfter - anyoneBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedAsLiquidatorAfterMaturity() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

      function testShouldNotCloseReceiveFixedSwapAsLiquidatorInMoreThanLast4hours() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 108663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapAsAnyoneInMoreThanLastOneHour() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 133663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityMoreThanOneHourFrom99to100PercentagePayoffBuyerEarned()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18674521911);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityLessThanOneHourFrom99to100PercentagePayoffBuyerEanred()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18674529204);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityMoreThan24HoursFrom99to100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18719460559);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityLessThan24HoursFrom99to100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18693193926);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorAfterMaturityFrom99to100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18666669656);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByBuyerAfterMaturityFrom99to100PercentagePayoff() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18691669656);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByCommunityBeforeMaturityMoreThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18742538786);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByCommunityBeforeMaturityLessThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18708537670);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityMoreThanOneHour100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18746039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorBeforeMaturityLessThanOneHour100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18746039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityMoreThan24Hours100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18771039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerBeforeMaturityLessThan24Hours100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18771039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByLiquidatorAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18746039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByBuyerAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18771039604);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityAfterMaturity100PercentagePayoff() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceBefore > buyerBalanceAfter,
            true,
            "Failed buyerBalanceBefore > buyerBalanceAfter"
        );
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityBeforeMaturityLessThanOneHour100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceBefore > buyerBalanceAfter,
            true,
            "Failed buyerBalanceBefore > buyerBalanceAfter"
        );
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotClosePayFixedSwapByCommunityBeforeMaturityMoreThanOneHour100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceBefore > buyerBalanceAfter,
            true,
            "Failed buyerBalanceBefore > buyerBalanceAfter"
        );
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldClosePayFixedSwapByCommunityAfterMaturityFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

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

        assertEq(
            buyerBalanceAfter > buyerBalanceBefore,
            true,
            "Failed buyerBalanceAfter > buyerBalanceBefore"
        );
        assertEq(buyerBalanceAfter, 18734889292);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityMoreThanOneHourFrom99to100PercentagePayoffBuyerLost()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 79464103);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityLessThanOneHourFrom99to100PercentagePayoffBuyerLost()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1295e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 79456000);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityMoreThan24HoursFrom99to100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1344e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 82310050);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityLessThan24HoursFrom99to100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1340e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 111495197);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorAfterMaturityFrom99to100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 88188831);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByBuyerAfterMaturityFrom99to100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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
        uint256 liquidatorBalanceBefore = _iporProtocol.asset.balanceOf(_liquidator);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1290e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 113188831);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByCommunityAfterMaturityFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 12389235);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByCommunityBeforeMaturityMoreThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1305e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 3889798);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByCommunityBeforeMaturityLessThanOneHourFrom99HalfTo100PercentagePayoff()
        public
    {
        //given
        vm.warp(100);

        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        assertEq(buyerBalanceAfter, 41668816);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityMoreThanOneHour100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityLessThanOneHour100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityMoreThan24Hours100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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

    function testShouldCloseReceiveFixedSwapByBuyerBeforeMaturityLessThan24Hours100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 24 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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

    function testShouldNotCloseReceiveFixedSwapByCommunityAfterMaturity100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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

        assertEq(
            buyerBalanceBefore > buyerBalanceAfter,
            true,
            "Failed buyerBalanceBefore > buyerBalanceAfter"
        );
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapByCommunityBeforeMaturityLessThanOneHour100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours + 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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

        assertEq(
            buyerBalanceBefore > buyerBalanceAfter,
            true,
            "Failed buyerBalanceBefore > buyerBalanceAfter"
        );
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldNotCloseReceiveFixedSwapByCommunityBeforeMaturityMoreThanOneHour100PercentagePayoff()
        public
    {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1400e14);

        vm.warp(100 + 28 days - 1 hours - 1 seconds);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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

        assertEq(
            buyerBalanceBefore > buyerBalanceAfter,
            true,
            "Failed buyerBalanceBefore > buyerBalanceAfter"
        );
        assertEq(buyerBalanceAfter, 0);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 0);
    }

    function testShouldCloseReceiveFixedSwapByLiquidatorBeforeMaturityLessThanOneHour() public {
        //given
        _iporProtocol =_iporProtocolFactory.getUsdtInstance(_cfg);
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

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

        vm.prank(_userOne);
        iporOracle.updateIndex(address(asset), 1300e14);

        vm.warp(100 + 28 days + 1 hours);

        IporTypes.IporSwapMemory memory iporSwap = _iporProtocol.miltonStorage.getSwapReceiveFixed(
            1
        );

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

        assertEq(
            buyerBalanceBefore > buyerBalanceAfter,
            true,
            "Failed buyerBalanceBefore > buyerBalanceAfter"
        );
        assertEq(buyerBalanceAfter, 12389235);
        assertEq(liquidatorBalanceAfter - liquidatorBalanceBefore, 0);
        assertEq(communityBalanceAfter - communityBalanceBefore, 25000000);
    }
}
