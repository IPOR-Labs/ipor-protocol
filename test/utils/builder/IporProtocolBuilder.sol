// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";
import "contracts/mocks/stanley/MockTestnetStrategy.sol";
import "contracts/mocks/MockIporWeighted.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/tokens/IvToken.sol";
import "contracts/itf/ItfIporOracle.sol";
import "contracts/itf/ItfStanley.sol";
import "contracts/itf/ItfMilton.sol";
import "contracts/itf/ItfJoseph.sol";
import "contracts/amm/MiltonStorage.sol";
import "./AssetBuilder.sol";
import "./IporOracleBuilder.sol";
import "./IporRiskManagementOracleBuilder.sol";
import "forge-std/Test.sol";

contract IporProtocolBuilder is Test {
    struct BuilderData {
        address asset;
        address iporOracle;
        address iporRiskManagementOracle;
    }

    struct IporProtocol {
        MockTestnetToken asset;
        IpToken ipToken;
        IvToken ivToken;
        ItfIporOracle iporOracle;
        IporRiskManagementOracle iporRiskManagementOracle;
        MockIporWeighted iporWeighted;
        MiltonStorage miltonStorage;
        MockSpreadModel spreadModel;
        ItfStanley stanley;
        ItfMilton milton;
        ItfJoseph joseph;
    }

    AssetBuilder public assetBuilder;
    IpTokenBuilder public ipTokenBuilder;
    IvTokenBuilder public ivTokenBuilder;
    IporOracleBuilder public iporOracleBuilder;
    IporRiskManagementOracleBuilder public iporRiskManagementOracleBuilder;
    IporWeightedBuilder public iporWeightedBuilder;
    MiltonStorageBuilder public miltonStorageBuilder;
    MockSpreadBuilder public spreadBuilder;
    StanleyBuilder public stanleyBuilder;
    MiltonBuilder public miltonBuilder;
    JosephBuilder public josephBuilder;

    address private _owner;

    BuilderData private builderData;

    constructor(address owner) {
        _owner = owner;
        assetBuilder = new AssetBuilder(owner);
        ipTokenBuilder = new IpTokenBuilder(owner, this);
        ivTokenBuilder = new IvTokenBuilder(owner, this);
        iporOracleBuilder = new IporOracleBuilder(owner);
        iporRiskManagementOracleBuilder = new IporRiskManagementOracleBuilder(owner);
        iporWeightedBuilder = new IporWeightedBuilder(owner);
        miltonStorageBuilder = new MiltonStorageBuilder(owner);
        spreadBuilder = new MockSpreadBuilder(owner, this);
        stanleyBuilder = new StanleyBuilder(owner, this);
        miltonBuilder = new MiltonBuilder(owner, this);
        josephBuilder = new JosephBuilder(owner, this);
    }

    function withAsset(address assetInput) public returns (IporProtocolBuilder) {
        builderData.asset = assetInput;
        ipTokenBuilder.withAsset(assetInput);
        ivTokenBuilder.withAsset(assetInput);
        iporOracleBuilder.withAsset(assetInput);
        iporRiskManagementOracleBuilder.withAsset(assetInput);
        stanleyBuilder.withAsset(assetInput);
        miltonBuilder.withAsset(assetInput);
        josephBuilder.withAsset(assetInput);

        return this;
    }

    function withIporOracle(address iporOracleAddress) public returns (IporProtocolBuilder) {
        builderData.iporOracle = iporOracleAddress;
        iporWeightedBuilder.withIporOracle(iporOracleAddress);
        miltonBuilder.withIporOracle(iporOracleAddress);
        return this;
    }

    function withIporRiskManagementOracle(address iporRiskManagementOracleAddress)
        public
        returns (IporProtocolBuilder)
    {
        builderData.iporRiskManagementOracle = iporRiskManagementOracleAddress;
        miltonBuilder.withIporRiskManagementOracle(iporRiskManagementOracleAddress);
        return this;
    }

    function daiBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        josephBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.DAI);

        assetBuilder.withDAI();

        return this;
    }

    function usdtBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        josephBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.USDT);

        assetBuilder.withUSDT();

        return this;
    }

    function usdcBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        josephBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.USDC);

        assetBuilder.withUSDC();

        return this;
    }

    function ipToken() public view returns (IpTokenBuilder) {
        return ipTokenBuilder;
    }

    function ivToken() public view returns (IvTokenBuilder) {
        return ivTokenBuilder;
    }

    function spread() public view returns (MockSpreadBuilder) {
        return spreadBuilder;
    }

    function milton() public view returns (MiltonBuilder) {
        return miltonBuilder;
    }

    function joseph() public view returns (JosephBuilder) {
        return josephBuilder;
    }

    function stanley() public view returns (StanleyBuilder) {
        return stanleyBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return this;
    }

    function build() public returns (IporProtocol memory iporProtocol) {
        MockTestnetToken assetTemp;

        if (builderData.asset == address(0)) {
            assetTemp = assetBuilder.build();
        } else {
            assetTemp = MockTestnetToken(builderData.asset);
        }

        if (ipTokenBuilder.isSetAsset() == false) {
            ipTokenBuilder.withAsset(address(assetTemp));
        }
        IpToken ipTokenTemp = ipTokenBuilder.build();

        if (ivTokenBuilder.isSetAsset() == false) {
            ivTokenBuilder.withAsset(address(assetTemp));
        }
        IvToken ivTokenTemp = ivTokenBuilder.build();

        ItfIporOracle iporOracleTemp;

        if (builderData.iporOracle == address(0)) {
            iporOracleTemp = iporOracleBuilder.build();
        } else {
            iporOracleTemp = ItfIporOracle(builderData.iporOracle);
        }

        IporRiskManagementOracle iporRiskManagementOracleTemp;

        if (builderData.iporRiskManagementOracle == address(0)) {
            iporRiskManagementOracleTemp = iporRiskManagementOracleBuilder.build();
        } else {
            iporRiskManagementOracleTemp = IporRiskManagementOracle(builderData.iporRiskManagementOracle);
        }

        if (iporWeightedBuilder.isSetIporOracle() == false) {
            iporWeightedBuilder.withIporOracle(address(iporOracleTemp));
        }
        MockIporWeighted iporWeighted = iporWeightedBuilder.build();

        MiltonStorage miltonStorage = miltonStorageBuilder.build();
        MockSpreadModel spreadModel = spreadBuilder.build();

        if (stanleyBuilder.isSetAsset() == false) {
            stanleyBuilder.withAsset(address(assetTemp));
        }
        if (stanleyBuilder.isSetIvToken() == false) {
            stanleyBuilder.withIvToken(address(ivTokenTemp));
        }
        ItfStanley stanleyTemp = stanleyBuilder.build();

        if (miltonBuilder.isSetAsset() == false) {
            miltonBuilder.withAsset(address(assetTemp));
        }
        if (miltonBuilder.isSetIporOracle() == false) {
            miltonBuilder.withIporOracle(address(iporOracleTemp));
        }
        if (miltonBuilder.isSetMiltonStorage() == false) {
            miltonBuilder.withMiltonStorage(address(miltonStorage));
        }
        if (miltonBuilder.isSetStanley() == false) {
            miltonBuilder.withStanley(address(stanleyTemp));
        }
        if (miltonBuilder.isSetSpreadModel() == false) {
            miltonBuilder.withSpreadModel(address(spreadModel));
        }
        if (miltonBuilder.isSetIporRiskManagementOracle() == false) {
            miltonBuilder.withIporRiskManagementOracle(address(iporRiskManagementOracleTemp));
        }

        ItfMilton miltonTemp = miltonBuilder.build();

        if (josephBuilder.isSetAsset() == false) {
            josephBuilder.withAsset(address(assetTemp));
        }
        if (josephBuilder.isSetIpToken() == false) {
            josephBuilder.withIpToken(address(ipTokenTemp));
        }
        if (josephBuilder.isSetMiltonStorage() == false) {
            josephBuilder.withMiltonStorage(address(miltonStorage));
        }
        if (josephBuilder.isSetMilton() == false) {
            josephBuilder.withMilton(address(miltonTemp));
        }
        if (josephBuilder.isSetStanley() == false) {
            josephBuilder.withStanley(address(stanleyTemp));
        }

        ItfJoseph josephTemp = josephBuilder.build();

        vm.startPrank(address(_owner));
        iporOracleTemp.setIporAlgorithmFacade(address(iporWeighted));

        ivTokenTemp.setStanley(address(stanleyTemp));

        miltonStorage.setMilton(address(miltonTemp));
        stanleyTemp.setMilton(address(miltonTemp));
        miltonTemp.setupMaxAllowanceForAsset(address(stanleyTemp));

        ipTokenTemp.setJoseph(address(josephTemp));
        miltonStorage.setJoseph(address(josephTemp));
        miltonTemp.setJoseph(address(josephTemp));
        miltonTemp.setupMaxAllowanceForAsset(address(josephTemp));

        josephTemp.setMaxLiquidityPoolBalance(1000000000);
        josephTemp.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        iporProtocol = IporProtocol(
            assetTemp,
            ipTokenTemp,
            ivTokenTemp,
            iporOracleTemp,
            iporRiskManagementOracleTemp,
            iporWeighted,
            miltonStorage,
            spreadModel,
            stanleyTemp,
            miltonTemp,
            josephTemp
        );

        delete builderData;
    }
}

