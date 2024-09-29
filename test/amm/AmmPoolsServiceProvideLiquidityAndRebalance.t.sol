// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "../TestCommons.sol";

contract AmmPoolsServiceProvideLiquidityAndRebalanceTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
    }

    function testProvideLiquidityAndRebalanceSameTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint32 autoRebalanceThreshold = 10;
        uint16 ammTreasuryAssetManagementRatio = 1500;
        uint256 userPosition = 500_000 * 1e6;

        vm.warp(100);

        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio
        );

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.router), userPosition);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userOne, userPosition);
        vm.stopPrank();

        uint256 assetManagementBalanceBefore = _iporProtocol.assetManagement.maxWithdraw(address(_iporProtocol.ammTreasury));
        uint256 ammTreasuryBalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));

        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), address(this));

        //when
        _iporProtocol.ammPoolsService.rebalanceBetweenAmmTreasuryAndAssetManagement(address(_iporProtocol.asset));

        //then
        assertEq(_iporProtocol.assetManagement.maxWithdraw(address(_iporProtocol.ammTreasury)), assetManagementBalanceBefore);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), ammTreasuryBalanceBefore);

        assertEq(userPosition, _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)) + _iporProtocol.assetManagement.maxWithdraw(address(_iporProtocol.ammTreasury)));
    }

    function testProvideLiquidityAndRebalanceDifferentTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint32 autoRebalanceThreshold = 10;
        uint16 ammTreasuryAssetManagementRatio = 1500;
        uint256 userPosition = 500_000 * 1e6;

        vm.warp(block.timestamp + 100);

        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio
        );

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.router), userPosition);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userOne, userPosition);
        vm.stopPrank();

        uint256 assetManagementBalanceBefore = _iporProtocol.assetManagement.maxWithdraw(address(_iporProtocol.ammTreasury));
        uint256 ammTreasuryBalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));

        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), address(this));

        //when
        vm.warp(block.timestamp + 1 days);
        _iporProtocol.ammPoolsService.rebalanceBetweenAmmTreasuryAndAssetManagement(address(_iporProtocol.asset));

        //then
        assertTrue(
            _iporProtocol.assetManagement.maxWithdraw(address(_iporProtocol.ammTreasury)) == assetManagementBalanceBefore,
            "incorrect asset management balance"
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)),
            ammTreasuryBalanceBefore,
            "incorrect amm treasury balance"
        );
    }

    function testRebalanceAndProvideLiquiditySameTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint32 autoRebalanceThreshold = 10;
        uint16 ammTreasuryAssetManagementRatio = 1500;
        uint256 userPosition = 500_000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 150_000 * 1e6;
        uint256 expectedAssetManagementBalance = 850_000 * 1e6;

        vm.warp(100);

        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio
        );

        deal(address(_iporProtocol.asset), address(_userOne), 2 * userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.router), 2 * userPosition);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userOne, userPosition);
        vm.stopPrank();

        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), address(this));
        _iporProtocol.ammPoolsService.rebalanceBetweenAmmTreasuryAndAssetManagement(address(_iporProtocol.asset));

        //when
        vm.prank(address(_userOne));
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userOne, userPosition);

        //then

        assertEq(
            _iporProtocol.assetManagement.maxWithdraw(address(_iporProtocol.ammTreasury)),
            expectedAssetManagementBalance,
            "incorrect asset management balance"
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)),
            expectedAmmTreasuryBalance,
            "incorrect amm treasury balance"
        );
    }

    function testRebalanceAndProvideLiquidityDifferentTimestamp() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint32 autoRebalanceThreshold = 10;
        uint16 ammTreasuryAssetManagementRatio = 1500;
        uint256 userPosition = 500000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 150000000000;
        uint256 expectedAssetManagementBalance = 850000000000;

        vm.warp(100);

        _iporProtocol.ammGovernanceService.setAmmPoolsParams(
            address(_iporProtocol.asset),
            1000000000,
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio
        );

        deal(address(_iporProtocol.asset), address(_userOne), 2 * userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.router), 2 * userPosition);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userOne, userPosition);
        vm.stopPrank();

        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), address(this));
        _iporProtocol.ammPoolsService.rebalanceBetweenAmmTreasuryAndAssetManagement(address(_iporProtocol.asset));

        //when
        vm.warp(105);
        vm.prank(address(_userOne));
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userOne, userPosition);

        //then
        assertEq(_iporProtocol.assetManagement.maxWithdraw(address(_iporProtocol.ammTreasury)), expectedAssetManagementBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
    }
}
