// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/mocks/MockIporWeighted.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/tokens/IvToken.sol";
import "contracts/itf/ItfStanley6D.sol";

import "./BuilderUtils.sol";
import "./StrategyAaveBuilder.sol";
import "./StrategyCompoundBuilder.sol";
import "contracts/itf/ItfStanley.sol";
import "contracts/itf/ItfStanley18D.sol";
import "forge-std/Test.sol";

contract StanleyBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        address asset;
        address ivToken;
        address strategyAave;
        address strategyCompound;
        address stanleyImplementation;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (StanleyBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withAsset(address asset) public returns (StanleyBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withIvToken(address ivToken) public returns (StanleyBuilder) {
        builderData.ivToken = ivToken;
        return this;
    }

    function withStrategyAave(address strategyAave) public returns (StanleyBuilder) {
        builderData.strategyAave = strategyAave;
        return this;
    }

    function withStrategyCompound(address strategyCompound) public returns (StanleyBuilder) {
        builderData.strategyCompound = strategyCompound;
        return this;
    }

    function withStanleyImplementation(address stanleyImplementation) public returns (StanleyBuilder) {
        builderData.stanleyImplementation = stanleyImplementation;
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

    function build() public returns (ItfStanley) {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.ivToken != address(0), "IvToken address is not set");

        _buildStrategies();

        vm.startPrank(_owner);

        ERC1967Proxy proxy = _constructProxy(address(_buildStanleyImplementation()));
        ItfStanley stanley = ItfStanley(address(proxy));

        MockTestnetStrategy strategyAave = MockTestnetStrategy(builderData.strategyAave);
        MockTestnetStrategy strategyCompound = MockTestnetStrategy(builderData.strategyCompound);

        strategyAave.setStanley(address(stanley));
        strategyCompound.setStanley(address(stanley));
        vm.stopPrank();
        delete builderData;
        return stanley;
    }

    function _buildStanleyImplementation() internal returns (address stanleyImpl) {
        if (builderData.stanleyImplementation != address(0)) {
            stanleyImpl = builderData.stanleyImplementation;
        } else {
            if (builderData.assetType == BuilderUtils.AssetType.DAI) {
                stanleyImpl = address(new ItfStanley18D());
            } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
                stanleyImpl = address(new ItfStanley6D());
            } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
                stanleyImpl = address(new ItfStanley6D());
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
