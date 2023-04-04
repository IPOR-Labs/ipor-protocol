// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../contracts/mocks/tokens/MockTestnetToken.sol";
import "../contracts/mocks/stanley/MockTestnetStrategy.sol";
import "../contracts/tokens/IpToken.sol";
import "../contracts/tokens/IvToken.sol";
import "../contracts/itf/ItfMiltonSpreadModelDai.sol";
import "../contracts/itf/ItfMiltonSpreadModelUsdc.sol";
import "../contracts/itf/ItfMiltonSpreadModelUsdt.sol";
import "../contracts/itf/ItfIporOracle.sol";
import "../contracts/amm/MiltonStorage.sol";
import "../contracts/itf/ItfStanley.sol";
import "../contracts/itf/ItfStanleyUsdt.sol";
import "../contracts/itf/ItfStanleyUsdc.sol";
import "../contracts/itf/ItfStanleyDai.sol";
import "../contracts/itf/ItfMilton.sol";
import "../contracts/itf/ItfMiltonUsdt.sol";
import "../contracts/itf/ItfMiltonUsdc.sol";
import "../contracts/itf/ItfMiltonDai.sol";
import "../contracts/itf/ItfJoseph.sol";
import "../contracts/itf/ItfJosephUsdt.sol";
import "../contracts/itf/ItfJosephUsdc.sol";
import "../contracts/itf/ItfJosephDai.sol";
import "../contracts/facades/IporOracleFacadeDataProvider.sol";
import "../contracts/facades/MiltonFacadeDataProvider.sol";
import "../contracts/facades/cockpit/CockpitDataProvider.sol";
import "../contracts/itf/ItfDataProvider.sol";
import "../contracts/itf/ItfLiquidator.sol";
import "./Diploy-itf.s.sol";
import "../contracts/mocks/Multicall2.sol";
import "../contracts/tokens/IporToken.sol";
import "../contracts/mocks/TestnetFaucet.sol";
import "../contracts/mocks/MockIporWeighted.sol";