contract IpTokenBuilder is Test {
    struct BuilderData {
        string name;
        string symbol;
        address asset;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
    }

    function withName(string memory name) public returns (IpTokenBuilder) {
        builderData.name = name;
        return this;
    }

    function withSymbol(string memory symbol) public returns (IpTokenBuilder) {
        builderData.symbol = symbol;
        return this;
    }

    function withAsset(address asset) public returns (IpTokenBuilder) {
        builderData.asset = asset;
        return this;
    }

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function build() public returns (IpToken) {
        vm.startPrank(_owner);
        IpToken ipToken = new IpToken(builderData.name, builderData.symbol, builderData.asset);
        vm.stopPrank();
        delete builderData;
        return ipToken;
    }
}

contract IvTokenBuilder is Test {
    struct BuilderData {
        string name;
        string symbol;
        address asset;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
    }

    function withName(string memory name) public returns (IvTokenBuilder) {
        builderData.name = name;
        return this;
    }

    function withSymbol(string memory symbol) public returns (IvTokenBuilder) {
        builderData.symbol = symbol;
        return this;
    }

    function withAsset(address asset) public returns (IvTokenBuilder) {
        builderData.asset = asset;
        return this;
    }

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function build() public returns (IvToken) {
        vm.startPrank(_owner);
        IvToken ivToken = new IvToken(builderData.name, builderData.symbol, builderData.asset);
        vm.stopPrank();
        delete builderData;
        return ivToken;
    }
}

