// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DataUtils} from "../utils/DataUtils.sol";

contract JosephAutoRebalance is Test, TestCommons, DataUtils {
    IporProtocolFactory.TestCaseConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;
    
    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
    }

    function testProvideLiquidityAndRebalanceSameTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 10;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        vm.warp(100);

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), userPosition);
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        uint256 stanleyBalanceBefore = _iporProtocol.stanley.totalBalance(
            address(_iporProtocol.milton)
        );
        uint256 miltonBalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));

        _iporProtocol.joseph.addAppointedToRebalance(address(this));

        //when
        _iporProtocol.joseph.rebalance();

        //then
        assertEq(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)),
            stanleyBalanceBefore
        );
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), miltonBalanceBefore);
    }

    function testProvideLiquidityAndRebalanceDifferentTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 10;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        vm.warp(100);

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), userPosition);
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        uint256 stanleyBalanceBefore = _iporProtocol.stanley.totalBalance(
            address(_iporProtocol.milton)
        );
        uint256 miltonBalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));

        _iporProtocol.joseph.addAppointedToRebalance(address(this));

        //when
        vm.warp(101);
        _iporProtocol.joseph.rebalance();

        //then
        assertTrue(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)) != stanleyBalanceBefore
        );
        assertTrue(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)) != miltonBalanceBefore
        );
    }

    function testRebalanceAndProvideLiquiditySameTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 10;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        uint256 expectedMiltonBalance = 150000000000;
        uint256 expectedStanleyBalance = 850000000000000000000000;

        vm.warp(100);

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(_iporProtocol.asset), address(_userOne), 2 * userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), 2 * userPosition);
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        _iporProtocol.joseph.addAppointedToRebalance(address(this));
        _iporProtocol.joseph.rebalance();

        //when
        vm.prank(address(_userOne));
        _iporProtocol.joseph.provideLiquidity(userPosition);

        //then
        assertEq(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedMiltonBalance);
    }

    function testRebalanceAndProvideLiquidityDifferentTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 10;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        uint256 expectedMiltonBalance = 150000000354;
        uint256 expectedStanleyBalance = 850000002004415777544508;

        vm.warp(100);

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(_iporProtocol.asset), address(_userOne), 2 * userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), 2 * userPosition);
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        _iporProtocol.joseph.addAppointedToRebalance(address(this));
        _iporProtocol.joseph.rebalance();

        //when
        vm.warp(105);
        vm.prank(address(_userOne));
        _iporProtocol.joseph.provideLiquidity(userPosition);

        //then
        assertEq(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedMiltonBalance);
    }
}