// anvil --timestamp 1585899838
//forge script script/Diploy-itf.s.sol:DeployItf --fork-url http://localhost:8545 --broadcast
contract DeployItf is Script {
    uint256 internal _initialSupply6Decimals = 1_000_000_000_000_000000;
    uint256 internal _initialSupply18Decimals = 1_000_000_000_000_000000000000000000;

    struct Amm {
        SpreadModel spreadModel;
        Tokens tokens;
        ItfIporOracle iporOracle;
        MiltonStorages miltonStorages;
        StanleyType stanley;
        Miltons miltons;
        Josephes josephes;
        IporOracleFacadeDataProvider iporOracleFacadeDataProvider;
        MiltonFacadeDataProvider miltonFacadeDataProvider;
        CockpitDataProvider cockpitDataProvider;
        ItfDataProvider itfDataProvider;
        ItfLiquidators itfLiquidators;
        address multicall2;
        TestnetFaucet testnetFaucet;
    }

    struct TokensMocks {
        MockTestnetToken USDT;
        MockTestnetToken USDC;
        MockTestnetToken DAI;
        MockTestnetToken aUSDT;
        MockTestnetToken aUSDC;
        MockTestnetToken aDAI;
        MockTestnetToken cUSDT;
        MockTestnetToken cUSDC;
        MockTestnetToken cDAI;
    }

    struct StrategiesMocks {
        address mockTestnetStrategyAaveUsdtImplementation;
        address mockTestnetStrategyAaveUsdtProxy;
        address mockTestnetStrategyAaveUsdcImplementation;
        address mockTestnetStrategyAaveUsdcProxy;
        address mockTestnetStrategyAaveDaiImplementation;
        address mockTestnetStrategyAaveDaiProxy;
        address mockTestnetStrategyCompoundUsdtImplementation;
        address mockTestnetStrategyCompoundUsdtProxy;
        address mockTestnetStrategyCompoundUsdcImplementation;
        address mockTestnetStrategyCompoundUsdcProxy;
        address mockTestnetStrategyCompoundDaiImplementation;
        address mockTestnetStrategyCompoundDaiProxy;
    }

    struct Mocks {
        TokensMocks tokens;
        StrategiesMocks strategies;
        MockIporWeighted iporAlgorithm;
    }

    struct Tokens {
        IpToken ipUSDT;
        IpToken ipUSDC;
        IpToken ipDAI;
        IvToken ivUSDT;
        IvToken ivUSDC;
        IvToken ivDAI;
        IporToken IPOR;
    }

    struct MiltonStorages {
        MiltonStorage usdt;
        MiltonStorage usdc;
        MiltonStorage dai;
    }

    struct StanleyType {
        ItfStanley usdt;
        ItfStanley usdc;
        ItfStanley dai;
    }

    struct Miltons {
        ItfMilton usdt;
        ItfMilton usdc;
        ItfMilton dai;
    }

    struct Josephes {
        ItfJoseph usdt;
        ItfJoseph usdc;
        ItfJoseph dai;
    }

    struct ItfLiquidators {
        ItfLiquidator usdt;
        ItfLiquidator usdc;
        ItfLiquidator dai;
    }

    function run() external {
        console2.log("block.timestamp start: ", block.timestamp);
        uint256 deployerPrivateKey = vm.envUint("SC_ADMIN_PRIV_KEY");
        Mocks memory mocks;
        Amm memory amm;
        vm.startBroadcast(deployerPrivateKey);
        mocks.tokens = _createTokensMocks();
        mocks.strategies = _createStrategyMocks(mocks.tokens);
        amm.tokens = _createTokens(mocks);
        amm.spreadModel = _createSpreadModel();
        amm.iporOracle = _createIporOracle(mocks);
        amm.miltonStorages = _createMiltonStorage(mocks);
        amm.stanley = _createStanley(mocks, amm);
        amm.miltons = _createMiltons(mocks, amm);
        amm.josephes = _createJosephes(mocks, amm);
        amm.iporOracleFacadeDataProvider = _createIporOracleFacadeDataProvider(mocks, amm);
        amm.miltonFacadeDataProvider = _createMiltonFacadeDataProvider(mocks, amm);
        amm.cockpitDataProvider = _createCockpitDataProvider(mocks, amm);
        _setupIpToken(amm);
        _setupIvToken(amm);
        _setupMilton(amm);
        _setupMiltonStorage(amm);
        _setupStanley(amm);
        _setupIporOracle(amm);
        _setupTestnetStrategy(amm, mocks);

        amm.itfDataProvider = _createItfDataProvider(amm, mocks);
        amm.itfLiquidators = _createItfLiquidators(amm);
        amm.multicall2 = _createMulticall2();
        amm.tokens.IPOR = _createIPOR();
        amm.testnetFaucet = _createTestnetFaucet(amm, mocks);
        mocks.iporAlgorithm = _createAndSetupIporAlgorithm(amm);
        vm.stopBroadcast();

        console2.log("block.timestamp end: ", block.timestamp);
    }

    function _createTokensMocks() internal returns (TokensMocks memory tokensMocks) {
        TokensMocks memory tokensMocks;
        tokensMocks.USDT = new MockTestnetToken("Mocked USDT", "USDT", _initialSupply6Decimals, 6);
        tokensMocks.USDC = new MockTestnetToken("Mocked USDC", "USDC", _initialSupply6Decimals, 6);
        tokensMocks.DAI = new MockTestnetToken("Mocked DAI", "DAI", _initialSupply18Decimals, 18);
        tokensMocks.aUSDT = new MockTestnetToken(
            "Mocked Share aUSDT",
            "aUSDT",
            _initialSupply6Decimals,
            6
        );
        tokensMocks.aUSDC = new MockTestnetToken(
            "Mocked Share aUSDC",
            "aUSDC",
            _initialSupply6Decimals,
            6
        );
        tokensMocks.aDAI = new MockTestnetToken(
            "Mocked Share aDAI",
            "aDAI",
            _initialSupply18Decimals,
            18
        );
        tokensMocks.cUSDT = new MockTestnetToken(
            "Mocked Share cUSDT",
            "cUSDT",
            _initialSupply6Decimals,
            6
        );
        tokensMocks.cUSDC = new MockTestnetToken(
            "Mocked Share cUSDC",
            "cUSDC",
            _initialSupply6Decimals,
            6
        );
        tokensMocks.cDAI = new MockTestnetToken(
            "Mocked Share cDAI",
            "cDAI",
            _initialSupply18Decimals,
            18
        );
        console2.log("USDT: ", address(tokensMocks.USDT));
        console2.log("USDC: ", address(tokensMocks.USDC));
        console2.log("DAI: ", address(tokensMocks.DAI));
        console2.log("aUSDT: ", address(tokensMocks.aUSDT));
        console2.log("aUSDC: ", address(tokensMocks.aUSDC));
        console2.log("aDAI: ", address(tokensMocks.aDAI));
        console2.log("cUSDT: ", address(tokensMocks.cUSDT));
        console2.log("cUSDC: ", address(tokensMocks.cUSDC));
        console2.log("cDAI: ", address(tokensMocks.cDAI));
        return tokensMocks;
    }

    function _createStrategyMocks(TokensMocks memory tokensMocks)
        internal
        returns (StrategiesMocks memory strategiesMocks)
    {
        MockTestnetStrategy mockTestnetStrategyAaveUsdtImplementation = new MockTestnetStrategy();
        ERC1967Proxy mockTestnetStrategyAaveUsdtProxy = new ERC1967Proxy(
            address(mockTestnetStrategyAaveUsdtImplementation),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(tokensMocks.USDT),
                address(tokensMocks.aUSDT)
            )
        );

        MockTestnetStrategy mockTestnetStrategyAaveUsdcImplementation = new MockTestnetStrategy();
        ERC1967Proxy mockTestnetStrategyAaveUsdcProxy = new ERC1967Proxy(
            address(mockTestnetStrategyAaveUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(tokensMocks.USDC),
                address(tokensMocks.aUSDC)
            )
        );

        MockTestnetStrategy mockTestnetStrategyAaveDaiImplementation = new MockTestnetStrategy();
        ERC1967Proxy mockTestnetStrategyAaveDaiProxy = new ERC1967Proxy(
            address(mockTestnetStrategyAaveDaiImplementation),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(tokensMocks.DAI),
                address(tokensMocks.aDAI)
            )
        );

        MockTestnetStrategy mockTestnetStrategyCompoundUsdtImplementation = new MockTestnetStrategy();
        ERC1967Proxy mockTestnetStrategyCompoundUsdtProxy = new ERC1967Proxy(
            address(mockTestnetStrategyCompoundUsdtImplementation),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(tokensMocks.USDT),
                address(tokensMocks.cUSDT)
            )
        );

        MockTestnetStrategy mockTestnetStrategyCompoundUsdcImplementation = new MockTestnetStrategy();
        ERC1967Proxy mockTestnetStrategyCompoundUsdcProxy = new ERC1967Proxy(
            address(mockTestnetStrategyCompoundUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(tokensMocks.USDC),
                address(tokensMocks.cUSDC)
            )
        );

        MockTestnetStrategy mockTestnetStrategyCompoundDaiImplementation = new MockTestnetStrategy();
        ERC1967Proxy mockTestnetStrategyCompoundDaiProxy = new ERC1967Proxy(
            address(mockTestnetStrategyCompoundDaiImplementation),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(tokensMocks.DAI),
                address(tokensMocks.cDAI)
            )
        );
        console2.log("strategyAaveUsdtProxy: ", address(mockTestnetStrategyAaveUsdtProxy));
        console2.log("strategyAaveUsdcProxy: ", address(mockTestnetStrategyAaveUsdcProxy));
        console2.log("strategyAaveDaiProxy: ", address(mockTestnetStrategyAaveDaiProxy));
        console2.log("strategyCompoundUsdtProxy: ", address(mockTestnetStrategyCompoundUsdtProxy));
        console2.log("strategyCompoundUsdcProxy: ", address(mockTestnetStrategyCompoundUsdcProxy));
        console2.log("strategyCompoundDaiProxy: ", address(mockTestnetStrategyCompoundDaiProxy));
        strategiesMocks = StrategiesMocks(
            address(mockTestnetStrategyAaveUsdtImplementation),
            address(mockTestnetStrategyAaveUsdtProxy),
            address(mockTestnetStrategyAaveUsdcImplementation),
            address(mockTestnetStrategyAaveUsdcProxy),
            address(mockTestnetStrategyAaveDaiImplementation),
            address(mockTestnetStrategyAaveDaiProxy),
            address(mockTestnetStrategyCompoundUsdtImplementation),
            address(mockTestnetStrategyCompoundUsdtProxy),
            address(mockTestnetStrategyCompoundUsdcImplementation),
            address(mockTestnetStrategyCompoundUsdcProxy),
            address(mockTestnetStrategyCompoundDaiImplementation),
            address(mockTestnetStrategyCompoundDaiProxy)
        );
    }

    function _createTokens(Mocks memory mocks) internal returns (Tokens memory tokens) {
        tokens.ipUSDT = new IpToken("IP USDT", "ipUSDT", address(mocks.tokens.USDT));
        tokens.ipUSDC = new IpToken("IP USDC", "ipUSDC", address(mocks.tokens.USDC));
        tokens.ipDAI = new IpToken("IP DAI", "ipDAI", address(mocks.tokens.DAI));
        tokens.ivDAI = new IvToken("IV DAI", "ivDAI", address(mocks.tokens.DAI));
        tokens.ivUSDC = new IvToken("IV USDC", "ivUSDC", address(mocks.tokens.USDC));
        tokens.ivUSDT = new IvToken("IV USDT", "ivUSDT", address(mocks.tokens.USDT));
        console2.log("ipUSDT: ", address(tokens.ipUSDT));
        console2.log("ipUSDC: ", address(tokens.ipUSDC));
        console2.log("ipDAI: ", address(tokens.ipDAI));
        console2.log("ivUSDT: ", address(tokens.ivUSDT));
        console2.log("ivUSDC: ", address(tokens.ivUSDC));
        console2.log("ivDAI: ", address(tokens.ivDAI));
    }

    struct SpreadModel {
        ItfMiltonSpreadModelUsdt usdt;
        ItfMiltonSpreadModelUsdc usdc;
        ItfMiltonSpreadModelDai dai;
    }

    function _createSpreadModel() internal returns (SpreadModel memory spreadModel) {
        spreadModel.usdt = new ItfMiltonSpreadModelUsdt();
        spreadModel.usdc = new ItfMiltonSpreadModelUsdc();
        spreadModel.dai = new ItfMiltonSpreadModelDai();
        console2.log("spreadModelUsdt: ", address(spreadModel.usdt));
        console2.log("spreadModelUsdc: ", address(spreadModel.usdc));
        console2.log("spreadModelDai: ", address(spreadModel.dai));
    }

    function _createIporOracle(Mocks memory mocks) internal returns (ItfIporOracle iporOracle) {
        ItfIporOracle iporOracleImplementation = new ItfIporOracle();
        address[] memory assets = new address[](3);
        assets[0] = address(mocks.tokens.DAI);
        assets[1] = address(mocks.tokens.USDC);
        assets[2] = address(mocks.tokens.USDT);

        uint32[] memory updateTimestamps = new uint32[](3);
        updateTimestamps[0] = uint32(block.timestamp);
        updateTimestamps[1] = uint32(block.timestamp);
        updateTimestamps[2] = uint32(block.timestamp);

        uint64[] memory exponentialMovingAverages = new uint64[](3);
        exponentialMovingAverages[0] = uint64(32706669664256327);
        exponentialMovingAverages[1] = uint64(32706669664256327);
        exponentialMovingAverages[2] = uint64(32706669664256327);

        uint64[] memory exponentialWeightedMovingVariances = new uint64[](3);

        exponentialWeightedMovingVariances[0] = uint64(49811986068491);
        exponentialWeightedMovingVariances[1] = uint64(49811986068491);
        exponentialWeightedMovingVariances[2] = uint64(49811986068491);

        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(
            address(iporOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],uint32[],uint64[],uint64[])",
                assets,
                updateTimestamps,
                exponentialMovingAverages,
                exponentialWeightedMovingVariances
            )
        );
        console2.log("iporOracleProxy: ", address(iporOracleProxy));
        console2.log("block.timestamp: ", block.timestamp);
        iporOracle = ItfIporOracle(address(iporOracleProxy));
    }

    function _createMiltonStorage(Mocks memory mocks)
        internal
        returns (MiltonStorages memory miltonStorage)
    {
        MiltonStorage miltonStorageUsdtImplementation = new MiltonStorage();
        ERC1967Proxy miltonStorageUsdtProxy = new ERC1967Proxy(
            address(miltonStorageUsdtImplementation),
            abi.encodeWithSignature("initialize()")
        );
        MiltonStorage miltonStorageUsdcImplementation = new MiltonStorage();
        ERC1967Proxy miltonStorageUsdcProxy = new ERC1967Proxy(
            address(miltonStorageUsdcImplementation),
            abi.encodeWithSignature("initialize()")
        );
        MiltonStorage miltonStorageDaiImplementation = new MiltonStorage();
        ERC1967Proxy miltonStorageDaiProxy = new ERC1967Proxy(
            address(miltonStorageDaiImplementation),
            abi.encodeWithSignature("initialize()")
        );
        miltonStorage.usdt = MiltonStorage(address(miltonStorageUsdtProxy));
        miltonStorage.usdc = MiltonStorage(address(miltonStorageUsdcProxy));
        miltonStorage.dai = MiltonStorage(address(miltonStorageDaiProxy));

        console2.log("miltonStorageUsdtProxy: ", address(miltonStorageUsdtProxy));
        console2.log("miltonStorageUsdcProxy: ", address(miltonStorageUsdcProxy));
        console2.log("miltonStorageDaiProxy: ", address(miltonStorageDaiProxy));
    }

    function _createStanley(Mocks memory mocks, Amm memory amm)
        internal
        returns (StanleyType memory stanley)
    {
        ItfStanleyUsdt stanleyUsdtImplementation = new ItfStanleyUsdt();
        ERC1967Proxy stanleyUsdtProxy = new ERC1967Proxy(
            address(stanleyUsdtImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(mocks.tokens.USDT),
                address(amm.tokens.ivUSDT),
                address(mocks.strategies.mockTestnetStrategyAaveUsdtProxy),
                address(mocks.strategies.mockTestnetStrategyCompoundUsdtProxy)
            )
        );

        ItfStanleyUsdc stanleyUsdcImplementation = new ItfStanleyUsdc();
        ERC1967Proxy stanleyUsdcProxy = new ERC1967Proxy(
            address(stanleyUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(mocks.tokens.USDC),
                address(amm.tokens.ivUSDC),
                address(mocks.strategies.mockTestnetStrategyAaveUsdcProxy),
                address(mocks.strategies.mockTestnetStrategyCompoundUsdcProxy)
            )
        );

        ItfStanleyDai stanleyDaiImplementation = new ItfStanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
            address(stanleyDaiImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(mocks.tokens.DAI),
                address(amm.tokens.ivDAI),
                address(mocks.strategies.mockTestnetStrategyAaveDaiProxy),
                address(mocks.strategies.mockTestnetStrategyCompoundDaiProxy)
            )
        );

        stanley.usdt = ItfStanley(address(stanleyUsdtProxy));
        stanley.usdc = ItfStanley(address(stanleyUsdcProxy));
        stanley.dai = ItfStanley(address(stanleyDaiProxy));

        console2.log("stanleyUsdtProxy: ", address(stanleyUsdtProxy));
        console2.log("stanleyUsdcProxy: ", address(stanleyUsdcProxy));
        console2.log("stanleyDaiProxy: ", address(stanleyDaiProxy));
    }

    function _createMiltons(Mocks memory mocks, Amm memory amm)
        internal
        returns (Miltons memory miltons)
    {
        ItfMiltonUsdt miltonUsdtImplementation = new ItfMiltonUsdt();
        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(miltonUsdtImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(mocks.tokens.USDT),
                address(amm.iporOracle),
                address(amm.miltonStorages.usdt),
                address(amm.spreadModel.usdt),
                address(amm.stanley.usdt)
            )
        );

        ItfMiltonUsdc miltonUsdcImplementation = new ItfMiltonUsdc();
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(miltonUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(mocks.tokens.USDC),
                address(amm.iporOracle),
                address(amm.miltonStorages.usdc),
                address(amm.spreadModel.usdc),
                address(amm.stanley.usdc)
            )
        );

        ItfMiltonDai miltonDaiImplementation = new ItfMiltonDai();
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(miltonDaiImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(mocks.tokens.DAI),
                address(amm.iporOracle),
                address(amm.miltonStorages.dai),
                address(amm.spreadModel.dai),
                address(amm.stanley.dai)
            )
        );

        miltons.usdt = ItfMilton(address(miltonUsdtProxy));
        miltons.usdc = ItfMilton(address(miltonUsdcProxy));
        miltons.dai = ItfMilton(address(miltonDaiProxy));

        console2.log("miltonUsdtProxy: ", address(miltonUsdtProxy));
        console2.log("miltonUsdcProxy: ", address(miltonUsdcProxy));
        console2.log("miltonDaiProxy: ", address(miltonDaiProxy));
    }

    function _createJosephes(Mocks memory mocks, Amm memory amm)
        internal
        returns (Josephes memory josephes)
    {
        ItfJosephUsdt josephUsdtImplementation = new ItfJosephUsdt();
        ERC1967Proxy josephUsdtProxy = new ERC1967Proxy(
            address(josephUsdtImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(mocks.tokens.USDT),
                address(amm.tokens.ipUSDT),
                address(amm.miltons.usdt),
                address(amm.miltonStorages.usdt),
                address(amm.stanley.usdt)
            )
        );

        ItfJosephUsdc josephUsdcImplementation = new ItfJosephUsdc();
        ERC1967Proxy josephUsdcProxy = new ERC1967Proxy(
            address(josephUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(mocks.tokens.USDC),
                address(amm.tokens.ipUSDC),
                address(amm.miltons.usdc),
                address(amm.miltonStorages.usdc),
                address(amm.stanley.usdc)
            )
        );

        ItfJosephDai josephDaiImplementation = new ItfJosephDai();
        ERC1967Proxy josephDaiProxy = new ERC1967Proxy(
            address(josephDaiImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(mocks.tokens.DAI),
                address(amm.tokens.ipDAI),
                address(amm.miltons.dai),
                address(amm.miltonStorages.dai),
                address(amm.stanley.dai)
            )
        );

        josephes.usdt = ItfJoseph(address(josephUsdtProxy));
        josephes.usdc = ItfJoseph(address(josephUsdcProxy));
        josephes.dai = ItfJoseph(address(josephDaiProxy));

        console2.log("josephUsdtProxy: ", address(josephUsdtProxy));
        console2.log("josephUsdcProxy: ", address(josephUsdcProxy));
        console2.log("josephDaiProxy: ", address(josephDaiProxy));
    }

    function _createIporOracleFacadeDataProvider(Mocks memory mocks, Amm memory amm)
        internal
        returns (IporOracleFacadeDataProvider iporOracleFacadeDataProvider)
    {
        address[] memory assets = new address[](3);
        assets[0] = address(mocks.tokens.DAI);
        assets[1] = address(mocks.tokens.USDC);
        assets[2] = address(mocks.tokens.USDT);

        IporOracleFacadeDataProvider iporOracleFacadeDataProviderImplementation = new IporOracleFacadeDataProvider();
        ERC1967Proxy iporOracleFacadeDataProviderProxy = new ERC1967Proxy(
            address(iporOracleFacadeDataProviderImplementation),
            abi.encodeWithSignature(
                "initialize(address[],address)",
                assets,
                address(amm.iporOracle)
            )
        );

        iporOracleFacadeDataProvider = IporOracleFacadeDataProvider(
            address(iporOracleFacadeDataProviderProxy)
        );
        console2.log(
            "iporOracleFacadeDataProviderProxy: ",
            address(iporOracleFacadeDataProviderProxy)
        );
    }

    function _createMiltonFacadeDataProvider(Mocks memory mocks, Amm memory amm)
        internal
        returns (MiltonFacadeDataProvider miltonFacadeDataProvider)
    {
        address[] memory assets = new address[](3);
        assets[0] = address(mocks.tokens.DAI);
        assets[1] = address(mocks.tokens.USDC);
        assets[2] = address(mocks.tokens.USDT);
        address[] memory miltons = new address[](3);
        miltons[0] = address(amm.miltons.dai);
        miltons[1] = address(amm.miltons.usdc);
        miltons[2] = address(amm.miltons.usdt);
        address[] memory miltonStorages = new address[](3);
        miltonStorages[0] = address(amm.miltonStorages.dai);
        miltonStorages[1] = address(amm.miltonStorages.usdc);
        miltonStorages[2] = address(amm.miltonStorages.usdt);
        address[] memory josephs = new address[](3);
        josephs[0] = address(amm.josephes.dai);
        josephs[1] = address(amm.josephes.usdc);
        josephs[2] = address(amm.josephes.usdt);

        MiltonFacadeDataProvider miltonFacadeDataProviderImplementation = new MiltonFacadeDataProvider();
        ERC1967Proxy miltonFacadeDataProviderProxy = new ERC1967Proxy(
            address(miltonFacadeDataProviderImplementation),
            abi.encodeWithSignature(
                "initialize(address,address[],address[],address[],address[])",
                address(amm.iporOracle),
                assets,
                miltons,
                miltonStorages,
                josephs
            )
        );

        miltonFacadeDataProvider = MiltonFacadeDataProvider(address(miltonFacadeDataProviderProxy));
        console2.log("miltonFacadeDataProviderProxy: ", address(miltonFacadeDataProviderProxy));
    }

    function _createCockpitDataProvider(Mocks memory mocks, Amm memory amm)
        internal
        returns (CockpitDataProvider cockpitDataProvider)
    {
        address[] memory assets = new address[](3);
        assets[0] = address(mocks.tokens.DAI);
        assets[1] = address(mocks.tokens.USDC);
        assets[2] = address(mocks.tokens.USDT);
        address[] memory miltons = new address[](3);
        miltons[0] = address(amm.miltons.dai);
        miltons[1] = address(amm.miltons.usdc);
        miltons[2] = address(amm.miltons.usdt);
        address[] memory miltonStorages = new address[](3);
        miltonStorages[0] = address(amm.miltonStorages.dai);
        miltonStorages[1] = address(amm.miltonStorages.usdc);
        miltonStorages[2] = address(amm.miltonStorages.usdt);
        address[] memory josephs = new address[](3);
        josephs[0] = address(amm.josephes.dai);
        josephs[1] = address(amm.josephes.usdc);
        josephs[2] = address(amm.josephes.usdt);
        address[] memory ipTokens = new address[](3);
        ipTokens[0] = address(amm.tokens.ipDAI);
        ipTokens[1] = address(amm.tokens.ipUSDC);
        ipTokens[2] = address(amm.tokens.ipUSDT);
        address[] memory ivTokens = new address[](3);
        ivTokens[0] = address(amm.tokens.ivDAI);
        ivTokens[1] = address(amm.tokens.ivUSDC);
        ivTokens[2] = address(amm.tokens.ivUSDT);

        CockpitDataProvider cockpitDataProviderImplementation = new CockpitDataProvider();
        ERC1967Proxy cockpitDataProviderProxy = new ERC1967Proxy(
            address(cockpitDataProviderImplementation),
            abi.encodeWithSignature(
                "initialize(address,address[],address[],address[],address[],address[],address[])",
                address(amm.iporOracle),
                assets,
                miltons,
                miltonStorages,
                josephs,
                ipTokens,
                ivTokens
            )
        );

        cockpitDataProvider = CockpitDataProvider(address(cockpitDataProviderProxy));
        console2.log("cockpitDataProviderProxy: ", address(cockpitDataProviderProxy));
    }

    function _setupIpToken(Amm memory amm) internal {
        amm.tokens.ipDAI.setJoseph(address(amm.josephes.dai));
        amm.tokens.ipUSDC.setJoseph(address(amm.josephes.usdc));
        amm.tokens.ipUSDT.setJoseph(address(amm.josephes.usdt));
    }

    function _setupIvToken(Amm memory amm) internal {
        amm.tokens.ivDAI.setStanley(address(amm.stanley.dai));
        amm.tokens.ivUSDC.setStanley(address(amm.stanley.usdc));
        amm.tokens.ivUSDT.setStanley(address(amm.stanley.usdt));
    }

    function _setupMilton(Amm memory amm) internal {
        Milton miltonDai = amm.miltons.dai;
        Milton miltonUsdc = amm.miltons.usdc;
        Milton miltonUsdt = amm.miltons.usdt;

        miltonDai.setJoseph(address(amm.josephes.dai));
        miltonDai.setupMaxAllowanceForAsset(address(amm.josephes.dai));
        miltonDai.setupMaxAllowanceForAsset(address(amm.stanley.dai));

        miltonUsdc.setJoseph(address(amm.josephes.usdc));
        miltonUsdc.setupMaxAllowanceForAsset(address(amm.josephes.usdc));
        miltonUsdc.setupMaxAllowanceForAsset(address(amm.stanley.usdc));

        miltonUsdt.setJoseph(address(amm.josephes.usdt));
        miltonUsdt.setupMaxAllowanceForAsset(address(amm.josephes.usdt));
        miltonUsdt.setupMaxAllowanceForAsset(address(amm.stanley.usdt));
    }

    function _setupMiltonStorage(Amm memory amm) internal {
        MiltonStorage miltonStorageDai = amm.miltonStorages.dai;
        MiltonStorage miltonStorageUsdc = amm.miltonStorages.usdc;
        MiltonStorage miltonStorageUsdt = amm.miltonStorages.usdt;

        miltonStorageDai.setMilton(address(amm.miltons.dai));
        miltonStorageUsdc.setMilton(address(amm.miltons.usdc));
        miltonStorageUsdt.setMilton(address(amm.miltons.usdt));

        miltonStorageDai.setJoseph(address(amm.josephes.dai));
        miltonStorageUsdc.setJoseph(address(amm.josephes.usdc));
        miltonStorageUsdt.setJoseph(address(amm.josephes.usdt));
    }

    function _setupStanley(Amm memory amm) internal {
        amm.stanley.dai.setMilton(address(amm.miltons.dai));
        amm.stanley.usdc.setMilton(address(amm.miltons.usdc));
        amm.stanley.usdt.setMilton(address(amm.miltons.usdt));
    }

    function _setupIporOracle(Amm memory amm) internal {
        address updater = vm.envAddress("SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS");
        address owner = vm.envAddress("SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS");

        amm.iporOracle.addUpdater(owner);
        amm.iporOracle.addUpdater(updater);
    }

    function _setupTestnetStrategy(Amm memory amm, Mocks memory mocks) internal {
        StrategyCore(mocks.strategies.mockTestnetStrategyAaveDaiProxy).setStanley(
            address(amm.stanley.dai)
        );
        StrategyCore(mocks.strategies.mockTestnetStrategyAaveUsdcProxy).setStanley(
            address(amm.stanley.usdc)
        );
        StrategyCore(mocks.strategies.mockTestnetStrategyAaveUsdtProxy).setStanley(
            address(amm.stanley.usdt)
        );

        StrategyCore(mocks.strategies.mockTestnetStrategyCompoundDaiProxy).setStanley(
            address(amm.stanley.dai)
        );
        StrategyCore(mocks.strategies.mockTestnetStrategyCompoundUsdcProxy).setStanley(
            address(amm.stanley.usdc)
        );
        StrategyCore(mocks.strategies.mockTestnetStrategyCompoundUsdtProxy).setStanley(
            address(amm.stanley.usdt)
        );

        mocks.tokens.DAI.transfer(
            address(mocks.strategies.mockTestnetStrategyAaveDaiProxy),
            1_000_000_000000000000000000
        );
        mocks.tokens.USDC.transfer(
            address(mocks.strategies.mockTestnetStrategyAaveUsdcProxy),
            1_000_000_000000
        );
        mocks.tokens.USDT.transfer(
            address(mocks.strategies.mockTestnetStrategyAaveUsdtProxy),
            1_000_000_000000
        );

        mocks.tokens.DAI.transfer(
            address(mocks.strategies.mockTestnetStrategyCompoundDaiProxy),
            1_000_000_000000000000000000
        );
        mocks.tokens.USDC.transfer(
            address(mocks.strategies.mockTestnetStrategyCompoundUsdcProxy),
            1_000_000_000000
        );
        mocks.tokens.USDT.transfer(
            address(mocks.strategies.mockTestnetStrategyCompoundUsdtProxy),
            1_000_000_000000
        );
    }

    function _createItfDataProvider(Amm memory amm, Mocks memory mocks)
        internal
        returns (ItfDataProvider itfDataProvider)
    {
        address[] memory assets = new address[](3);
        assets[0] = address(mocks.tokens.DAI);
        assets[1] = address(mocks.tokens.USDC);
        assets[2] = address(mocks.tokens.USDT);
        address[] memory miltons = new address[](3);
        miltons[0] = address(amm.miltons.dai);
        miltons[1] = address(amm.miltons.usdc);
        miltons[2] = address(amm.miltons.usdt);
        address[] memory miltonStorages = new address[](3);
        miltonStorages[0] = address(amm.miltonStorages.dai);
        miltonStorages[1] = address(amm.miltonStorages.usdc);
        miltonStorages[2] = address(amm.miltonStorages.usdt);
        address[] memory josephs = new address[](3);
        josephs[0] = address(amm.josephes.dai);
        josephs[1] = address(amm.josephes.usdc);
        josephs[2] = address(amm.josephes.usdt);
        address[] memory miltonSpreadModels = new address[](3);
        miltonSpreadModels[0] = address(amm.spreadModel.dai);
        miltonSpreadModels[1] = address(amm.spreadModel.usdc);
        miltonSpreadModels[2] = address(amm.spreadModel.usdt);

        ItfDataProvider itfDataProviderImplementation = new ItfDataProvider();

        ERC1967Proxy itfDataProviderProxy = new ERC1967Proxy(
            address(itfDataProviderImplementation),
            abi.encodeWithSignature(
                "initialize(address[],address[],address[],address,address[])",
                assets,
                miltons,
                miltonStorages,
                address(amm.iporOracle),
                miltonSpreadModels
            )
        );

        itfDataProvider = ItfDataProvider(address(itfDataProviderProxy));
        console2.log("itfDataProvider", address(itfDataProvider));
    }

    function _createItfLiquidators(Amm memory amm)
        internal
        returns (ItfLiquidators memory itfLiquidators)
    {
        itfLiquidators.dai = new ItfLiquidator(
            address(amm.miltons.dai),
            address(amm.miltonStorages.dai)
        );
        itfLiquidators.usdc = new ItfLiquidator(
            address(amm.miltons.usdc),
            address(amm.miltonStorages.usdc)
        );
        itfLiquidators.usdt = new ItfLiquidator(
            address(amm.miltons.usdt),
            address(amm.miltonStorages.usdt)
        );

        console2.log("itfLiquidators.dai", address(itfLiquidators.dai));
        console2.log("itfLiquidators.usdc", address(itfLiquidators.usdc));
        console2.log("itfLiquidators.usdt", address(itfLiquidators.usdt));
    }

    function _createMulticall2() internal returns (address multicall) {
        multicall = address(new Multicall2());
        console2.log("multicall", multicall);
    }

    function _createIPOR() internal returns (IporToken ipor) {
        address owner = vm.envAddress("SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS");

        ipor = new IporToken("IPOR Token", "IPOR", owner);
        console2.log("ipor", address(ipor));

        console2.log("ipor", address(ipor));
    }

    function _createTestnetFaucet(Amm memory amm, Mocks memory mocks)
        internal
        returns (TestnetFaucet testnetFaucet)
    {
        TestnetFaucet testnetFaucet = new TestnetFaucet();

        address owner = vm.envAddress("SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS");
        mocks.tokens.DAI.transfer(address(testnetFaucet), 1_000_000_000000000000000000);
        mocks.tokens.USDC.transfer(address(testnetFaucet), 1_000_000_000000);
        mocks.tokens.USDT.transfer(address(testnetFaucet), 1_000_000_000000);

        console2.log("testnetFaucet", address(testnetFaucet));
    }

    function _createAndSetupIporAlgorithm(Amm memory amm)
        internal
        returns (MockIporWeighted iporAlgorithm)
    {
        MockIporWeighted iporAlgorithmImplementation = new MockIporWeighted();
        ERC1967Proxy iporAlgorithmProxy = new ERC1967Proxy(
            address(iporAlgorithmImplementation),
            abi.encodeWithSignature("initialize(address)", address(amm.iporOracle))
        );
        iporAlgorithm = MockIporWeighted(address(iporAlgorithmProxy));
        amm.iporOracle.setIporAlgorithmFacade(address(iporAlgorithm));
        console2.log("iporAlgorithm", address(iporAlgorithm));
    }
}
