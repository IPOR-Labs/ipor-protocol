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

contract MiltonAutoUpdateIndex is Test, TestCommons, DataUtils {
    event IporIndexUpdate(
        address asset,
        uint256 indexValue,
        uint256 quasiIbtPrice,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance,
        uint256 updateTimestamp
    );

    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
        _cfg.iporOracleUpdater = _admin;
        _cfg.iporRiskManagementOracleUpdater = _admin;
    }

    function testOpenAndCloseSwapPayFixedUsdtAndAutoUpdateIndex() public {
        //given
        vm.warp(100);
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        iporOracle.addUpdater(address(milton));

        milton.setAutoUpdateIporIndexThreshold(1);

        uint256 liquidityAmount = 1000000 * 10**6;
        uint256 totalAmount = 10000 * 10**6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        asset.approve(address(milton), totalAmount);

        joseph.provideLiquidity(liquidityAmount);

        uint256 myBalanceBefore = _iporProtocol.asset.balanceOf(address(this));

        //then
        vm.expectEmit(true, true, false, false);
        emit IporIndexUpdate(address(asset), 1, 31536000000000000000000000, 1, 1, 100);

        //when
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);
        milton.closeSwapPayFixed(1);

        //then
        uint256 myBalanceAfter = _iporProtocol.asset.balanceOf(address(this));
        assertEq(myBalanceBefore - myBalanceAfter, 48075873);
    }

    function testOpenAndCloseSwapReceiveFixedUsdtAndAutoUpdateIndex() public {
        //given
        vm.warp(100);
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        iporOracle.addUpdater(address(milton));

        milton.setAutoUpdateIporIndexThreshold(1);

        uint256 liquidityAmount = 1000000 * 10**6;
        uint256 totalAmount = 10000 * 10**6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        asset.approve(address(milton), totalAmount);

        joseph.provideLiquidity(liquidityAmount);

        uint256 myBalanceBefore = _iporProtocol.asset.balanceOf(address(this));

        //then
        vm.expectEmit(true, true, false, false);
        emit IporIndexUpdate(address(asset), 1, 31536000000000000000000000, 1, 1, 100);

        //when
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 myBalanceAfter = _iporProtocol.asset.balanceOf(address(this));
        assertEq(myBalanceBefore - myBalanceAfter, 48075873);
    }

    function testOpenAndCloseSwapPayFixedDaiAndAutoUpdateIndex() public {
        //given
        vm.warp(100);
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        iporOracle.addUpdater(address(milton));

        milton.setAutoUpdateIporIndexThreshold(1);

        uint256 liquidityAmount = 1000000 * 10**18;
        uint256 totalAmount = 10000 * 10**18;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        asset.approve(address(milton), totalAmount);

        joseph.provideLiquidity(liquidityAmount);

        uint256 myBalanceBefore = _iporProtocol.asset.balanceOf(address(this));

        //then
        vm.expectEmit(true, true, true, true);
        emit IporIndexUpdate(address(asset), 1, 31536000000000000000000000, 1, 1, 100);

        //when
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);
        milton.closeSwapPayFixed(1);

        //then
        uint256 myBalanceAfter = _iporProtocol.asset.balanceOf(address(this));

        assertEq(myBalanceBefore - myBalanceAfter, 48075873362445411054, "incorrect balance");
    }

    function testOpenAndCloseSwapReceiveFixedDaiAndAutoUpdateIndex() public {
        //given
        vm.warp(100);
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;
        ItfIporOracle iporOracle = _iporProtocol.iporOracle;

        iporOracle.addUpdater(address(milton));

        milton.setAutoUpdateIporIndexThreshold(1);

        uint256 liquidityAmount = 1000000 * 10**18;
        uint256 totalAmount = 10000 * 10**18;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        asset.approve(address(milton), totalAmount);

        joseph.provideLiquidity(liquidityAmount);

        uint256 myBalanceBefore = _iporProtocol.asset.balanceOf(address(this));

        //then
        vm.expectEmit(true, true, true, true);
        emit IporIndexUpdate(address(asset), 1, 31536000000000000000000000, 1, 1, 100);

        //when
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 myBalanceAfter = _iporProtocol.asset.balanceOf(address(this));
        assertEq(myBalanceBefore - myBalanceAfter, 48075873362445411054);
    }
}