contract IporWeightedBuilder is Test {
    struct BuilderData {
        address iporOracle;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withIporOracle(address iporOracle) public returns (IporWeightedBuilder) {
        builderData.iporOracle = iporOracle;
        return this;
    }

    function isSetIporOracle() public view returns (bool) {
        return builderData.iporOracle != address(0);
    }

    function build() public returns (MockIporWeighted) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MockIporWeighted()));
        MockIporWeighted iporWeighted = MockIporWeighted(address(proxy));
        vm.stopPrank();
        delete builderData;
        return iporWeighted;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(impl, abi.encodeWithSignature("initialize(address)", builderData.iporOracle));
    }
}

contract MiltonStorageBuilder is Test {
    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function build() public returns (MiltonStorage) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MiltonStorage()));
        MiltonStorage miltonStorage = MiltonStorage(address(proxy));
        vm.stopPrank();
        return miltonStorage;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize()", ""));
    }
}

contract MockSpreadBuilder is Test {
    struct BuilderData {
        uint256 quotePayFixedValue;
        uint256 quoteReceiveFixedValue;
        int256 spreadPayFixedValue;
        int256 spreadReceiveFixedValue;
        address spreadImplementation;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
    }

    function withQuotePayFixedValue(uint256 quotePayFixedValue) public returns (MockSpreadBuilder) {
        builderData.quotePayFixedValue = quotePayFixedValue;
        return this;
    }

    function withQuoteReceiveFixedValue(uint256 quoteReceiveFixedValue) public returns (MockSpreadBuilder) {
        builderData.quoteReceiveFixedValue = quoteReceiveFixedValue;
        return this;
    }

    function withSpreadPayFixedValue(int256 spreadPayFixedValue) public returns (MockSpreadBuilder) {
        builderData.spreadPayFixedValue = spreadPayFixedValue;
        return this;
    }

    function withSpreadReceiveFixedValue(int256 spreadReceiveFixedValue) public returns (MockSpreadBuilder) {
        builderData.spreadReceiveFixedValue = spreadReceiveFixedValue;
        return this;
    }

    function withSpreadImplementation(address spreadImplementation) public returns (MockSpreadBuilder) {
        builderData.spreadImplementation = spreadImplementation;
        return this;
    }

    function build() public returns (MockSpreadModel spreadModel) {
        vm.startPrank(_owner);
        if (builderData.spreadImplementation != address(0)) {
            spreadModel = MockSpreadModel(builderData.spreadImplementation);
        } else {
            spreadModel = new MockSpreadModel(
                builderData.quotePayFixedValue,
                builderData.quoteReceiveFixedValue,
                builderData.spreadPayFixedValue,
                builderData.spreadReceiveFixedValue
            );
        }
        vm.stopPrank();
        delete builderData;
    }
}

