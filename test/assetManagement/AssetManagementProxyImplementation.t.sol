// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {TestCommons} from "../TestCommons.sol";
import "../../contracts/vault/AssetManagementDai.sol";
import "../mocks/assetManagement/MockStrategy.sol";
import "../mocks/tokens/MockTestnetToken.sol";
import "../utils/builder/AssetManagementBuilder.sol";
import "../utils/builder/AssetBuilder.sol";

contract AssetManagementProxyImplementationTest is TestCommons {
    AssetBuilder internal _assetBuilder = new AssetBuilder(address(this));
    AssetManagementBuilder internal _assetManagementBuilder = new AssetManagementBuilder(address(this));

    AssetManagement internal _assetManagementDai;
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

        _strategyAaveDai = new MockStrategy(address(asset), address(asset));

        _strategyCompoundDai = new MockStrategy(address(asset), address(asset));

        _strategyDsrDai = new MockStrategy(address(asset), address(asset));

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

    function testShouldReturnNonZeroAddress() public {
        // given
        console2.log("address(_assetManagementDai): ", address(_assetManagementDai));
        // when
        address proxyImpl = _assetManagementDai.getImplementation();
        // then
        assertTrue(proxyImpl != address(0), "proxyImpl should not be zero address");
    }

    function testShouldUpdateImplementation() public {
        // given
        address oldProxyImpl = _assetManagementDai.getImplementation();

        _assetBuilder.withDAI();
        MockTestnetToken asset = _assetBuilder.build();

        _strategyAaveDai = new MockStrategy(address(asset), address(asset));

        _strategyCompoundDai = new MockStrategy(address(asset), address(asset));

        _strategyDsrDai = new MockStrategy(address(asset), address(asset));

        AmmTreasury ammTreasury = new AmmTreasury(address(asset), 18, address(asset), address(asset), address(asset));

        address newImplementation = address(
            new AssetManagementDai(
                address(asset),
                address(ammTreasury),
                address(_strategyAaveDai),
                address(_strategyCompoundDai),
                address(_strategyDsrDai)
            )
        );

        // when
        _assetManagementDai.upgradeTo(newImplementation);

        // then
        address newProxyImpl = _assetManagementDai.getImplementation();
        assertTrue(newProxyImpl == newImplementation, "Implementation should be equal to newImplementation");
        assertTrue(newProxyImpl != oldProxyImpl, "proxyImpl should be updated");
    }
}
