// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {TestCommons} from "../TestCommons.sol";

import {IvToken} from "@ipor-protocol/contracts/tokens/IvToken.sol";


import "../utils/builder/AssetManagementBuilder.sol";
import "../mocks/assetManagement/MockStrategy.sol";
import "../mocks/tokens/MockTestnetToken.sol";
import "../utils/builder/IvTokenBuilder.sol";
import "../utils/builder/AssetBuilder.sol";

contract AssetManagementMaxApyStrategyTest is TestCommons {
    AssetBuilder internal _assetBuilder = new AssetBuilder(address(this));
    IvTokenBuilder internal _ivTokenBuilder = new IvTokenBuilder(address(this));
    AssetManagementBuilder internal _assetManagementBuilder = new AssetManagementBuilder(address(this));

    AssetManagement internal _assetManagementDai;
    MockStrategy internal _strategyAaveDai;
    MockStrategy internal _strategyCompoundDai;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _assetBuilder.withDAI();
        MockTestnetToken asset = _assetBuilder.build();

        IvToken ivToken = _ivTokenBuilder.withName("IV DAI").withSymbol("ivDAI").withAsset(address(asset)).build();

        _strategyAaveDai = new MockStrategy();
        _strategyAaveDai.setAsset(address(asset));
        _strategyAaveDai.setShareToken(address(asset));

        _strategyCompoundDai = new MockStrategy();
        _strategyCompoundDai.setAsset(address(asset));
        _strategyCompoundDai.setShareToken(address(asset));

        _assetManagementDai = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(asset))
            .withIvToken(address(ivToken))
            .withStrategyAave(address(_strategyAaveDai))
            .withStrategyCompound(address(_strategyCompoundDai))
            .build();
    }

    function testShouldSelectAaveStrategy() public {
        // given
        _strategyAaveDai.setApy(100000);
        _strategyCompoundDai.setApy(99999);
        // when
        (address strategyMaxApy, , ) = _assetManagementDai.getMaxApyStrategy();
        // then
        assertEq(strategyMaxApy, address(_strategyAaveDai));
    }

    function testShouldSelectAaveStrategyWhenAaveApyEqualsCompoundApy() public {
        // given
        _strategyAaveDai.setApy(10);
        _strategyCompoundDai.setApy(10);
        // when
        (address strategyMaxApy, , ) = _assetManagementDai.getMaxApyStrategy();
        // then
        assertEq(strategyMaxApy, address(_strategyAaveDai));
    }

    function testShouldSelectCompoundStrategy() public {
        // given
        _strategyAaveDai.setApy(1000);
        _strategyCompoundDai.setApy(99999);
        // when
        (address strategyMaxApy, , ) = _assetManagementDai.getMaxApyStrategy();
        // then
        assertEq(strategyMaxApy, address(_strategyCompoundDai));
    }
}