contract StrategyAaveBuilder is Test {
    struct BuilderData {
        address asset;
        address shareToken;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAsset(address asset) public returns (StrategyAaveBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withShareToken(address shareToken) public returns (StrategyAaveBuilder) {
        builderData.shareToken = shareToken;
        return this;
    }

    function withShareTokenDai() public returns (StrategyAaveBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share aDAI", "aDAI", 0, 18);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function withShareTokenUsdt() public returns (StrategyAaveBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share aUSDT", "aUSDT", 0, 6);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function withShareTokenUsdc() public returns (StrategyAaveBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share aUSDC", "aUSDC", 0, 6);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function build() public returns (MockTestnetStrategy) {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.shareToken != address(0), "ShareToken address is not set");

        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MockTestnetStrategy()));
        MockTestnetStrategy strategy = MockTestnetStrategy(address(proxy));
        vm.stopPrank();
        return strategy;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature("initialize(address,address)", builderData.asset, builderData.shareToken)
        );
    }
}

contract StrategyCompoundBuilder is Test {
    struct BuilderData {
        address asset;
        address shareToken;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAsset(address asset) public returns (StrategyCompoundBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withShareToken(address shareToken) public returns (StrategyCompoundBuilder) {
        builderData.shareToken = shareToken;
        return this;
    }

    function withShareTokenDai() public returns (StrategyCompoundBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share cDAI", "cDAI", 0, 18);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function withShareTokenUsdt() public returns (StrategyCompoundBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share cUSDT", "cUSDT", 0, 6);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function withShareTokenUsdc() public returns (StrategyCompoundBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share cUSDC", "cUSDC", 0, 6);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function build() public returns (MockTestnetStrategy) {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.shareToken != address(0), "ShareToken address is not set");
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MockTestnetStrategy()));
        MockTestnetStrategy strategy = MockTestnetStrategy(address(proxy));
        vm.stopPrank();
        return strategy;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature("initialize(address,address)", builderData.asset, builderData.shareToken)
        );
    }
}

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
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
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

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function isSetIvToken() public view returns (bool) {
        return builderData.ivToken != address(0);
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

contract MiltonBuilder is Test {
    struct BuilderData {
        BuilderUtils.MiltonTestCase testCase;
        BuilderUtils.AssetType assetType;
        address asset;
        address iporOracle;
        address iporRiskManagementOracle;
        address miltonStorage;
        address spreadModel;
        address stanley;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
    }

    function withTestCase(BuilderUtils.MiltonTestCase testCase) public returns (MiltonBuilder) {
        builderData.testCase = testCase;
        return this;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (MiltonBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withAsset(address asset) public returns (MiltonBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withIporOracle(address iporOracle) public returns (MiltonBuilder) {
        builderData.iporOracle = iporOracle;
        return this;
    }

    function withIporRiskManagementOracle(address iporRiskManagementOracle) public returns (MiltonBuilder) {
        builderData.iporRiskManagementOracle = iporRiskManagementOracle;
        return this;
    }

    function withMiltonStorage(address miltonStorage) public returns (MiltonBuilder) {
        builderData.miltonStorage = miltonStorage;
        return this;
    }

    function withSpreadModel(address spreadModel) public returns (MiltonBuilder) {
        builderData.spreadModel = spreadModel;
        return this;
    }

    function withStanley(address stanley) public returns (MiltonBuilder) {
        builderData.stanley = stanley;
        return this;
    }

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function isSetIporOracle() public view returns (bool) {
        return builderData.iporOracle != address(0);
    }

    function isSetIporRiskManagementOracle() public view returns (bool) {
        return builderData.iporRiskManagementOracle != address(0);
    }

    function isSetMiltonStorage() public view returns (bool) {
        return builderData.miltonStorage != address(0);
    }

    function isSetSpreadModel() public view returns (bool) {
        return builderData.spreadModel != address(0);
    }

    function isSetStanley() public view returns (bool) {
        return builderData.stanley != address(0);
    }

    function build() public returns (ItfMilton) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(_buildMiltonImplementation());
        ItfMilton milton = ItfMilton(address(miltonProxy));
        vm.stopPrank();
        delete builderData;
        return milton;
    }

    function _buildMiltonImplementation() internal returns (address miltonImpl) {
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            miltonImpl = address(
                _constructMiltonDaiImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            miltonImpl = address(
                _constructMiltonUsdtImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            miltonImpl = address(
                _constructMiltonUsdcImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else {
            revert("Unsupported asset type");
        }
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        require(builderData.asset != address(0), "Asset address is required");
        require(builderData.iporOracle != address(0), "IporOracle address is required");
        require(builderData.miltonStorage != address(0), "MiltonStorage address is required");
        require(builderData.spreadModel != address(0), "SpreadModel address is required");
        require(builderData.stanley != address(0), "Stanley address is required");

        proxy = new ERC1967Proxy(
            impl,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                builderData.asset,
                builderData.iporOracle,
                builderData.miltonStorage,
                builderData.spreadModel,
                builderData.stanley
            )
        );
    }

    function _constructMiltonDaiImplementation(BuilderUtils.MiltonTestCase testCase, address iporRiskManagementOracle)
    internal
    returns (ItfMilton)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");

        if (testCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            return new ItfMilton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE0) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                18
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 600000000000000000, 0, 10 * 1e18, 20, 10 * 1e18),
                18
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                18
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                18
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 50000000000000000, 10 * 1e18, 20, 10 * 1e18),
                18
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 25000000000000000, 10 * 1e18, 20, 10 * 1e18),
                18
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                18
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE7) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                18
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE8) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 100000 * 1e18, 20, 10 * 1e18),
                18
            );
        } else {
            revert("Unsupported test case");
        }
    }

    function _constructMiltonUsdtImplementation(BuilderUtils.MiltonTestCase testCase, address iporRiskManagementOracle)
    internal
    returns (ItfMilton)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");
        if (testCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            return new ItfMilton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE0) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 600000000000000000, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 50000000000000000, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 25000000000000000, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else {
            revert("Unsupported test case");
        }
    }

    function _constructMiltonUsdcImplementation(BuilderUtils.MiltonTestCase testCase, address iporRiskManagementOracle)
    internal
    returns (ItfMilton)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");
        if (testCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            return new ItfMilton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE0) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 600000000000000000, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 50000000000000000, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 25000000000000000, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return
            new MockMilton(
                iporRiskManagementOracle,
                MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
                6
            );
        } else {
            revert("Unsupported test case");
        }
    }
}


