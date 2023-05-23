// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/mocks/MockIporWeighted.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/tokens/IvToken.sol";
import "contracts/itf/ItfAssetManagement6D.sol";

import "./BuilderUtils.sol";
import "./StrategyAaveBuilder.sol";
import "./StrategyCompoundBuilder.sol";
import "contracts/itf/ItfAssetManagement.sol";
import "contracts/itf/ItfAssetManagement18D.sol";
import "forge-std/Test.sol";

contract AssetManagementBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        address asset;
        address ivToken;
        address strategyAave;
        address strategyCompound;
        address assetManagementImplementation;
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

    function withIvToken(address ivToken) public returns (AssetManagementBuilder) {
        builderData.ivToken = ivToken;
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

    function withAssetManagementImplementation(address assetManagementImplementation) public returns (AssetManagementBuilder) {
        builderData.assetManagementImplementation = assetManagementImplementation;
        return this;
    }

    function _buildStrategiesDai() internal {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.ivToken != address(0), "IvToken address is not set");

        StrategyAaveBuilder strategyAaveBuilder = new StrategyAaveBuilder(_owner);
        strategyAaveBuilder.withAsset(builderData.asset);
        strategyAaveBuilder.withShareTokenDai();
        MockTestnetStrategy strategyAave = strategyAaveBuilder.build();

        StrategyCompoundBuilder strategyCompoundBuilder = new StrategyCompoundBuilder(_owner);
        strategyCompoundBuilder.withAsset(builderData.asset);
        strategyCompoundBuilder.withShareTokenDai();
        MockTestnetStrategy strategyCompound = strategyCompoundBuilder.build();

        builderData.strategyAave = address(strategyAave);
        builderData.strategyCompound = address(strategyCompound);
    }

    function _buildStrategiesUsdt() internal {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.ivToken != address(0), "IvToken address is not set");

        StrategyAaveBuilder strategyAaveBuilder = new StrategyAaveBuilder(_owner);
        strategyAaveBuilder.withAsset(builderData.asset);
        strategyAaveBuilder.withShareTokenUsdt();
        MockTestnetStrategy strategyAave = strategyAaveBuilder.build();

        StrategyCompoundBuilder strategyCompoundBuilder = new StrategyCompoundBuilder(_owner);
        strategyCompoundBuilder.withAsset(builderData.asset);
        strategyCompoundBuilder.withShareTokenUsdt();
        MockTestnetStrategy strategyCompound = strategyCompoundBuilder.build();

        builderData.strategyAave = address(strategyAave);
        builderData.strategyCompound = address(strategyCompound);
    }

    function _buildStrategiesUsdc() internal {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.ivToken != address(0), "IvToken address is not set");

        StrategyAaveBuilder strategyAaveBuilder = new StrategyAaveBuilder(_owner);
        strategyAaveBuilder.withAsset(builderData.asset);
        strategyAaveBuilder.withShareTokenUsdt();
        MockTestnetStrategy strategyAave = strategyAaveBuilder.build();

        StrategyCompoundBuilder strategyCompoundBuilder = new StrategyCompoundBuilder(_owner);
        strategyCompoundBuilder.withAsset(builderData.asset);
        strategyCompoundBuilder.withShareTokenUsdc();
        MockTestnetStrategy strategyCompound = strategyCompoundBuilder.build();

        builderData.strategyAave = address(strategyAave);
        builderData.strategyCompound = address(strategyCompound);
    }

    function build() public returns (ItfAssetManagement) {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.ivToken != address(0), "IvToken address is not set");

        _buildStrategies();

        vm.startPrank(_owner);

        ERC1967Proxy proxy = _constructProxy(address(_buildAssetManagementImplementation()));
        ItfAssetManagement assetManagement = ItfAssetManagement(address(proxy));

        MockTestnetStrategy strategyAave = MockTestnetStrategy(builderData.strategyAave);
        MockTestnetStrategy strategyCompound = MockTestnetStrategy(builderData.strategyCompound);

        strategyAave.setAssetManagement(address(assetManagement));
        strategyCompound.setAssetManagement(address(assetManagement));
        vm.stopPrank();
        delete builderData;
        return assetManagement;
    }

    function _buildAssetManagementImplementation() internal returns (address assetManagementImpl) {
        if (builderData.assetManagementImplementation != address(0)) {
            assetManagementImpl = builderData.assetManagementImplementation;
        } else {
            if (builderData.assetType == BuilderUtils.AssetType.DAI) {
                assetManagementImpl = address(new ItfAssetManagement18D());
            } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
                assetManagementImpl = address(new ItfAssetManagement6D());
            } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
                assetManagementImpl = address(new ItfAssetManagement6D());
            } else {
                revert("Asset type not supported");
            }
        }
    }

    function _buildStrategies() internal {
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            _buildStrategiesDai();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            _buildStrategiesUsdt();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            _buildStrategiesUsdc();
        } else {
            revert("Asset type not supported");
        }
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                builderData.asset,
                builderData.ivToken,
                builderData.strategyAave,
                builderData.strategyCompound
            )
        );
    }
}
