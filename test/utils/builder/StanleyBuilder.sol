import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/mocks/MockIporWeighted.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../contracts/tokens/IvToken.sol";
import "../../../contracts/itf/ItfMiltonDai.sol";
import "../../../contracts/itf/ItfStanleyUsdt.sol";
import "../../../contracts/itf/ItfStanleyUsdc.sol";

import "./BuilderUtils.sol";
import "./IvTokenBuilder.sol";
import "./StrategyAaveBuilder.sol";
import "./StrategyCompoundBuilder.sol";
import "../../../contracts/itf/ItfStanley.sol";
import "../../../contracts/itf/ItfStanleyDai.sol";
import "forge-std/Test.sol";

contract StanleyBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        address asset;
        address ivToken;
        address strategyAave;
        address strategyCompound;
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

    function withStrategiesDai() public returns (StanleyBuilder) {
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

        builderData.assetType = BuilderUtils.AssetType.DAI;
        builderData.strategyAave = address(strategyAave);
        builderData.strategyCompound = address(strategyCompound);

        return this;
    }

    function withStrategiesUsdt() public returns (StanleyBuilder) {
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

        builderData.assetType = BuilderUtils.AssetType.USDT;
        builderData.strategyAave = address(strategyAave);
        builderData.strategyCompound = address(strategyCompound);

        return this;
    }

    function withStrategiesUsdc() public returns (StanleyBuilder) {
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

        builderData.assetType = BuilderUtils.AssetType.USDC;
        builderData.strategyAave = address(strategyAave);
        builderData.strategyCompound = address(strategyCompound);

        return this;
    }

    function build() public returns (ItfStanley) {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.ivToken != address(0), "IvToken address is not set");

        ItfStanley stanley;

        vm.startPrank(_owner);
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            stanley = _buildDAI();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            stanley = _buildUSDC();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            stanley = _buildUSDT();
        } else {
            revert("Unsupported asset type");
        }

        MockTestnetStrategy strategyAave = MockTestnetStrategy(builderData.strategyAave);
        MockTestnetStrategy strategyCompound = MockTestnetStrategy(builderData.strategyCompound);

        strategyAave.setStanley(address(stanley));
        strategyCompound.setStanley(address(stanley));
        vm.stopPrank();
        return stanley;
    }

    function _buildDAI() internal returns (ItfStanley) {
        ERC1967Proxy proxy = _constructProxy(address(new ItfStanleyDai()));
        ItfStanley stanley = ItfStanley(address(proxy));
        return stanley;
    }

    function _buildUSDC() internal returns (ItfStanley) {
        ERC1967Proxy proxy = _constructProxy(address(new ItfStanleyUsdc()));
        ItfStanley stanley = ItfStanley(address(proxy));
        return stanley;
    }

    function _buildUSDT() internal returns (ItfStanley) {
        ERC1967Proxy proxy = _constructProxy(address(new ItfStanleyUsdt()));
        ItfStanley stanley = ItfStanley(address(proxy));
        return stanley;
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
