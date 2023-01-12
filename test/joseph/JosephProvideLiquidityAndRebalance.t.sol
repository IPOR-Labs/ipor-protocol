// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DataUtils} from "../utils/DataUtils.sol";

contract JosephAutoRebalance is Test, TestCommons, DataUtils {
    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
    }

    function testProvideLiquidityAndRebalanceSameTimestamp() public {
        //given
        IporProtocol memory iporProtocol = setupIporProtocolForUsdt();

        uint256 autoRebalanceThreshold = 10;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        vm.warp(100);

        iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        iporProtocol.asset.approve(address(iporProtocol.joseph), userPosition);
        iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        uint256 stanleyBalanceBefore = iporProtocol.stanley.totalBalance(
            address(iporProtocol.milton)
        );
        uint256 miltonBalanceBefore = iporProtocol.asset.balanceOf(address(iporProtocol.milton));

        iporProtocol.joseph.addAppointedToRebalance(address(this));

        //when
        iporProtocol.joseph.rebalance();

        //then
        assertEq(
            iporProtocol.stanley.totalBalance(address(iporProtocol.milton)),
            stanleyBalanceBefore
        );
        assertEq(iporProtocol.asset.balanceOf(address(iporProtocol.milton)), miltonBalanceBefore);
    }

    function testProvideLiquidityAndRebalanceDifferentTimestamp() public {
        //given
        IporProtocol memory iporProtocol = setupIporProtocolForUsdt();

        uint256 autoRebalanceThreshold = 10;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        vm.warp(100);

        iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        iporProtocol.asset.approve(address(iporProtocol.joseph), userPosition);
        iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        uint256 stanleyBalanceBefore = iporProtocol.stanley.totalBalance(
            address(iporProtocol.milton)
        );
        uint256 miltonBalanceBefore = iporProtocol.asset.balanceOf(address(iporProtocol.milton));

        iporProtocol.joseph.addAppointedToRebalance(address(this));

        //when
        vm.warp(101);
        iporProtocol.joseph.rebalance();

        //then
        assertTrue(
            iporProtocol.stanley.totalBalance(address(iporProtocol.milton)) != stanleyBalanceBefore
        );
        assertTrue(
            iporProtocol.asset.balanceOf(address(iporProtocol.milton)) != miltonBalanceBefore
        );
    }

    function testRebalanceAndProvideLiquiditySameTimestamp() public {
        //given
        IporProtocol memory iporProtocol = setupIporProtocolForUsdt();

        uint256 autoRebalanceThreshold = 10;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        uint256 expectedMiltonBalance = 150000000000;
        uint256 expectedStanleyBalance = 850000000000000000000000;

        vm.warp(100);

        iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(iporProtocol.asset), address(_userOne), 2 * userPosition);

        vm.startPrank(address(_userOne));
        iporProtocol.asset.approve(address(iporProtocol.joseph), 2 * userPosition);
        iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        iporProtocol.joseph.addAppointedToRebalance(address(this));
        iporProtocol.joseph.rebalance();

        //when
        vm.prank(address(_userOne));
        iporProtocol.joseph.provideLiquidity(userPosition);

        //then
        assertEq(
            iporProtocol.stanley.totalBalance(address(iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(iporProtocol.asset.balanceOf(address(iporProtocol.milton)), expectedMiltonBalance);
    }

    function testRebalanceAndProvideLiquidityDifferentTimestamp() public {
        //given
        IporProtocol memory iporProtocol = setupIporProtocolForUsdt();

        uint256 autoRebalanceThreshold = 10;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        uint256 expectedMiltonBalance = 150000000354;
        uint256 expectedStanleyBalance = 850000002004415777544508;

        vm.warp(100);

        iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(iporProtocol.asset), address(_userOne), 2 * userPosition);

        vm.startPrank(address(_userOne));
        iporProtocol.asset.approve(address(iporProtocol.joseph), 2 * userPosition);
        iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        iporProtocol.joseph.addAppointedToRebalance(address(this));
        iporProtocol.joseph.rebalance();

        //when
        vm.warp(105);
        vm.prank(address(_userOne));
        iporProtocol.joseph.provideLiquidity(userPosition);

        //then
        assertEq(
            iporProtocol.stanley.totalBalance(address(iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(iporProtocol.asset.balanceOf(address(iporProtocol.milton)), expectedMiltonBalance);
    }
}
