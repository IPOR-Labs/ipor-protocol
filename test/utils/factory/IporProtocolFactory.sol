// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/tokens/IvToken.sol";
import "contracts/itf/ItfIporOracle.sol";

import "../builder/AssetBuilder.sol";
import "../builder/IpTokenBuilder.sol";
import "../builder/IvTokenBuilder.sol";
import "../builder/IporWeightedBuilder.sol";
import "../builder/MiltonStorageBuilder.sol";
import "../builder/StanleyBuilder.sol";
import "../builder/SpreadRouterBuilder.sol";
import "../builder/MiltonBuilder.sol";
import "./IporOracleFactory.sol";
import "./IporRiskManagementOracleFactory.sol";

contract IporProtocolFactory is Test {
    struct Amm {
        ItfIporOracle iporOracle;
        IporRiskManagementOracle iporRiskManagementOracle;
        BuilderUtils.IporProtocol usdt;
        BuilderUtils.IporProtocol usdc;
        BuilderUtils.IporProtocol dai;
    }

    struct AmmConfig {
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase iporRiskManagementOracleInitialParamsTestCase;
        BuilderUtils.MiltonTestCase miltonUsdtTestCase;
        BuilderUtils.MiltonTestCase miltonUsdcTestCase;
        BuilderUtils.MiltonTestCase miltonDaiTestCase;
    }

    struct IporProtocolConfig {
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        BuilderUtils.MiltonTestCase miltonTestCase;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase iporRiskManagementOracleInitialParamsTestCase;
        address[] approvalsForUsers;
        address josephImplementation;
        address spreadImplementation;
        address stanleyImplementation;
    }

    IporOracleFactory internal _iporOracleFactory;
    IporRiskManagementOracleFactory internal _iporRiskManagementOracleFactory;

    AssetBuilder internal _assetBuilder;
    IpTokenBuilder internal _ipTokenBuilder;
    IvTokenBuilder internal _ivTokenBuilder;
    IporWeightedBuilder internal _iporWeightedBuilder;
    MiltonStorageBuilder internal _miltonStorageBuilder;
    SpreadRouterBuilder internal _spreadBuilder;
    StanleyBuilder internal _stanleyBuilder;
    MiltonBuilder internal _miltonBuilder;


    MockTestnetToken internal _usdt;
    MockTestnetToken internal _usdc;
    MockTestnetToken internal _dai;

    address internal _owner;

    constructor(address owner) {
        _iporOracleFactory = new IporOracleFactory(owner);
        _iporRiskManagementOracleFactory = new IporRiskManagementOracleFactory(owner);
        //        _iporProtocolBuilder = new IporProtocolBuilder(owner);
        _assetBuilder = new AssetBuilder(owner);
        _ipTokenBuilder = new IpTokenBuilder(owner);
        _ivTokenBuilder = new IvTokenBuilder(owner);
        _iporWeightedBuilder = new IporWeightedBuilder(owner);
        _miltonStorageBuilder = new MiltonStorageBuilder(owner);
        _spreadBuilder = new SpreadRouterBuilder(owner);
        _stanleyBuilder = new StanleyBuilder(owner);
        _miltonBuilder = new MiltonBuilder(owner);
        _owner = owner;
    }
//
//    function getFullInstance(AmmConfig memory cfg) public returns (Amm memory amm) {
//        _assetBuilder.withUSDT();
//        _usdt = _assetBuilder.build();
//
//        _assetBuilder.withUSDC();
//        _usdc = _assetBuilder.build();
//
//        _assetBuilder.withDAI();
//        _dai = _assetBuilder.build();
//
//        address[] memory assets = new address[](3);
//        assets[0] = address(_dai);
//        assets[1] = address(_usdt);
//        assets[2] = address(_usdc);
//
//        ItfIporOracle iporOracle = _iporOracleFactory.getInstance(
//            assets,
//            cfg.iporOracleUpdater,
//            cfg.iporOracleInitialParamsTestCase
//        );
//
//        IporRiskManagementOracle iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
//            assets,
//            cfg.iporRiskManagementOracleUpdater,
//            cfg.iporRiskManagementOracleInitialParamsTestCase
//        );
//
//        amm.iporOracle = iporOracle;
//        amm.iporRiskManagementOracle = iporRiskManagementOracle;
//
//        IpToken ipToken = _ipTokenBuilder.withName("IP USDT").withSymbol("ipUSDT").withAsset(address(_usdt)).build();
//
//        IvToken ivToken = _ivTokenBuilder.withName("IV USDT").withSymbol("ivUSDT").withAsset(address(_usdt)).build();
//
//        MockIporWeighted iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
//
//        MiltonStorage miltonStorage = _miltonStorageBuilder.build();
//
//        MockSpreadModel spreadModel = _spreadBuilder.build();
//
//        ItfStanley stanley = _stanleyBuilder
//            .withAssetType(BuilderUtils.AssetType.USDT)
//            .withAsset(address(_usdt))
//            .withIvToken(address(ivToken))
//            .build();
//
//        ItfMilton milton = _miltonBuilder
//            .withAssetType(BuilderUtils.AssetType.USDT)
//            .withAsset(address(_usdt))
//            .withIporOracle(address(iporOracle))
//            .withMiltonStorage(address(miltonStorage))
//            .withStanley(address(stanley))
//            .withSpreadModel(address(spreadModel))
//            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
//            .withTestCase(cfg.miltonUsdtTestCase)
//            .build();
//
//        ItfJoseph joseph = _josephBuilder
//            .withAssetType(BuilderUtils.AssetType.USDT)
//            .withAsset(address(_usdt))
//            .withIpToken(address(ipToken))
//            .withMiltonStorage(address(miltonStorage))
//            .withMilton(address(milton))
//            .withStanley(address(stanley))
//            .build();
//
//        vm.startPrank(address(_owner));
//        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
//        ivToken.setStanley(address(stanley));
//        miltonStorage.setMilton(address(milton));
//        stanley.setMilton(address(milton));
//        milton.setupMaxAllowanceForAsset(address(stanley));
//
//        ipToken.setJoseph(address(joseph));
//        miltonStorage.setJoseph(address(joseph));
//        milton.setJoseph(address(joseph));
//        milton.setupMaxAllowanceForAsset(address(joseph));
//
//        joseph.setMaxLiquidityPoolBalance(1000000000);
//        joseph.setMaxLpAccountContribution(1000000000);
//
//        vm.stopPrank();
//
//        amm.usdt = BuilderUtils.IporProtocol({
//            asset: _usdt,
//            ipToken: ipToken,
//            ivToken: ivToken,
//            iporOracle: iporOracle,
//            iporRiskManagementOracle: iporRiskManagementOracle,
//            iporWeighted: iporWeighted,
//            miltonStorage: miltonStorage,
//            spreadModel: spreadModel,
//            stanley: stanley,
//            milton: milton,
//            joseph: joseph
//        });
//
//        ipToken = _ipTokenBuilder.withName("IP USDC").withSymbol("ipUSDC").withAsset(address(_usdc)).build();
//        ivToken = _ivTokenBuilder.withName("IV USDC").withSymbol("ivUSDC").withAsset(address(_usdc)).build();
//        iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
//        miltonStorage = _miltonStorageBuilder.build();
//        spreadModel = _spreadBuilder.build();
//
//        stanley = _stanleyBuilder
//            .withAssetType(BuilderUtils.AssetType.USDC)
//            .withAsset(address(_usdc))
//            .withIvToken(address(ivToken))
//            .build();
//
//        milton = _miltonBuilder
//            .withAssetType(BuilderUtils.AssetType.USDC)
//            .withAsset(address(_usdc))
//            .withIporOracle(address(iporOracle))
//            .withMiltonStorage(address(miltonStorage))
//            .withStanley(address(stanley))
//            .withSpreadModel(address(spreadModel))
//            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
//            .withTestCase(cfg.miltonUsdcTestCase)
//            .build();
//
//        joseph = _josephBuilder
//            .withAssetType(BuilderUtils.AssetType.USDC)
//            .withAsset(address(_usdc))
//            .withIpToken(address(ipToken))
//            .withMiltonStorage(address(miltonStorage))
//            .withMilton(address(milton))
//            .withStanley(address(stanley))
//            .build();
//
//        vm.startPrank(address(_owner));
//        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
//        ivToken.setStanley(address(stanley));
//        miltonStorage.setMilton(address(milton));
//        stanley.setMilton(address(milton));
//        milton.setupMaxAllowanceForAsset(address(stanley));
//
//        ipToken.setJoseph(address(joseph));
//        miltonStorage.setJoseph(address(joseph));
//        milton.setJoseph(address(joseph));
//        milton.setupMaxAllowanceForAsset(address(joseph));
//
//        joseph.setMaxLiquidityPoolBalance(1000000000);
//        joseph.setMaxLpAccountContribution(1000000000);
//
//        vm.stopPrank();
//
//        amm.usdc = BuilderUtils.IporProtocol({
//            asset: _usdc,
//            ipToken: ipToken,
//            ivToken: ivToken,
//            iporOracle: iporOracle,
//            iporRiskManagementOracle: iporRiskManagementOracle,
//            iporWeighted: iporWeighted,
//            miltonStorage: miltonStorage,
//            spreadModel: spreadModel,
//            stanley: stanley,
//            milton: milton,
//            joseph: joseph
//        });
//
//        ipToken = _ipTokenBuilder.withName("IP DAI").withSymbol("ipDAI").withAsset(address(_dai)).build();
//        ivToken = _ivTokenBuilder.withName("IV DAI").withSymbol("ivDAI").withAsset(address(_dai)).build();
//        iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
//        miltonStorage = _miltonStorageBuilder.build();
//        spreadModel = _spreadBuilder.build();
//
//        stanley = _stanleyBuilder
//            .withAssetType(BuilderUtils.AssetType.DAI)
//            .withAsset(address(_dai))
//            .withIvToken(address(ivToken))
//            .build();
//
//        milton = _miltonBuilder
//            .withAssetType(BuilderUtils.AssetType.DAI)
//            .withAsset(address(_dai))
//            .withIporOracle(address(iporOracle))
//            .withMiltonStorage(address(miltonStorage))
//            .withStanley(address(stanley))
//            .withSpreadModel(address(spreadModel))
//            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
//            .withTestCase(cfg.miltonDaiTestCase)
//            .build();
//
//        joseph = _josephBuilder
//            .withAssetType(BuilderUtils.AssetType.DAI)
//            .withAsset(address(_dai))
//            .withIpToken(address(ipToken))
//            .withMiltonStorage(address(miltonStorage))
//            .withMilton(address(milton))
//            .withStanley(address(stanley))
//            .build();
//
//        vm.startPrank(address(_owner));
//        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
//        ivToken.setStanley(address(stanley));
//        miltonStorage.setMilton(address(milton));
//        stanley.setMilton(address(milton));
//        milton.setupMaxAllowanceForAsset(address(stanley));
//
//        ipToken.setJoseph(address(joseph));
//        miltonStorage.setJoseph(address(joseph));
//        milton.setJoseph(address(joseph));
//        milton.setupMaxAllowanceForAsset(address(joseph));
//
//        joseph.setMaxLiquidityPoolBalance(1000000000);
//        joseph.setMaxLpAccountContribution(1000000000);
//
//        vm.stopPrank();
//
//        amm.dai = BuilderUtils.IporProtocol({
//            asset: _dai,
//            ipToken: ipToken,
//            ivToken: ivToken,
//            iporOracle: iporOracle,
//            iporRiskManagementOracle: iporRiskManagementOracle,
//            iporWeighted: iporWeighted,
//            miltonStorage: miltonStorage,
//            spreadModel: spreadModel,
//            stanley: stanley,
//            milton: milton,
//            joseph: joseph
//        });
//    }
//
//    function getDaiInstance(IporProtocolConfig memory cfg)
//        public
//        returns (BuilderUtils.IporProtocol memory iporProtocol)
//    {
//        _assetBuilder.withDAI();
//        MockTestnetToken dai = _assetBuilder.build();
//
//        address[] memory assets = new address[](1);
//        assets[0] = address(dai);
//
//        ItfIporOracle iporOracle = _iporOracleFactory.getInstance(
//            assets,
//            cfg.iporOracleUpdater,
//            cfg.iporOracleInitialParamsTestCase
//        );
//
//        IporRiskManagementOracle iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
//            assets,
//            cfg.iporRiskManagementOracleUpdater,
//            cfg.iporRiskManagementOracleInitialParamsTestCase
//        );
//
//        IpToken ipToken = _ipTokenBuilder.withName("IP DAI").withSymbol("ipDAI").withAsset(address(dai)).build();
//
//        IvToken ivToken = _ivTokenBuilder.withName("IV DAI").withSymbol("ivDAI").withAsset(address(dai)).build();
//
//        MockIporWeighted iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
//
//        MiltonStorage miltonStorage = _miltonStorageBuilder.build();
//
//        MockSpreadModel spreadModel = _spreadBuilder.withSpreadImplementation(cfg.spreadImplementation).build();
//
//        ItfStanley stanley = _stanleyBuilder
//            .withAssetType(BuilderUtils.AssetType.DAI)
//            .withAsset(address(dai))
//            .withIvToken(address(ivToken))
//            .withStanleyImplementation(cfg.stanleyImplementation)
//            .build();
//
//        ItfMilton milton = _miltonBuilder
//            .withAssetType(BuilderUtils.AssetType.DAI)
//            .withAsset(address(dai))
//            .withIporOracle(address(iporOracle))
//            .withMiltonStorage(address(miltonStorage))
//            .withStanley(address(stanley))
//            .withSpreadModel(address(spreadModel))
//            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
//            .withTestCase(cfg.miltonTestCase)
//            .build();
//
//        ItfJoseph joseph = _josephBuilder
//            .withAssetType(BuilderUtils.AssetType.DAI)
//            .withAsset(address(dai))
//            .withIpToken(address(ipToken))
//            .withMiltonStorage(address(miltonStorage))
//            .withMilton(address(milton))
//            .withStanley(address(stanley))
//            .withJosephImplementation(cfg.josephImplementation)
//            .build();
//
//        vm.startPrank(address(_owner));
//        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
//        ivToken.setStanley(address(stanley));
//        miltonStorage.setMilton(address(milton));
//        stanley.setMilton(address(milton));
//        milton.setupMaxAllowanceForAsset(address(stanley));
//
//        ipToken.setJoseph(address(joseph));
//        miltonStorage.setJoseph(address(joseph));
//        milton.setJoseph(address(joseph));
//        milton.setupMaxAllowanceForAsset(address(joseph));
//
//        joseph.setMaxLiquidityPoolBalance(1000000000);
//        joseph.setMaxLpAccountContribution(1000000000);
//
//        vm.stopPrank();
//
//        iporProtocol = BuilderUtils.IporProtocol({
//            asset: dai,
//            ipToken: ipToken,
//            ivToken: ivToken,
//            iporOracle: iporOracle,
//            iporRiskManagementOracle: iporRiskManagementOracle,
//            iporWeighted: iporWeighted,
//            miltonStorage: miltonStorage,
//            spreadModel: spreadModel,
//            stanley: stanley,
//            milton: milton,
//            joseph: joseph
//        });
//
//        //setup
//        setupUsers(cfg, iporProtocol);
//
//        return iporProtocol;
//    }
//
//    function getUsdtInstance(IporProtocolConfig memory cfg)
//        public
//        returns (BuilderUtils.IporProtocol memory iporProtocol)
//    {
//        _assetBuilder.withUSDT();
//        MockTestnetToken usdt = _assetBuilder.build();
//
//        address[] memory assets = new address[](1);
//        assets[0] = address(usdt);
//
//        ItfIporOracle iporOracle = _iporOracleFactory.getInstance(
//            assets,
//            cfg.iporOracleUpdater,
//            cfg.iporOracleInitialParamsTestCase
//        );
//
//        IporRiskManagementOracle iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
//            assets,
//            cfg.iporRiskManagementOracleUpdater,
//            cfg.iporRiskManagementOracleInitialParamsTestCase
//        );
//
//        IpToken ipToken = _ipTokenBuilder.withName("IP USDT").withSymbol("ipUSDT").withAsset(address(usdt)).build();
//
//        IvToken ivToken = _ivTokenBuilder.withName("IV USDT").withSymbol("ivUSDT").withAsset(address(usdt)).build();
//
//        MockIporWeighted iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
//
//        MiltonStorage miltonStorage = _miltonStorageBuilder.build();
//
//        MockSpreadModel spreadModel = _spreadBuilder.withSpreadImplementation(cfg.spreadImplementation).build();
//
//        ItfStanley stanley = _stanleyBuilder
//            .withAssetType(BuilderUtils.AssetType.USDT)
//            .withAsset(address(usdt))
//            .withIvToken(address(ivToken))
//            .withStanleyImplementation(cfg.stanleyImplementation)
//            .build();
//
//        ItfMilton milton = _miltonBuilder
//            .withAssetType(BuilderUtils.AssetType.USDT)
//            .withAsset(address(usdt))
//            .withIporOracle(address(iporOracle))
//            .withMiltonStorage(address(miltonStorage))
//            .withStanley(address(stanley))
//            .withSpreadModel(address(spreadModel))
//            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
//            .withTestCase(cfg.miltonTestCase)
//            .build();
//
//        ItfJoseph joseph = _josephBuilder
//            .withAssetType(BuilderUtils.AssetType.USDT)
//            .withAsset(address(usdt))
//            .withIpToken(address(ipToken))
//            .withMiltonStorage(address(miltonStorage))
//            .withMilton(address(milton))
//            .withStanley(address(stanley))
//            .withJosephImplementation(cfg.josephImplementation)
//            .build();
//
//        vm.startPrank(address(_owner));
//        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
//        ivToken.setStanley(address(stanley));
//        miltonStorage.setMilton(address(milton));
//        stanley.setMilton(address(milton));
//        milton.setupMaxAllowanceForAsset(address(stanley));
//
//        ipToken.setJoseph(address(joseph));
//        miltonStorage.setJoseph(address(joseph));
//        milton.setJoseph(address(joseph));
//        milton.setupMaxAllowanceForAsset(address(joseph));
//
//        joseph.setMaxLiquidityPoolBalance(1000000000);
//        joseph.setMaxLpAccountContribution(1000000000);
//
//        vm.stopPrank();
//
//        iporProtocol = BuilderUtils.IporProtocol({
//            asset: usdt,
//            ipToken: ipToken,
//            ivToken: ivToken,
//            iporOracle: iporOracle,
//            iporRiskManagementOracle: iporRiskManagementOracle,
//            iporWeighted: iporWeighted,
//            miltonStorage: miltonStorage,
//            spreadModel: spreadModel,
//            stanley: stanley,
//            milton: milton,
//            joseph: joseph
//        });
//
//        //setup
//        setupUsers(cfg, iporProtocol);
//
//        return iporProtocol;
//    }
//
//    function getUsdcInstance(IporProtocolConfig memory cfg)
//        public
//        returns (BuilderUtils.IporProtocol memory iporProtocol)
//    {
//        _assetBuilder.withUSDC();
//        MockTestnetToken usdc = _assetBuilder.build();
//
//        address[] memory assets = new address[](1);
//        assets[0] = address(usdc);
//
//        ItfIporOracle iporOracle = _iporOracleFactory.getInstance(
//            assets,
//            cfg.iporOracleUpdater,
//            cfg.iporOracleInitialParamsTestCase
//        );
//
//        IporRiskManagementOracle iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
//            assets,
//            cfg.iporRiskManagementOracleUpdater,
//            cfg.iporRiskManagementOracleInitialParamsTestCase
//        );
//
//        IpToken ipToken = _ipTokenBuilder.withName("IP USDC").withSymbol("ipUSDC").withAsset(address(usdc)).build();
//
//        IvToken ivToken = _ivTokenBuilder.withName("IV USDC").withSymbol("ivUSDC").withAsset(address(usdc)).build();
//
//        MockIporWeighted iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
//
//        MiltonStorage miltonStorage = _miltonStorageBuilder.build();
//
//        MockSpreadModel spreadModel = _spreadBuilder.withSpreadImplementation(cfg.spreadImplementation).build();
//
//        ItfStanley stanley = _stanleyBuilder
//            .withAssetType(BuilderUtils.AssetType.USDC)
//            .withAsset(address(usdc))
//            .withIvToken(address(ivToken))
//            .withStanleyImplementation(cfg.stanleyImplementation)
//            .build();
//
//        ItfMilton milton = _miltonBuilder
//            .withAssetType(BuilderUtils.AssetType.USDC)
//            .withAsset(address(usdc))
//            .withIporOracle(address(iporOracle))
//            .withMiltonStorage(address(miltonStorage))
//            .withStanley(address(stanley))
//            .withSpreadModel(address(spreadModel))
//            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
//            .withTestCase(cfg.miltonTestCase)
//            .build();
//
//        ItfJoseph joseph = _josephBuilder
//            .withAssetType(BuilderUtils.AssetType.USDC)
//            .withAsset(address(usdc))
//            .withIpToken(address(ipToken))
//            .withMiltonStorage(address(miltonStorage))
//            .withMilton(address(milton))
//            .withStanley(address(stanley))
//            .withJosephImplementation(cfg.josephImplementation)
//            .build();
//
//        vm.startPrank(address(_owner));
//        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
//        ivToken.setStanley(address(stanley));
//        miltonStorage.setMilton(address(milton));
//        stanley.setMilton(address(milton));
//        milton.setupMaxAllowanceForAsset(address(stanley));
//
//        ipToken.setJoseph(address(joseph));
//        miltonStorage.setJoseph(address(joseph));
//        milton.setJoseph(address(joseph));
//        milton.setupMaxAllowanceForAsset(address(joseph));
//
//        joseph.setMaxLiquidityPoolBalance(1000000000);
//        joseph.setMaxLpAccountContribution(1000000000);
//
//        vm.stopPrank();
//
//        iporProtocol = BuilderUtils.IporProtocol({
//            asset: usdc,
//            ipToken: ipToken,
//            ivToken: ivToken,
//            iporOracle: iporOracle,
//            iporRiskManagementOracle: iporRiskManagementOracle,
//            iporWeighted: iporWeighted,
//            miltonStorage: miltonStorage,
//            spreadModel: spreadModel,
//            stanley: stanley,
//            milton: milton,
//            joseph: joseph
//        });
//
//        //setup
//        setupUsers(cfg, iporProtocol);
//
//        return iporProtocol;
//    }
//
//    function setupUsers(
//        IporProtocolFactory.IporProtocolConfig memory cfg,
//        BuilderUtils.IporProtocol memory iporProtocol
//    ) public {
//        if (iporProtocol.asset.decimals() == 18) {
//            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
//                vm.startPrank(cfg.approvalsForUsers[i]);
//                iporProtocol.asset.approve(address(iporProtocol.joseph), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
//                iporProtocol.asset.approve(address(iporProtocol.milton), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
//                vm.stopPrank();
//                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_18DEC);
//            }
//        } else if (iporProtocol.asset.decimals() == 6) {
//            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
//                vm.startPrank(cfg.approvalsForUsers[i]);
//                iporProtocol.asset.approve(address(iporProtocol.joseph), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
//                iporProtocol.asset.approve(address(iporProtocol.milton), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
//                vm.stopPrank();
//                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_6DEC);
//            }
//        } else {
//            revert("Unsupported decimals");
//        }
//    }
}
