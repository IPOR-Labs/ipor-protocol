// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "contracts/itf/ItfAmmTreasury.sol";
import "contracts/itf/ItfAmmTreasury6D.sol";
import "contracts/itf/ItfAmmTreasury18D.sol";

import "contracts/mocks/ammTreasury/MockAmmTreasury.sol";

import "./BuilderUtils.sol";
import "contracts/itf/ItfAmmTreasury18D.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";
import "contracts/mocks/ammTreasury/MockAmmTreasury.sol";

contract AmmTreasuryBuilder is Test {
    struct BuilderData {
        BuilderUtils.AmmTreasuryTestCase testCase;
        BuilderUtils.AssetType assetType;
        address asset;
        address iporOracle;
        address iporRiskManagementOracle;
        address ammStorage;
        address spreadModel;
        address assetManagement;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withTestCase(BuilderUtils.AmmTreasuryTestCase testCase) public returns (AmmTreasuryBuilder) {
        builderData.testCase = testCase;
        return this;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (AmmTreasuryBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withAsset(address asset) public returns (AmmTreasuryBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withIporOracle(address iporOracle) public returns (AmmTreasuryBuilder) {
        builderData.iporOracle = iporOracle;
        return this;
    }

    function withIporRiskManagementOracle(address iporRiskManagementOracle) public returns (AmmTreasuryBuilder) {
        builderData.iporRiskManagementOracle = iporRiskManagementOracle;
        return this;
    }

    function withAmmStorage(address ammStorage) public returns (AmmTreasuryBuilder) {
        builderData.ammStorage = ammStorage;
        return this;
    }

    function withSpreadModel(address spreadModel) public returns (AmmTreasuryBuilder) {
        builderData.spreadModel = spreadModel;
        return this;
    }

    function withAssetManagement(address assetManagement) public returns (AmmTreasuryBuilder) {
        builderData.assetManagement = assetManagement;
        return this;
    }

    function build() public returns (ItfAmmTreasury) {
        vm.startPrank(_owner);
        ERC1967Proxy ammTreasuryProxy = _constructProxy(_buildAmmTreasuryImplementation());
        ItfAmmTreasury ammTreasury = ItfAmmTreasury(address(ammTreasuryProxy));
        vm.stopPrank();
        delete builderData;
        return ammTreasury;
    }

    function _buildAmmTreasuryImplementation() internal returns (address ammTreasuryImpl) {
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            ammTreasuryImpl = address(
                _constructAmmTreasuryDaiImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            ammTreasuryImpl = address(
                _constructAmmTreasuryUsdtImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            ammTreasuryImpl = address(
                _constructAmmTreasuryUsdcImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else {
            revert("Unsupported asset type");
        }
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        require(builderData.asset != address(0), "Asset address is required");
        require(builderData.iporOracle != address(0), "IporOracle address is required");
        require(builderData.ammStorage != address(0), "AmmStorage address is required");
        require(builderData.spreadModel != address(0), "SpreadModel address is required");
        require(builderData.assetManagement != address(0), "AssetManagement address is required");

        proxy = new ERC1967Proxy(
            impl,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                builderData.asset,
                builderData.iporOracle,
                builderData.ammStorage,
                builderData.spreadModel,
                builderData.assetManagement
            )
        );
    }

    function _constructAmmTreasuryDaiImplementation(BuilderUtils.AmmTreasuryTestCase testCase, address iporRiskManagementOracle)
        internal
        returns (ItfAmmTreasury)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");

        if (testCase == BuilderUtils.AmmTreasuryTestCase.DEFAULT) {
            return new ItfAmmTreasury18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE0) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE1) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 600000000000000000, 0, 10 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE2) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE3) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE4) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 50000000000000000, 10 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE5) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 25000000000000000, 10 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE6) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE7) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE8) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 100000 * 1e18, 20, 10 * 1e18),
                    18
                );
        } else {
            revert("Unsupported test case");
        }
    }

    function _constructAmmTreasuryUsdtImplementation(BuilderUtils.AmmTreasuryTestCase testCase, address iporRiskManagementOracle)
        internal
        returns (ItfAmmTreasury)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");
        if (testCase == BuilderUtils.AmmTreasuryTestCase.DEFAULT) {
            return new ItfAmmTreasury6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE0) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE1) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 600000000000000000, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE2) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE3) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE4) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 50000000000000000, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE5) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 25000000000000000, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE6) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else {
            revert("Unsupported test case");
        }
    }

    function _constructAmmTreasuryUsdcImplementation(BuilderUtils.AmmTreasuryTestCase testCase, address iporRiskManagementOracle)
        internal
        returns (ItfAmmTreasury)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");
        if (testCase == BuilderUtils.AmmTreasuryTestCase.DEFAULT) {
            return new ItfAmmTreasury6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE0) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE1) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 600000000000000000, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE2) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE3) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE4) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 50000000000000000, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE5) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 25000000000000000, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else if (testCase == BuilderUtils.AmmTreasuryTestCase.CASE6) {
            return
                new MockAmmTreasury(
                    iporRiskManagementOracle,
                    MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                    6
                );
        } else {
            revert("Unsupported test case");
        }
    }
}
