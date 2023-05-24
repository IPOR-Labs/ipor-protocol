// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";

contract JosephAutoRebalance is Test, TestCommons, DataUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;
    
    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
        _cfg.iporRiskManagementOracleUpdater = _admin;
    }

    function testProvideLiquidityAndRebalanceSameTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 10;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        vm.warp(100);

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), userPosition);
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        uint256 assetManagementBalanceBefore = _iporProtocol.assetManagement.totalBalance(
            address(_iporProtocol.ammTreasury)
        );
        uint256 ammTreasuryBalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));

        _iporProtocol.joseph.addAppointedToRebalance(address(this));

        //when
        _iporProtocol.joseph.rebalance();

        //then
        assertEq(
            _iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)),
            assetManagementBalanceBefore
        );
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), ammTreasuryBalanceBefore);
    }

    function testProvideLiquidityAndRebalanceDifferentTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 10;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        vm.warp(100);

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), userPosition);
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        uint256 assetManagementBalanceBefore = _iporProtocol.assetManagement.totalBalance(
            address(_iporProtocol.ammTreasury)
        );
        uint256 ammTreasuryBalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));

        _iporProtocol.joseph.addAppointedToRebalance(address(this));

        //when
        vm.warp(101);
        _iporProtocol.joseph.rebalance();

        //then
        assertTrue(
            _iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)) != assetManagementBalanceBefore
        );
        assertTrue(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) != ammTreasuryBalanceBefore
        );
    }

    function testRebalanceAndProvideLiquiditySameTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 10;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 150000000000;
        uint256 expectedAssetManagementBalance = 850000000000000000000000;

        vm.warp(100);

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

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
            _iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)),
            expectedAssetManagementBalance
        );
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
    }

    function testRebalanceAndProvideLiquidityDifferentTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 10;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 userPosition = 500000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 150000000354;
        uint256 expectedAssetManagementBalance = 850000002004415777544508;

        vm.warp(100);

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

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
            _iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)),
            expectedAssetManagementBalance
        );
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
    }
}
