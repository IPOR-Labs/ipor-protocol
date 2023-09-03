// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {TestCommons} from "../TestCommons.sol";

import "../utils/builder/AssetManagementBuilder.sol";
import "../mocks/assetManagement/MockStrategy.sol";
import "../mocks/tokens/MockTestnetToken.sol";
import "../utils/builder/AssetBuilder.sol";
import "../../contracts/vault/AssetManagementDai.sol";


contract AssetManagementMaxApyStrategyTest is TestCommons {
    AssetBuilder internal _assetBuilder = new AssetBuilder(address(this));
    AssetManagementBuilder internal _assetManagementBuilder = new AssetManagementBuilder(address(this));

    AssetManagementDai internal _assetManagementDai;
    MockStrategy internal _strategyAaveDai;
    MockStrategy internal _strategyCompoundDai;
    MockStrategy internal _strategyDsrDai;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _assetBuilder.withDAI();
        MockTestnetToken asset = _assetBuilder.build();

        _strategyAaveDai = new MockStrategy();
        _strategyAaveDai.setAsset(address(asset));
        _strategyAaveDai.setShareToken(address(asset));

        _strategyCompoundDai = new MockStrategy();
        _strategyCompoundDai.setAsset(address(asset));
        _strategyCompoundDai.setShareToken(address(asset));

        _strategyDsrDai = new MockStrategy();
        _strategyDsrDai.setAsset(address(asset));
        _strategyDsrDai.setShareToken(address(asset));

        AmmTreasury ammTreasury = new AmmTreasury(address(asset), 18, address(asset), address(asset), address(asset));

        _assetManagementDai = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(asset))
            .withStrategyAave(address(_strategyAaveDai))
            .withStrategyCompound(address(_strategyCompoundDai))
            .withStrategyDsr(address(_strategyDsrDai))
            .withAmmTreasury(address(ammTreasury))
            .build();
    }

    function testShouldSelectAaveStrategy() public {
        // given
        _strategyAaveDai.setApy(100000);
        _strategyCompoundDai.setApy(99999);
        // when
        AssetManagementCore.StrategyData[] memory sortedStrategies = _assetManagementDai.getMaxApyStrategy();
        // then
        assertEq(sortedStrategies[2].strategy, address(_strategyAaveDai));
    }

    function testShouldSelectAaveStrategyWhenAaveApyEqualsCompoundApy() public {
        // given
        _strategyAaveDai.setApy(10);
        _strategyCompoundDai.setApy(10);
        // when
        AssetManagementCore.StrategyData[] memory sortedStrategies = _assetManagementDai.getMaxApyStrategy();
        // then
        assertEq(sortedStrategies[2].strategy, address(_strategyAaveDai));
    }

    function testShouldSelectCompoundStrategy() public {
        // given
        _strategyAaveDai.setApy(1000);
        _strategyCompoundDai.setApy(99999);
        // when
        AssetManagementCore.StrategyData[] memory sortedStrategies = _assetManagementDai.getMaxApyStrategy();
        // then
        assertEq(sortedStrategies[2].strategy, address(_strategyCompoundDai));
    }
}
