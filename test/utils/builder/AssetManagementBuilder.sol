// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/vault/AssetManagementUsdt.sol";
import "../../../contracts/vault/AssetManagementUsdc.sol";
import "../../../contracts/vault/AssetManagementDai.sol";
import "../../../contracts/vault/AssetManagementDai.sol";
import "../../mocks/EmptyAssetManagementImplementation.sol";
import "./BuilderUtils.sol";
import "./MockTestnetStrategyBuilder.sol";

import "forge-std/Test.sol";

contract AssetManagementBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        address asset;
        address ammTreasury;
        address strategyAave;
        address strategyCompound;
        address strategyDsr;
        address assetManagementImplementation;
        address assetManagementProxyAddress;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (AssetManagementBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withAsset(address asset) public returns (AssetManagementBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withStrategyAave(address strategyAave) public returns (AssetManagementBuilder) {
        builderData.strategyAave = strategyAave;
        return this;
    }

    function withStrategyCompound(address strategyCompound) public returns (AssetManagementBuilder) {
        builderData.strategyCompound = strategyCompound;
        return this;
    }

    function withStrategyDsr(address strategyDsr) public returns (AssetManagementBuilder) {
        builderData.strategyDsr = strategyDsr;
        return this;
    }

    function withAmmTreasury(address ammTreasury) public returns (AssetManagementBuilder) {
        builderData.ammTreasury = ammTreasury;
        return this;
    }

    function withAssetManagementImplementation(
        address assetManagementImplementation
    ) public returns (AssetManagementBuilder) {
        builderData.assetManagementImplementation = assetManagementImplementation;
        return this;
    }

    function withAssetManagementProxyAddress(
        address assetManagementProxyAddress
    ) public returns (AssetManagementBuilder) {
        builderData.assetManagementProxyAddress = assetManagementProxyAddress;
        return this;
    }

    function _buildStrategiesForUpgradeDai() internal {
        require(builderData.asset != address(0), "Asset address is not set");

        if (builderData.strategyAave == address(0)) {
            MockTestnetStrategyBuilder strategyAaveBuilder = new MockTestnetStrategyBuilder(_owner);
            strategyAaveBuilder.withAsset(builderData.asset);
            strategyAaveBuilder.withAssetDecimals(18);
            strategyAaveBuilder.withShareTokenDai();
            strategyAaveBuilder.withAssetManagementProxy(builderData.assetManagementProxyAddress);
            MockTestnetStrategy strategyAave = strategyAaveBuilder.build();
            builderData.strategyAave = address(strategyAave);
        }

        if (builderData.strategyCompound == address(0)) {
            MockTestnetStrategyBuilder strategyCompoundBuilder = new MockTestnetStrategyBuilder(_owner);
            strategyCompoundBuilder.withAsset(builderData.asset);
            strategyCompoundBuilder.withAssetDecimals(18);
            strategyCompoundBuilder.withShareTokenDai();
            strategyCompoundBuilder.withAssetManagementProxy(builderData.assetManagementProxyAddress);
            MockTestnetStrategy strategyCompound = strategyCompoundBuilder.build();
            builderData.strategyCompound = address(strategyCompound);
        }

        if (builderData.strategyDsr == address(0)) {
            MockTestnetStrategyBuilder strategyDsrBuilder = new MockTestnetStrategyBuilder(_owner);
            strategyDsrBuilder.withAsset(builderData.asset);
            strategyDsrBuilder.withAssetDecimals(18);
            strategyDsrBuilder.withShareTokenDai();
            strategyDsrBuilder.withAssetManagementProxy(builderData.assetManagementProxyAddress);
            MockTestnetStrategy strategyDsr = strategyDsrBuilder.build();
            builderData.strategyDsr = address(strategyDsr);
        }
    }

    function _buildStrategiesForUpgradeUsdt() internal {
        require(builderData.asset != address(0), "Asset address is not set");

        if (builderData.strategyAave == address(0)) {
            MockTestnetStrategyBuilder strategyAaveBuilder = new MockTestnetStrategyBuilder(_owner);
            strategyAaveBuilder.withAsset(builderData.asset);
            strategyAaveBuilder.withAssetDecimals(6);
            strategyAaveBuilder.withShareTokenUsdt();
            strategyAaveBuilder.withAssetManagementProxy(builderData.assetManagementProxyAddress);
            MockTestnetStrategy strategyAave = strategyAaveBuilder.build();
            builderData.strategyAave = address(strategyAave);
        }

        if (builderData.strategyCompound == address(0)) {
            MockTestnetStrategyBuilder strategyCompoundBuilder = new MockTestnetStrategyBuilder(_owner);
            strategyCompoundBuilder.withAsset(builderData.asset);
            strategyCompoundBuilder.withAssetDecimals(6);
            strategyCompoundBuilder.withShareTokenUsdt();
            strategyCompoundBuilder.withAssetManagementProxy(builderData.assetManagementProxyAddress);
            MockTestnetStrategy strategyCompound = strategyCompoundBuilder.build();
            builderData.strategyCompound = address(strategyCompound);
        }
    }

    function _buildStrategiesForUpgradeUsdc() internal {
        require(builderData.asset != address(0), "Asset address is not set");

        if (builderData.strategyAave == address(0)) {
            MockTestnetStrategyBuilder strategyAaveBuilder = new MockTestnetStrategyBuilder(_owner);
            strategyAaveBuilder.withAsset(builderData.asset);
            strategyAaveBuilder.withAssetDecimals(6);
            strategyAaveBuilder.withShareTokenUsdc();
            strategyAaveBuilder.withAssetManagementProxy(builderData.assetManagementProxyAddress);
            MockTestnetStrategy strategyAave = strategyAaveBuilder.build();
            builderData.strategyAave = address(strategyAave);
        }

        if (builderData.strategyCompound == address(0)) {
            MockTestnetStrategyBuilder strategyCompoundBuilder = new MockTestnetStrategyBuilder(_owner);
            strategyCompoundBuilder.withAsset(builderData.asset);
            strategyCompoundBuilder.withAssetDecimals(6);
            strategyCompoundBuilder.withShareTokenUsdc();
            strategyCompoundBuilder.withAssetManagementProxy(builderData.assetManagementProxyAddress);
            MockTestnetStrategy strategyCompound = strategyCompoundBuilder.build();
            builderData.strategyCompound = address(strategyCompound);
        }
    }

    function buildEmptyProxy() public returns (AssetManagement) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new EmptyAssetManagementImplementation()));
        AssetManagement assetManagement = AssetManagement(address(proxy));
        vm.stopPrank();
        delete builderData;
        return assetManagement;
    }

    function build() public returns (AssetManagement) {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.ammTreasury != address(0), "AmmTreasury address is not set");
        require(builderData.strategyAave != address(0), "Strategy Aave address is not set");
        require(builderData.strategyCompound != address(0), "Strategy Compound address is not set");

        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(_buildAssetManagementImplementation()));
        vm.stopPrank();

        delete builderData;
        return AssetManagement(address(proxy));
    }

    function upgrade() public {
        require(builderData.assetManagementProxyAddress != address(0), "assetManagementProxyAddress is required");

        AssetManagement assetManagement = AssetManagement(builderData.assetManagementProxyAddress);

        address implementation;

        if (address(builderData.assetManagementImplementation) == address(0)) {
            _buildStrategiesForUpgrade();
            implementation = address(_buildAssetManagementImplementation());
        }

        vm.startPrank(_owner);
        assetManagement.upgradeTo(implementation);

        /// @dev grant max allowance for spender only for test purposes because MockTestnetStrategy are used
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            assetManagement.grantMaxAllowanceForSpender(builderData.asset, builderData.strategyAave);
            assetManagement.grantMaxAllowanceForSpender(builderData.asset, builderData.strategyCompound);
            assetManagement.grantMaxAllowanceForSpender(builderData.asset, builderData.strategyDsr);
        }

        if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            assetManagement.grantMaxAllowanceForSpender(builderData.asset, builderData.strategyAave);
            assetManagement.grantMaxAllowanceForSpender(builderData.asset, builderData.strategyCompound);
        }

        if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            assetManagement.grantMaxAllowanceForSpender(builderData.asset, builderData.strategyAave);
            assetManagement.grantMaxAllowanceForSpender(builderData.asset, builderData.strategyCompound);
        }
        vm.stopPrank();

        delete builderData;
    }

    function _buildAssetManagementImplementation() internal returns (address assetManagementImpl) {
        if (builderData.assetManagementImplementation != address(0)) {
            assetManagementImpl = builderData.assetManagementImplementation;
        } else {
            if (builderData.assetType == BuilderUtils.AssetType.DAI) {
                require(builderData.strategyDsr != address(0), "Strategy DSR address is not set");

                assetManagementImpl = address(
                    new AssetManagementDai(
                        builderData.asset,
                        builderData.ammTreasury,
                        builderData.strategyAave,
                        builderData.strategyCompound,
                        builderData.strategyDsr
                    )
                );
            } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
                assetManagementImpl = address(
                    new AssetManagementUsdt(
                        builderData.asset,
                        builderData.ammTreasury,
                        builderData.strategyAave,
                        builderData.strategyCompound
                    )
                );
            } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
                assetManagementImpl = address(
                    new AssetManagementUsdc(
                        builderData.asset,
                        builderData.ammTreasury,
                        builderData.strategyAave,
                        builderData.strategyCompound
                    )
                );
            } else {
                revert("Asset type not supported");
            }
        }
    }

    function _buildStrategiesForUpgrade() internal {
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            _buildStrategiesForUpgradeDai();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            _buildStrategiesForUpgradeUsdt();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            _buildStrategiesForUpgradeUsdc();
        } else {
            revert("Asset type not supported");
        }
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize()"));
    }
}
