import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../contracts/tokens/IpToken.sol";
import "../../../contracts/tokens/IvToken.sol";
import "../../../contracts/itf/ItfStanley.sol";
import "../../../contracts/amm/MiltonStorage.sol";
import "../../../contracts/itf/ItfMilton.sol";
import "../../../contracts/itf/ItfJoseph.sol";
import "../../../contracts/itf/ItfIporOracle.sol";
import "../../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../../contracts/mocks/MockIporWeighted.sol";

import "../builder/AssetBuilder.sol";
import "../builder/IpTokenBuilder.sol";
import "../builder/StanleyBuilder.sol";
import "../builder/MiltonStorageBuilder.sol";
import "../builder/MiltonBuilder.sol";
import "../builder/JosephBuilder.sol";
import "../builder/IporOracleBuilder.sol";
import "../builder/IporWeightedBuilder.sol";
import "forge-std/Test.sol";

contract IporProtocolFactory is Test {
    struct IporProtocol {
        MockTestnetToken asset;
        IpToken ipToken;
        ItfIporOracle iporOracle;
        MiltonStorage miltonStorage;
        MockSpreadModel spreadModel;
        ItfStanley stanley;
        ItfMilton milton;
        ItfJoseph joseph;
    }

    struct TestCaseConfig {
        address iporOracleUpdater;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        BuilderUtils.MiltonTestCase miltonTestCase;
        address[] approvalsForUsers;
    }

    AssetBuilder internal assetBuilder;
    IpTokenBuilder internal ipTokenBuilder;
    IporOracleBuilder internal iporOracleBuilder;
    IporWeightedBuilder internal iporWeightedBuilder;
    MiltonStorageBuilder internal miltonStorageBuilder;
    IvTokenBuilder internal ivTokenBuilder;
    StanleyBuilder internal stanleyBuilder;
    MiltonBuilder internal miltonBuilder;
    JosephBuilder internal josephBuilder;
    MockSpreadBuilder internal mockSpreadBuilder;

    address internal _owner;

    constructor(address owner) {
        assetBuilder = new AssetBuilder(owner);
        ipTokenBuilder = new IpTokenBuilder(owner);
        iporOracleBuilder = new IporOracleBuilder(owner);
        iporWeightedBuilder = new IporWeightedBuilder(owner);
        miltonStorageBuilder = new MiltonStorageBuilder(owner);
        ivTokenBuilder = new IvTokenBuilder(owner);
        stanleyBuilder = new StanleyBuilder(owner);
        miltonBuilder = new MiltonBuilder(owner);
        josephBuilder = new JosephBuilder(owner);
        mockSpreadBuilder = new MockSpreadBuilder(owner);
        _owner = owner;
    }

    function getDaiInstance() public returns (IporProtocol memory iporProtocol) {
        assetBuilder.withDAI();
        iporProtocol.asset = assetBuilder.build();

        ipTokenBuilder.withAsset(address(iporProtocol.asset));
        ipTokenBuilder.withName("IP DAI");
        ipTokenBuilder.withSymbol("ipDAI");
        iporProtocol.ipToken = ipTokenBuilder.build();

        iporOracleBuilder.withAsset(address(iporProtocol.asset));
        iporOracleBuilder.withDefaultIndicators();
        iporProtocol.iporOracle = iporOracleBuilder.build();

        iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle));
        MockIporWeighted iporWeighted = iporWeightedBuilder.build();

        iporProtocol.miltonStorage = miltonStorageBuilder.build();

        mockSpreadBuilder.withDefaultValues();
        iporProtocol.spreadModel = mockSpreadBuilder.build();

        ivTokenBuilder.withAsset(address(iporProtocol.asset));
        ivTokenBuilder.withName("IV DAI");
        ivTokenBuilder.withSymbol("ivDAI");
        IvToken ivToken = ivTokenBuilder.build();

        stanleyBuilder.withAsset(address(iporProtocol.asset));
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        stanleyBuilder.withIvToken(address(ivToken));
        stanleyBuilder.withStrategiesDai();
        iporProtocol.stanley = stanleyBuilder.build();

        miltonBuilder.withAsset(address(iporProtocol.asset));
        miltonBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        miltonBuilder.withIporOracle(address(iporProtocol.iporOracle));
        miltonBuilder.withMiltonStorage(address(iporProtocol.miltonStorage));
        miltonBuilder.withSpreadModel(address(iporProtocol.spreadModel));
        miltonBuilder.withStanley(address(iporProtocol.stanley));
        iporProtocol.milton = miltonBuilder.build();

        josephBuilder.withAsset(address(iporProtocol.asset));
        josephBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        josephBuilder.withIpToken(address(iporProtocol.ipToken));
        josephBuilder.withMilton(address(iporProtocol.milton));
        josephBuilder.withMiltonStorage(address(iporProtocol.miltonStorage));
        josephBuilder.withStanley(address(iporProtocol.stanley));
        iporProtocol.joseph = josephBuilder.build();

        //setup
        vm.startPrank(address(_owner));
        iporProtocol.iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        iporProtocol.ipToken.setJoseph(address(iporProtocol.joseph));
        ivToken.setStanley(address(iporProtocol.stanley));

        iporProtocol.joseph.setMaxLiquidityPoolBalance(1000000000);
        iporProtocol.joseph.setMaxLpAccountContribution(1000000000);
        iporProtocol.miltonStorage.setJoseph(address(iporProtocol.joseph));
        iporProtocol.miltonStorage.setMilton(address(iporProtocol.milton));
        iporProtocol.milton.setJoseph(address(iporProtocol.joseph));
        iporProtocol.milton.setupMaxAllowanceForAsset(address(iporProtocol.joseph));
        iporProtocol.milton.setupMaxAllowanceForAsset(address(iporProtocol.stanley));

        iporProtocol.stanley.setMilton(address(iporProtocol.milton));

        vm.stopPrank();

        return iporProtocol;
    }

    function getDaiInstance(TestCaseConfig memory cfg)
        public
        returns (IporProtocol memory iporProtocol)
    {
        assetBuilder.withDAI();
        iporProtocol.asset = assetBuilder.build();

        ipTokenBuilder.withAsset(address(iporProtocol.asset));
        ipTokenBuilder.withName("IP DAI");
        ipTokenBuilder.withSymbol("ipDAI");
        iporProtocol.ipToken = ipTokenBuilder.build();

        _prepareIporOracleBuilder(address(iporProtocol.asset), cfg);

        iporProtocol.iporOracle = iporOracleBuilder.build();

        iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle));
        MockIporWeighted iporWeighted = iporWeightedBuilder.build();

        iporProtocol.miltonStorage = miltonStorageBuilder.build();

        mockSpreadBuilder.withDefaultValues();
        iporProtocol.spreadModel = mockSpreadBuilder.build();

        ivTokenBuilder.withAsset(address(iporProtocol.asset));
        ivTokenBuilder.withName("IV DAI");
        ivTokenBuilder.withSymbol("ivDAI");
        IvToken ivToken = ivTokenBuilder.build();

        stanleyBuilder.withAsset(address(iporProtocol.asset));
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        stanleyBuilder.withIvToken(address(ivToken));
        stanleyBuilder.withStrategiesDai();
        iporProtocol.stanley = stanleyBuilder.build();

        miltonBuilder.withAsset(address(iporProtocol.asset));
        miltonBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        miltonBuilder.withIporOracle(address(iporProtocol.iporOracle));
        miltonBuilder.withMiltonStorage(address(iporProtocol.miltonStorage));
        miltonBuilder.withSpreadModel(address(iporProtocol.spreadModel));
        miltonBuilder.withStanley(address(iporProtocol.stanley));
        miltonBuilder.withMiltonTestCase(cfg.miltonTestCase);
        iporProtocol.milton = miltonBuilder.build();

        josephBuilder.withAsset(address(iporProtocol.asset));
        josephBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        josephBuilder.withIpToken(address(iporProtocol.ipToken));
        josephBuilder.withMilton(address(iporProtocol.milton));
        josephBuilder.withMiltonStorage(address(iporProtocol.miltonStorage));
        josephBuilder.withStanley(address(iporProtocol.stanley));
        iporProtocol.joseph = josephBuilder.build();

        //setup
        vm.startPrank(address(_owner));
        iporProtocol.iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        iporProtocol.iporOracle.addUpdater(cfg.iporOracleUpdater);

        iporProtocol.ipToken.setJoseph(address(iporProtocol.joseph));
        ivToken.setStanley(address(iporProtocol.stanley));

        iporProtocol.joseph.setMaxLiquidityPoolBalance(1000000000);
        iporProtocol.joseph.setMaxLpAccountContribution(1000000000);
        iporProtocol.miltonStorage.setJoseph(address(iporProtocol.joseph));
        iporProtocol.miltonStorage.setMilton(address(iporProtocol.milton));
        iporProtocol.milton.setJoseph(address(iporProtocol.joseph));
        iporProtocol.milton.setupMaxAllowanceForAsset(address(iporProtocol.joseph));
        iporProtocol.milton.setupMaxAllowanceForAsset(address(iporProtocol.stanley));

        iporProtocol.stanley.setMilton(address(iporProtocol.milton));

        vm.stopPrank();

        for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
            vm.startPrank(cfg.approvalsForUsers[i]);
            iporProtocol.asset.approve(
                address(iporProtocol.joseph),
                TestConstants.TOTAL_SUPPLY_18_DECIMALS
            );
            iporProtocol.asset.approve(
                address(iporProtocol.milton),
                TestConstants.TOTAL_SUPPLY_18_DECIMALS
            );
            vm.stopPrank();
            deal(
                address(iporProtocol.asset),
                cfg.approvalsForUsers[i],
                TestConstants.USER_SUPPLY_10MLN_18DEC
            );
        }

        return iporProtocol;
    }

    function getUsdtInstance(TestCaseConfig memory cfg)
        public
        returns (IporProtocol memory iporProtocol)
    {
        assetBuilder.withUSDT();
        iporProtocol.asset = assetBuilder.build();

        ipTokenBuilder.withAsset(address(iporProtocol.asset));
        ipTokenBuilder.withName("IP USDT");
        ipTokenBuilder.withSymbol("ipUSDT");
        iporProtocol.ipToken = ipTokenBuilder.build();

        _prepareIporOracleBuilder(address(iporProtocol.asset), cfg);

        iporProtocol.iporOracle = iporOracleBuilder.build();

        iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle));
        MockIporWeighted iporWeighted = iporWeightedBuilder.build();

        iporProtocol.miltonStorage = miltonStorageBuilder.build();

        mockSpreadBuilder.withDefaultValues();
        iporProtocol.spreadModel = mockSpreadBuilder.build();

        ivTokenBuilder.withAsset(address(iporProtocol.asset));
        ivTokenBuilder.withName("IV USDT");
        ivTokenBuilder.withSymbol("ivUSDT");
        IvToken ivToken = ivTokenBuilder.build();

        stanleyBuilder.withAsset(address(iporProtocol.asset));
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        stanleyBuilder.withIvToken(address(ivToken));
        stanleyBuilder.withStrategiesUsdt();
        iporProtocol.stanley = stanleyBuilder.build();

        miltonBuilder.withAsset(address(iporProtocol.asset));
        miltonBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        miltonBuilder.withIporOracle(address(iporProtocol.iporOracle));
        miltonBuilder.withMiltonStorage(address(iporProtocol.miltonStorage));
        miltonBuilder.withSpreadModel(address(iporProtocol.spreadModel));
        miltonBuilder.withStanley(address(iporProtocol.stanley));
        iporProtocol.milton = miltonBuilder.build();

        josephBuilder.withAsset(address(iporProtocol.asset));
        josephBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        josephBuilder.withIpToken(address(iporProtocol.ipToken));
        josephBuilder.withMilton(address(iporProtocol.milton));
        josephBuilder.withMiltonStorage(address(iporProtocol.miltonStorage));
        josephBuilder.withStanley(address(iporProtocol.stanley));
        iporProtocol.joseph = josephBuilder.build();

        //setup
        vm.startPrank(address(_owner));
        iporProtocol.iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        iporProtocol.iporOracle.addUpdater(cfg.iporOracleUpdater);

        iporProtocol.ipToken.setJoseph(address(iporProtocol.joseph));
        ivToken.setStanley(address(iporProtocol.stanley));

        iporProtocol.joseph.setMaxLiquidityPoolBalance(1000000000);
        iporProtocol.joseph.setMaxLpAccountContribution(1000000000);
        iporProtocol.miltonStorage.setJoseph(address(iporProtocol.joseph));
        iporProtocol.miltonStorage.setMilton(address(iporProtocol.milton));
        iporProtocol.milton.setJoseph(address(iporProtocol.joseph));
        iporProtocol.milton.setupMaxAllowanceForAsset(address(iporProtocol.joseph));
        iporProtocol.milton.setupMaxAllowanceForAsset(address(iporProtocol.stanley));

        iporProtocol.stanley.setMilton(address(iporProtocol.milton));

        vm.stopPrank();

        return iporProtocol;
    }

    function getUsdcInstance(TestCaseConfig memory cfg)
        public
        returns (IporProtocol memory iporProtocol)
    {
        assetBuilder.withUSDC();
        iporProtocol.asset = assetBuilder.build();

        ipTokenBuilder.withAsset(address(iporProtocol.asset));
        ipTokenBuilder.withName("IP USDC");
        ipTokenBuilder.withSymbol("ipUSDC");
        iporProtocol.ipToken = ipTokenBuilder.build();

        _prepareIporOracleBuilder(address(iporProtocol.asset), cfg);

        iporProtocol.iporOracle = iporOracleBuilder.build();

        iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle));
        MockIporWeighted iporWeighted = iporWeightedBuilder.build();

        iporProtocol.miltonStorage = miltonStorageBuilder.build();

        mockSpreadBuilder.withDefaultValues();
        iporProtocol.spreadModel = mockSpreadBuilder.build();

        ivTokenBuilder.withAsset(address(iporProtocol.asset));
        ivTokenBuilder.withName("IV USDC");
        ivTokenBuilder.withSymbol("ivUSDC");
        IvToken ivToken = ivTokenBuilder.build();

        stanleyBuilder.withAsset(address(iporProtocol.asset));
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        stanleyBuilder.withIvToken(address(ivToken));
        stanleyBuilder.withStrategiesUsdc();
        iporProtocol.stanley = stanleyBuilder.build();

        miltonBuilder.withAsset(address(iporProtocol.asset));
        miltonBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        miltonBuilder.withIporOracle(address(iporProtocol.iporOracle));
        miltonBuilder.withMiltonStorage(address(iporProtocol.miltonStorage));
        miltonBuilder.withSpreadModel(address(iporProtocol.spreadModel));
        miltonBuilder.withStanley(address(iporProtocol.stanley));
        iporProtocol.milton = miltonBuilder.build();

        josephBuilder.withAsset(address(iporProtocol.asset));
        josephBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        josephBuilder.withIpToken(address(iporProtocol.ipToken));
        josephBuilder.withMilton(address(iporProtocol.milton));
        josephBuilder.withMiltonStorage(address(iporProtocol.miltonStorage));
        josephBuilder.withStanley(address(iporProtocol.stanley));
        iporProtocol.joseph = josephBuilder.build();

        //setup
        vm.startPrank(address(_owner));
        iporProtocol.iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        iporProtocol.iporOracle.addUpdater(cfg.iporOracleUpdater);

        iporProtocol.ipToken.setJoseph(address(iporProtocol.joseph));
        ivToken.setStanley(address(iporProtocol.stanley));

        iporProtocol.joseph.setMaxLiquidityPoolBalance(1000000000);
        iporProtocol.joseph.setMaxLpAccountContribution(1000000000);
        iporProtocol.miltonStorage.setJoseph(address(iporProtocol.joseph));
        iporProtocol.miltonStorage.setMilton(address(iporProtocol.milton));
        iporProtocol.milton.setJoseph(address(iporProtocol.joseph));
        iporProtocol.milton.setupMaxAllowanceForAsset(address(iporProtocol.joseph));
        iporProtocol.milton.setupMaxAllowanceForAsset(address(iporProtocol.stanley));

        iporProtocol.stanley.setMilton(address(iporProtocol.milton));

        vm.stopPrank();

        return iporProtocol;
    }

    function _prepareIporOracleBuilder(address asset, TestCaseConfig memory cfg) internal {
        iporOracleBuilder.withAsset(asset);
        if (
            cfg.iporOracleInitialParamsTestCase ==
            BuilderUtils.IporOracleInitialParamsTestCase.CASE1
        ) {
            iporOracleBuilder.withLastUpdateTimestamp(1);
            iporOracleBuilder.withExponentialMovingAverage(1);
            iporOracleBuilder.withExponentialWeightedMovingVariance(1);
        } else {
            iporOracleBuilder.withDefaultIndicators();
        }
    }

    //    function getUsdtInstance() public returns (IporProtocol memory iporProtocol) {
    //        return IporProtocol();
    //    }
    //
    //    function getUsdcInstance() public returns (IporProtocol memory iporProtocol) {
    //        return IporProtocol();
    //    }
}