contract JosephBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        bool paused;
        address asset;
        address ipToken;
        address milton;
        address miltonStorage;
        address stanley;
        address josephImplementation;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (JosephBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withPaused(bool paused) public returns (JosephBuilder) {
        builderData.paused = paused;
        return this;
    }

    function withAsset(address asset) public returns (JosephBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withIpToken(address ipToken) public returns (JosephBuilder) {
        builderData.ipToken = ipToken;
        return this;
    }

    function withMilton(address milton) public returns (JosephBuilder) {
        builderData.milton = milton;
        return this;
    }

    function withMiltonStorage(address miltonStorage) public returns (JosephBuilder) {
        builderData.miltonStorage = miltonStorage;
        return this;
    }

    function withStanley(address stanley) public returns (JosephBuilder) {
        builderData.stanley = stanley;
        return this;
    }

    function withJosephImplementation(address josephImplementation) public returns (JosephBuilder) {
        builderData.josephImplementation = josephImplementation;
        return this;
    }

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function isSetIpToken() public view returns (bool) {
        return builderData.ipToken != address(0);
    }

    function isSetMiltonStorage() public view returns (bool) {
        return builderData.miltonStorage != address(0);
    }

    function isSetMilton() public view returns (bool) {
        return builderData.milton != address(0);
    }

    function isSetStanley() public view returns (bool) {
        return builderData.stanley != address(0);
    }

    function build() public returns (ItfJoseph) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(_buildJosephImplementation());
        ItfJoseph joseph = ItfJoseph(address(proxy));
        vm.stopPrank();
        delete builderData;
        return joseph;
    }

    function _buildJosephImplementation() internal returns (address josephImpl) {
        if (builderData.josephImplementation != address(0)) {
            josephImpl = builderData.josephImplementation;
        } else {
            if (builderData.assetType == BuilderUtils.AssetType.DAI) {
                josephImpl = address(new ItfJoseph(18, false));
            } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
                josephImpl = address(new ItfJoseph(6, false));
            } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
                josephImpl = address(new ItfJoseph(6, false));
            } else {
                revert("Asset type not supported");
            }
        }
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                builderData.paused,
                builderData.asset,
                builderData.ipToken,
                builderData.milton,
                builderData.miltonStorage,
                builderData.stanley
            )
        );
    }
}

