// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/tokens/IvToken.sol";
import "contracts/itf/ItfIporOracle.sol";

import "../builder/AssetBuilder.sol";
import "../builder/IpTokenBuilder.sol";
import "../builder/IvTokenBuilder.sol";
import "../builder/IporWeightedBuilder.sol";
import "../builder/AmmStorageBuilder.sol";
import "../builder/AssetManagementBuilder.sol";
import "../builder/SpreadRouterBuilder.sol";
import "../builder/AmmTreasuryBuilder.sol";
import "../builder/IporProtocolRouterBuilder.sol";
import "./IporOracleFactory.sol";
import "./IporRiskManagementOracleFactory.sol";
import "contracts/amm/AmmSwapsLens.sol";
import "contracts/amm/AmmOpenSwapService.sol";
import "contracts/amm/AmmCloseSwapService.sol";
import "contracts/amm/AmmPoolsService.sol";
import "contracts/amm/AmmGovernanceService.sol";
import "../../mocks/EmptyImplementation.sol";

contract IporProtocolFactory is Test {
    struct Amm {
        IporProtocolRouter router;
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
        BuilderUtils.Spread28DaysTestCase spread28DaysTestCase;
        BuilderUtils.Spread60DaysTestCase spread60DaysTestCase;
        BuilderUtils.Spread90DaysTestCase spread90DaysTestCase;
        BuilderUtils.AmmTreasuryTestCase miltonUsdtTestCase;
        BuilderUtils.AmmTreasuryTestCase miltonUsdcTestCase;
        BuilderUtils.AmmTreasuryTestCase miltonDaiTestCase;
    }

    struct IporProtocolConfig {
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase;
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase iporRiskManagementOracleInitialParamsTestCase;
        BuilderUtils.Spread28DaysTestCase spread28DaysTestCase;
        BuilderUtils.Spread60DaysTestCase spread60DaysTestCase;
        BuilderUtils.Spread90DaysTestCase spread90DaysTestCase;
        address[] approvalsForUsers;
        address josephImplementation;
        address spreadImplementation;
        address assetManagementImplementation;
    }

    IporOracleFactory internal _iporOracleFactory;
    IporRiskManagementOracleFactory internal _iporRiskManagementOracleFactory;

    AssetBuilder internal _assetBuilder;
    IpTokenBuilder internal _ipTokenBuilder;
    IvTokenBuilder internal _ivTokenBuilder;
    IporWeightedBuilder internal _iporWeightedBuilder;
    AmmStorageBuilder internal _ammStorageBuilder;
    AmmTreasuryBuilder internal _ammTreasuryBuilder;
    SpreadRouterBuilder internal _spreadRouterBuilder;
    AssetManagementBuilder internal _assetManagementBuilder;
    AmmTreasuryBuilder internal _miltonBuilder;
    IporProtocolRouterBuilder internal _iporProtocolRouterBuilder;

    MockTestnetToken internal _usdt;
    MockTestnetToken internal _usdc;
    MockTestnetToken internal _dai;
    address internal _fakeContract = address(new EmptyImplementation());

    address internal _owner;

    constructor(address owner) {
        _iporOracleFactory = new IporOracleFactory(owner);
        _iporRiskManagementOracleFactory = new IporRiskManagementOracleFactory(owner);
        _assetBuilder = new AssetBuilder(owner);
        _ipTokenBuilder = new IpTokenBuilder(owner);
        _ivTokenBuilder = new IvTokenBuilder(owner);
        _iporWeightedBuilder = new IporWeightedBuilder(owner);
        _ammStorageBuilder = new AmmStorageBuilder(owner);
        _ammTreasuryBuilder = new AmmTreasuryBuilder(owner);
        _spreadRouterBuilder = new SpreadRouterBuilder(owner);
        _assetManagementBuilder = new AssetManagementBuilder(owner);
        _miltonBuilder = new AmmTreasuryBuilder(owner);
        _iporProtocolRouterBuilder = new IporProtocolRouterBuilder(owner);
        _owner = owner;
    }

    function getFullInstance(AmmConfig memory cfg) public returns (Amm memory amm) {
        _assetBuilder.withUSDT();
        amm.usdt.asset = _assetBuilder.build();

        _assetBuilder.withUSDC();
        amm.usdc.asset = _assetBuilder.build();

        _assetBuilder.withDAI();
        amm.dai.asset = _assetBuilder.build();

        address[] memory assets = new address[](3);
        assets[0] = address(amm.dai.asset);
        assets[1] = address(amm.usdt.asset);
        assets[2] = address(amm.usdc.asset);

        ItfIporOracle iporOracle = _iporOracleFactory.getInstance(
            assets,
            cfg.iporOracleUpdater,
            cfg.iporOracleInitialParamsTestCase
        );

        IporRiskManagementOracle iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
            assets,
            cfg.iporRiskManagementOracleUpdater,
            cfg.iporRiskManagementOracleInitialParamsTestCase
        );

        amm.iporOracle = iporOracle;
        amm.iporRiskManagementOracle = iporRiskManagementOracle;

        amm.usdt.ipToken = _ipTokenBuilder.withName("IP USDT").withSymbol("ipUSDT").withAsset(address(_usdt)).build();
        amm.usdt.ivToken = _ivTokenBuilder.withName("IV USDT").withSymbol("ivUSDT").withAsset(address(_usdt)).build();
        amm.usdt.iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
        amm.usdt.ammStorage = _ammStorageBuilder.build();

        amm.router = _iporProtocolRouterBuilder.buildEmptyProxy();

        _spreadRouterBuilder.withIporRouter(address(amm.router));

        _spreadRouterBuilder.withUsdt(address(amm.usdt.asset));
        _spreadRouterBuilder.withUsdc(address(amm.usdc.asset));
        _spreadRouterBuilder.withDai(address(amm.dai.asset));

        _spreadRouterBuilder.withSpread28DaysTestCase(cfg.spread28DaysTestCase);
        _spreadRouterBuilder.withSpread60DaysTestCase(cfg.spread60DaysTestCase);
        _spreadRouterBuilder.withSpread90DaysTestCase(cfg.spread90DaysTestCase);
        //        iporProtocol.spreadRouter = _spreadRouterBuilder.build();
        //
        //        amm.usdt.assetManagement = _assetManagementBuilder
        //            .withAssetType(BuilderUtils.AssetType.USDT)
        //            .withAsset(address(amm.usdt.asset))
        //            .withIvToken(address(amm.usdt.ivToken))
        //            .withAssetManagementImplementation(cfg.assetManagementImplementation)
        //            .build();
        //
        //        iporProtocol.ammTreasury = _ammTreasuryBuilder
        //            .withAsset(address(iporProtocol.asset))
        //            .withAmmStorage(address(iporProtocol.ammStorage))
        //            .withAssetManagement(address(iporProtocol.assetManagement))
        //            .withIporProtocolRouter(address(iporProtocol.router))
        //            .build();
        //
        //        iporProtocol.router = _getUsdtIporProtocolRouterInstance(
        //            iporProtocol,
        //            cfg.openSwapServiceTestCase,
        //            cfg.closeSwapServiceTestCase
        //        );

        //
        //        ItfStanley stanley = _assetManagementBuilder
        //            .withAssetType(BuilderUtils.AssetType.USDT)
        //            .withAsset(address(_usdt))
        //            .withIvToken(address(ivToken))
        //            .build();
        //
        //        ItfMilton milton = _miltonBuilder
        //            .withAssetType(BuilderUtils.AssetType.USDT)
        //            .withAsset(address(_usdt))
        //            .withIporOracle(address(iporOracle))
        //            .withMiltonStorage(address(ammStorage))
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
        //            .withMiltonStorage(address(ammStorage))
        //            .withMilton(address(milton))
        //            .withStanley(address(stanley))
        //            .build();
        //
        //        vm.startPrank(address(_owner));
        //        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        //        ivToken.setStanley(address(stanley));
        //        ammStorage.setMilton(address(milton));
        //        stanley.setMilton(address(milton));
        //        milton.setupMaxAllowanceForAsset(address(stanley));
        //
        //        ipToken.setJoseph(address(joseph));
        //        ammStorage.setJoseph(address(joseph));
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
        //            ammStorage: ammStorage,
        //            spreadModel: spreadModel,
        //            stanley: stanley,
        //            milton: milton,
        //            joseph: joseph
        //        });
        //
        //        ipToken = _ipTokenBuilder.withName("IP USDC").withSymbol("ipUSDC").withAsset(address(_usdc)).build();
        //        ivToken = _ivTokenBuilder.withName("IV USDC").withSymbol("ivUSDC").withAsset(address(_usdc)).build();
        //        iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
        //        ammStorage = _ammStorageBuilder.build();
        //        spreadModel = _spreadBuilder.build();
        //
        //        stanley = _assetManagementBuilder
        //            .withAssetType(BuilderUtils.AssetType.USDC)
        //            .withAsset(address(_usdc))
        //            .withIvToken(address(ivToken))
        //            .build();
        //
        //        milton = _miltonBuilder
        //            .withAssetType(BuilderUtils.AssetType.USDC)
        //            .withAsset(address(_usdc))
        //            .withIporOracle(address(iporOracle))
        //            .withMiltonStorage(address(ammStorage))
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
        //            .withMiltonStorage(address(ammStorage))
        //            .withMilton(address(milton))
        //            .withStanley(address(stanley))
        //            .build();
        //
        //        vm.startPrank(address(_owner));
        //        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        //        ivToken.setStanley(address(stanley));
        //        ammStorage.setMilton(address(milton));
        //        stanley.setMilton(address(milton));
        //        milton.setupMaxAllowanceForAsset(address(stanley));
        //
        //        ipToken.setJoseph(address(joseph));
        //        ammStorage.setJoseph(address(joseph));
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
        //            ammStorage: ammStorage,
        //            spreadModel: spreadModel,
        //            stanley: stanley,
        //            milton: milton,
        //            joseph: joseph
        //        });
        //
        //        ipToken = _ipTokenBuilder.withName("IP DAI").withSymbol("ipDAI").withAsset(address(_dai)).build();
        //        ivToken = _ivTokenBuilder.withName("IV DAI").withSymbol("ivDAI").withAsset(address(_dai)).build();
        //        iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
        //        ammStorage = _ammStorageBuilder.build();
        //        spreadModel = _spreadBuilder.build();
        //
        //        stanley = _assetManagementBuilder
        //            .withAssetType(BuilderUtils.AssetType.DAI)
        //            .withAsset(address(_dai))
        //            .withIvToken(address(ivToken))
        //            .build();
        //
        //        milton = _miltonBuilder
        //            .withAssetType(BuilderUtils.AssetType.DAI)
        //            .withAsset(address(_dai))
        //            .withIporOracle(address(iporOracle))
        //            .withMiltonStorage(address(ammStorage))
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
        //            .withMiltonStorage(address(ammStorage))
        //            .withMilton(address(milton))
        //            .withStanley(address(stanley))
        //            .build();
        //
        //        vm.startPrank(address(_owner));
        //        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        //        ivToken.setStanley(address(stanley));
        //        ammStorage.setMilton(address(milton));
        //        stanley.setMilton(address(milton));
        //        milton.setupMaxAllowanceForAsset(address(stanley));
        //
        //        ipToken.setJoseph(address(joseph));
        //        ammStorage.setJoseph(address(joseph));
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
        //            ammStorage: ammStorage,
        //            spreadModel: spreadModel,
        //            stanley: stanley,
        //            milton: milton,
        //            joseph: joseph
        //        });
    }

    function getUsdtInstance(IporProtocolConfig memory cfg)
        public
        returns (BuilderUtils.IporProtocol memory iporProtocol)
    {
        _assetBuilder.withUSDT();

        iporProtocol.asset = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(iporProtocol.asset);

        iporProtocol.iporOracle = _iporOracleFactory.getInstance(
            assets,
            cfg.iporOracleUpdater,
            cfg.iporOracleInitialParamsTestCase
        );

        iporProtocol.iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
            assets,
            cfg.iporRiskManagementOracleUpdater,
            cfg.iporRiskManagementOracleInitialParamsTestCase
        );

        iporProtocol.ipToken = _ipTokenBuilder
            .withName("IP USDT")
            .withSymbol("ipUSDT")
            .withAsset(address(iporProtocol.asset))
            .build();

        iporProtocol.ivToken = _ivTokenBuilder
            .withName("IV USDT")
            .withSymbol("ivUSDT")
            .withAsset(address(iporProtocol.asset))
            .build();

        iporProtocol.iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle)).build();

        iporProtocol.ammStorage = _ammStorageBuilder.build();

        iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();

        _spreadRouterBuilder.withIporRouter(address(iporProtocol.router));

        _spreadRouterBuilder.withUsdt(address(iporProtocol.asset));
        _spreadRouterBuilder.withUsdc(address(_fakeContract));
        _spreadRouterBuilder.withDai(address(_fakeContract));

        _spreadRouterBuilder.withSpread28DaysTestCase(cfg.spread28DaysTestCase);
        _spreadRouterBuilder.withSpread60DaysTestCase(cfg.spread60DaysTestCase);
        _spreadRouterBuilder.withSpread90DaysTestCase(cfg.spread90DaysTestCase);

        iporProtocol.spreadRouter = _spreadRouterBuilder.build();

        iporProtocol.assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(iporProtocol.asset))
            .withIvToken(address(iporProtocol.ivToken))
            .withAssetManagementImplementation(cfg.assetManagementImplementation)
            .build();

        iporProtocol.ammTreasury = _ammTreasuryBuilder
            .withAsset(address(iporProtocol.asset))
            .withAmmStorage(address(iporProtocol.ammStorage))
            .withAssetManagement(address(iporProtocol.assetManagement))
            .withIporProtocolRouter(address(iporProtocol.router))
            .build();

        iporProtocol.router = _getUsdtIporProtocolRouterInstance(
            iporProtocol,
            cfg.openSwapServiceTestCase,
            cfg.closeSwapServiceTestCase
        );

        vm.startPrank(address(_owner));
        iporProtocol.iporOracle.setIporAlgorithmFacade(address(iporProtocol.iporWeighted));

        //TODO: when ipor oracle will have immutable then remove it
        iporProtocol.ivToken.setAssetManagement(address(iporProtocol.assetManagement));

        iporProtocol.assetManagement.setAmmTreasury((address(iporProtocol.ammTreasury)));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.assetManagement));

        iporProtocol.ammStorage.setRouter(address(iporProtocol.router));
        iporProtocol.ipToken.setRouter(address(iporProtocol.router));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmMaxLiquidityPoolBalance(
            address(iporProtocol.asset),
            1000000000
        );
        IAmmGovernanceService(address(iporProtocol.router)).setAmmMaxLpAccountContribution(
            address(iporProtocol.asset),
            1000000000
        );

        vm.stopPrank();

        //setup
        setupUsers(cfg, iporProtocol);
    }

    function getUsdcInstance(IporProtocolConfig memory cfg)
        public
        returns (BuilderUtils.IporProtocol memory iporProtocol)
    {
        _assetBuilder.withUSDC();

        iporProtocol.asset = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(iporProtocol.asset);

        iporProtocol.iporOracle = _iporOracleFactory.getInstance(
            assets,
            cfg.iporOracleUpdater,
            cfg.iporOracleInitialParamsTestCase
        );

        iporProtocol.iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
            assets,
            cfg.iporRiskManagementOracleUpdater,
            cfg.iporRiskManagementOracleInitialParamsTestCase
        );

        iporProtocol.ipToken = _ipTokenBuilder
            .withName("IP USDC")
            .withSymbol("ipUSDC")
            .withAsset(address(iporProtocol.asset))
            .build();

        iporProtocol.ivToken = _ivTokenBuilder
            .withName("IV USDC")
            .withSymbol("ivUSDC")
            .withAsset(address(iporProtocol.asset))
            .build();

        iporProtocol.iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle)).build();

        iporProtocol.ammStorage = _ammStorageBuilder.build();

        iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();

        _spreadRouterBuilder.withIporRouter(address(iporProtocol.router));

        _spreadRouterBuilder.withUsdt(address(_fakeContract));
        _spreadRouterBuilder.withUsdc(address(iporProtocol.asset));
        _spreadRouterBuilder.withDai(address(_fakeContract));

        _spreadRouterBuilder.withSpread28DaysTestCase(cfg.spread28DaysTestCase);
        _spreadRouterBuilder.withSpread60DaysTestCase(cfg.spread60DaysTestCase);
        _spreadRouterBuilder.withSpread90DaysTestCase(cfg.spread90DaysTestCase);

        iporProtocol.spreadRouter = _spreadRouterBuilder.build();

        iporProtocol.assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(iporProtocol.asset))
            .withIvToken(address(iporProtocol.ivToken))
            .withAssetManagementImplementation(cfg.assetManagementImplementation)
            .build();

        iporProtocol.ammTreasury = _ammTreasuryBuilder
            .withAsset(address(iporProtocol.asset))
            .withAmmStorage(address(iporProtocol.ammStorage))
            .withAssetManagement(address(iporProtocol.assetManagement))
            .withIporProtocolRouter(address(iporProtocol.router))
            .build();

        iporProtocol.router = _getUsdcIporProtocolRouterInstance(
            iporProtocol,
            cfg.openSwapServiceTestCase,
            cfg.closeSwapServiceTestCase
        );

        vm.startPrank(address(_owner));
        iporProtocol.iporOracle.setIporAlgorithmFacade(address(iporProtocol.iporWeighted));

        //TODO: when ipor oracle will have immutable then remove it
        iporProtocol.ivToken.setAssetManagement(address(iporProtocol.assetManagement));

        iporProtocol.assetManagement.setAmmTreasury((address(iporProtocol.ammTreasury)));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.assetManagement));

        iporProtocol.ammStorage.setRouter(address(iporProtocol.router));
        iporProtocol.ipToken.setRouter(address(iporProtocol.router));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmMaxLiquidityPoolBalance(
            address(iporProtocol.asset),
            1000000000
        );
        IAmmGovernanceService(address(iporProtocol.router)).setAmmMaxLpAccountContribution(
            address(iporProtocol.asset),
            1000000000
        );

        vm.stopPrank();

        //setup
        setupUsers(cfg, iporProtocol);
    }

    function getDaiInstance(IporProtocolConfig memory cfg)
        public
        returns (BuilderUtils.IporProtocol memory iporProtocol)
    {
        _assetBuilder.withDAI();

        iporProtocol.asset = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(iporProtocol.asset);

        iporProtocol.iporOracle = _iporOracleFactory.getInstance(
            assets,
            cfg.iporOracleUpdater,
            cfg.iporOracleInitialParamsTestCase
        );

        iporProtocol.iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
            assets,
            cfg.iporRiskManagementOracleUpdater,
            cfg.iporRiskManagementOracleInitialParamsTestCase
        );

        iporProtocol.ipToken = _ipTokenBuilder
            .withName("IP DAI")
            .withSymbol("ipDAI")
            .withAsset(address(iporProtocol.asset))
            .build();

        iporProtocol.ivToken = _ivTokenBuilder
            .withName("IV DAI")
            .withSymbol("ivDAI")
            .withAsset(address(iporProtocol.asset))
            .build();

        iporProtocol.iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle)).build();

        iporProtocol.ammStorage = _ammStorageBuilder.build();

        iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();

        _spreadRouterBuilder.withIporRouter(address(iporProtocol.router));
        _spreadRouterBuilder.withUsdt(address(_fakeContract));
        _spreadRouterBuilder.withUsdc(address(_fakeContract));
        _spreadRouterBuilder.withDai(address(iporProtocol.asset));
        _spreadRouterBuilder.withSpread28DaysTestCase(cfg.spread28DaysTestCase);
        _spreadRouterBuilder.withSpread60DaysTestCase(cfg.spread60DaysTestCase);
        _spreadRouterBuilder.withSpread90DaysTestCase(cfg.spread90DaysTestCase);

        iporProtocol.spreadRouter = _spreadRouterBuilder.build();

        iporProtocol.assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(iporProtocol.asset))
            .withIvToken(address(iporProtocol.ivToken))
            .withAssetManagementImplementation(cfg.assetManagementImplementation)
            .build();

        iporProtocol.ammTreasury = _ammTreasuryBuilder
            .withAsset(address(iporProtocol.asset))
            .withAmmStorage(address(iporProtocol.ammStorage))
            .withAssetManagement(address(iporProtocol.assetManagement))
            .withIporProtocolRouter(address(iporProtocol.router))
            .build();

        iporProtocol.router = _getDaiIporProtocolRouterInstance(
            iporProtocol,
            cfg.openSwapServiceTestCase,
            cfg.closeSwapServiceTestCase
        );

        vm.startPrank(address(_owner));
        iporProtocol.iporOracle.setIporAlgorithmFacade(address(iporProtocol.iporWeighted));

        //TODO: when ipor oracle will have immutable then remove it
        iporProtocol.ivToken.setAssetManagement(address(iporProtocol.assetManagement));

        iporProtocol.assetManagement.setAmmTreasury((address(iporProtocol.ammTreasury)));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.assetManagement));

        iporProtocol.ammStorage.setRouter(address(iporProtocol.router));
        iporProtocol.ipToken.setRouter(address(iporProtocol.router));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmMaxLiquidityPoolBalance(
            address(iporProtocol.asset),
            1000000000
        );
        IAmmGovernanceService(address(iporProtocol.router)).setAmmMaxLpAccountContribution(
            address(iporProtocol.asset),
            1000000000
        );

        vm.stopPrank();

        //setup
        setupUsers(cfg, iporProtocol);
    }

    function _getUsdtIporProtocolRouterInstance(
        BuilderUtils.IporProtocol memory iporProtocol,
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase,
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase
    ) public returns (IporProtocolRouter) {
        if (address(iporProtocol.router) == address(0)) {
            iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        }

        IporProtocolRouter.DeployedContracts memory deployerContracts;

        deployerContracts.ammSwapsLens = address(
            new AmmSwapsLens(
                _fakeContract,
                IAmmStorage(_fakeContract),
                address(iporProtocol.asset),
                iporProtocol.ammStorage,
                _fakeContract,
                IAmmStorage(_fakeContract),
                iporProtocol.iporOracle
            )
        );

        deployerContracts.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _preparePoolCfgForOpenSwapService(
                    openSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage)
                ),
                usdcPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                daiPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                iporOracle: address(iporProtocol.iporOracle),
                iporRiskManagementOracle: address(iporProtocol.iporRiskManagementOracle),
                spreadRouter: address(iporProtocol.spreadRouter)
            })
        );

        deployerContracts.ammCloseSwapService = address(
            new AmmCloseSwapService({
                usdtPoolCfg: _preparePoolCfgForCloseSwapService(
                    closeSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement)
                ),
                usdcPoolCfg: _prepareFakePoolCfgForCloseSwapService(),
                daiPoolCfg: _prepareFakePoolCfgForCloseSwapService(),
                iporOracle: address(iporProtocol.iporOracle),
                iporRiskManagementOracle: address(iporProtocol.iporRiskManagementOracle),
                spreadRouter: address(iporProtocol.spreadRouter)
            })
        );

        deployerContracts.ammPoolsService = address(
            new AmmPoolsService({
                usdtPoolCfg: _preparePoolCfgForPoolsService(
                    address(iporProtocol.asset),
                    address(iporProtocol.ipToken),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement)
                ),
                usdcPoolCfg: _prepareFakePoolCfgForPoolsService(),
                daiPoolCfg: _prepareFakePoolCfgForPoolsService(),
                iporOracle: address(iporProtocol.iporOracle)
            })
        );

        deployerContracts.ammGovernanceService = address(
            new AmmGovernanceService({
                usdtPoolCfg: _preparePoolCfgForGovernanceService(
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage)
                ),
                usdcPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                daiPoolCfg: _prepareFakePoolCfgForGovernanceService()
            })
        );

        vm.startPrank(address(_owner));
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));

        return IporProtocolRouter(iporProtocol.router);
    }

    function _getUsdcIporProtocolRouterInstance(
        BuilderUtils.IporProtocol memory iporProtocol,
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase,
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase
    ) public returns (IporProtocolRouter) {
        if (address(iporProtocol.router) == address(0)) {
            iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        }

        IporProtocolRouter.DeployedContracts memory deployerContracts;

        deployerContracts.ammSwapsLens = address(
            new AmmSwapsLens(
                address(iporProtocol.asset),
                iporProtocol.ammStorage,
                _fakeContract,
                IAmmStorage(_fakeContract),
                _fakeContract,
                IAmmStorage(_fakeContract),
                iporProtocol.iporOracle
            )
        );

        deployerContracts.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                usdcPoolCfg: _preparePoolCfgForOpenSwapService(
                    openSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage)
                ),
                daiPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                iporOracle: address(iporProtocol.iporOracle),
                iporRiskManagementOracle: address(iporProtocol.iporRiskManagementOracle),
                spreadRouter: address(iporProtocol.spreadRouter)
            })
        );

        deployerContracts.ammCloseSwapService = address(
            new AmmCloseSwapService({
                usdtPoolCfg: _prepareFakePoolCfgForCloseSwapService(),
                usdcPoolCfg: _preparePoolCfgForCloseSwapService(
                    closeSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement)
                ),
                daiPoolCfg: _prepareFakePoolCfgForCloseSwapService(),
                iporOracle: address(iporProtocol.iporOracle),
                iporRiskManagementOracle: address(iporProtocol.iporRiskManagementOracle),
                spreadRouter: address(iporProtocol.spreadRouter)
            })
        );

        deployerContracts.ammPoolsService = address(
            new AmmPoolsService({
                usdtPoolCfg: _prepareFakePoolCfgForPoolsService(),
                usdcPoolCfg: _preparePoolCfgForPoolsService(
                    address(iporProtocol.asset),
                    address(iporProtocol.ipToken),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement)
                ),
                daiPoolCfg: _prepareFakePoolCfgForPoolsService(),
                iporOracle: address(iporProtocol.iporOracle)
            })
        );

        deployerContracts.ammGovernanceService = address(
            new AmmGovernanceService({
                usdtPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                usdcPoolCfg: _preparePoolCfgForGovernanceService(
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage)
                ),
                daiPoolCfg: _prepareFakePoolCfgForGovernanceService()
            })
        );

        vm.startPrank(address(_owner));
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));

        return IporProtocolRouter(iporProtocol.router);
    }

    function _getDaiIporProtocolRouterInstance(
        BuilderUtils.IporProtocol memory iporProtocol,
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase,
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase
    ) public returns (IporProtocolRouter) {
        if (address(iporProtocol.router) == address(0)) {
            iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        }

        IporProtocolRouter.DeployedContracts memory deployerContracts;

        deployerContracts.ammSwapsLens = address(
            new AmmSwapsLens(
                _fakeContract,
                IAmmStorage(_fakeContract),
                _fakeContract,
                IAmmStorage(_fakeContract),
                address(iporProtocol.asset),
                iporProtocol.ammStorage,
                iporProtocol.iporOracle
            )
        );

        deployerContracts.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                usdcPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                daiPoolCfg: _preparePoolCfgForOpenSwapService(
                    openSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage)
                ),
                iporOracle: address(iporProtocol.iporOracle),
                iporRiskManagementOracle: address(iporProtocol.iporRiskManagementOracle),
                spreadRouter: address(iporProtocol.spreadRouter)
            })
        );

        deployerContracts.ammCloseSwapService = address(
            new AmmCloseSwapService({
                usdtPoolCfg: _prepareFakePoolCfgForCloseSwapService(),
                usdcPoolCfg: _prepareFakePoolCfgForCloseSwapService(),
                daiPoolCfg: _preparePoolCfgForCloseSwapService(
                    closeSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement)
                ),
                iporOracle: address(iporProtocol.iporOracle),
                iporRiskManagementOracle: address(iporProtocol.iporRiskManagementOracle),
                spreadRouter: address(iporProtocol.spreadRouter)
            })
        );

        deployerContracts.ammPoolsService = address(
            new AmmPoolsService({
                usdtPoolCfg: _prepareFakePoolCfgForPoolsService(),
                usdcPoolCfg: _prepareFakePoolCfgForPoolsService(),
                daiPoolCfg: _preparePoolCfgForPoolsService(
                    address(iporProtocol.asset),
                    address(iporProtocol.ipToken),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement)
                ),
                iporOracle: address(iporProtocol.iporOracle)
            })
        );

        deployerContracts.ammGovernanceService = address(
            new AmmGovernanceService({
                usdtPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                usdcPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                daiPoolCfg: _preparePoolCfgForGovernanceService(
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage)
                )
            })
        );

        vm.startPrank(address(_owner));
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));

        return IporProtocolRouter(iporProtocol.router);
    }

    function _prepareFakePoolCfgForGovernanceService()
        internal
        returns (IAmmGovernanceService.PoolConfiguration memory poolCfg)
    {
        poolCfg = IAmmGovernanceService.PoolConfiguration({
            asset: address(_fakeContract),
            assetDecimals: 0,
            ammStorage: address(_fakeContract),
            ammTreasury: address(_fakeContract)
        });
    }

    function _prepareFakePoolCfgForPoolsService() internal returns (IAmmPoolsService.PoolConfiguration memory poolCfg) {
        poolCfg = IAmmPoolsService.PoolConfiguration({
            asset: address(_fakeContract),
            decimals: 0,
            ipToken: address(_fakeContract),
            ammStorage: address(_fakeContract),
            ammTreasury: address(_fakeContract),
            assetManagement: address(_fakeContract),
            redeemFeeRate: 0,
            redeemLpMaxUtilizationRate: 0
        });
    }

    function _prepareFakePoolCfgForCloseSwapService()
        internal
        returns (IAmmCloseSwapService.PoolConfiguration memory poolCfg)
    {
        poolCfg = IAmmCloseSwapService.PoolConfiguration({
            asset: address(_fakeContract),
            decimals: 0,
            ammStorage: address(_fakeContract),
            ammTreasury: address(_fakeContract),
            assetManagement: address(_fakeContract),
            openingFeeRate: 0,
            openingFeeRateForSwapUnwind: 0,
            liquidationLegLimit: 0,
            timeBeforeMaturityAllowedToCloseSwapByCommunity: 0,
            timeBeforeMaturityAllowedToCloseSwapByBuyer: 0,
            minLiquidationThresholdToCloseBeforeMaturityByCommunity: 0,
            minLiquidationThresholdToCloseBeforeMaturityByBuyer: 0,
            minLeverage: 0
        });
    }

    function _prepareFakePoolCfgForOpenSwapService()
        internal
        returns (IAmmOpenSwapService.PoolConfiguration memory poolCfg)
    {
        poolCfg = IAmmOpenSwapService.PoolConfiguration({
            asset: address(_fakeContract),
            decimals: 0,
            ammStorage: address(_fakeContract),
            ammTreasury: address(_fakeContract),
            iporPublicationFee: 0,
            maxSwapCollateralAmount: 0,
            liquidationDepositAmount: 0,
            minLeverage: 0,
            openingFeeRate: 0,
            openingFeeTreasuryPortionRate: 0
        });
    }

    function _preparePoolCfgForGovernanceService(
        address asset,
        address ammTreasury,
        address ammStorage
    ) internal returns (IAmmGovernanceService.PoolConfiguration memory poolCfg) {
        poolCfg = IAmmGovernanceService.PoolConfiguration({
            asset: asset,
            assetDecimals: IERC20MetadataUpgradeable(asset).decimals(),
            ammStorage: ammStorage,
            ammTreasury: ammTreasury
        });
    }

    function _preparePoolCfgForPoolsService(
        address asset,
        address ipToken,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) internal returns (IAmmPoolsService.PoolConfiguration memory poolCfg) {
        poolCfg = IAmmPoolsService.PoolConfiguration({
            asset: asset,
            decimals: IERC20MetadataUpgradeable(asset).decimals(),
            ipToken: ipToken,
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            assetManagement: assetManagement,
            redeemFeeRate: 5 * 1e15,
            redeemLpMaxUtilizationRate: 1e18
        });
    }

    function _preparePoolCfgForCloseSwapService(
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase,
        address asset,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) internal returns (IAmmCloseSwapService.PoolConfiguration memory poolCfg) {
        if (closeSwapServiceTestCase == BuilderUtils.AmmCloseSwapServiceTestCase.DEFAULT) {
            poolCfg = IAmmCloseSwapService.PoolConfiguration({
                asset: address(asset),
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                openingFeeRate: 1e16,
                openingFeeRateForSwapUnwind: 5 * 1e18, //TODO: suspicious value
                liquidationLegLimit: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 0
            });
        } else if (closeSwapServiceTestCase == BuilderUtils.AmmCloseSwapServiceTestCase.CASE1) {
            poolCfg = IAmmCloseSwapService.PoolConfiguration({
                asset: address(asset),
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                openingFeeRate: 3e14,
                openingFeeRateForSwapUnwind: 5 * 1e18, //TODO: suspicious value
                liquidationLegLimit: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 0
            });
        }
    }

    function _preparePoolCfgForOpenSwapService(
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase,
        address asset,
        address ammTreasury,
        address ammStorage
    ) internal returns (IAmmOpenSwapService.PoolConfiguration memory poolCfg) {
        if (openSwapServiceTestCase == BuilderUtils.AmmOpenSwapServiceTestCase.DEFAULT) {
            poolCfg = IAmmOpenSwapService.PoolConfiguration({
                asset: asset,
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                iporPublicationFee: 10 * 1e18,
                maxSwapCollateralAmount: 100_000 * 1e18,
                liquidationDepositAmount: 25,
                minLeverage: 10 * 1e18,
                openingFeeRate: 1e16,
                openingFeeTreasuryPortionRate: 0
            });
        } else if (openSwapServiceTestCase == BuilderUtils.AmmOpenSwapServiceTestCase.CASE1) {
            poolCfg = IAmmOpenSwapService.PoolConfiguration({
                asset: asset,
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                iporPublicationFee: 10 * 1e18,
                maxSwapCollateralAmount: 100_000 * 1e18,
                liquidationDepositAmount: 20,
                minLeverage: 10 * 1e18,
                openingFeeRate: 3e14,
                openingFeeTreasuryPortionRate: 0
            });
        }
    }

    function setupUsers(
        IporProtocolFactory.IporProtocolConfig memory cfg,
        BuilderUtils.IporProtocol memory iporProtocol
    ) public {
        if (iporProtocol.asset.decimals() == 18) {
            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                //                iporProtocol.asset.approve(address(iporProtocol.joseph), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
                iporProtocol.asset.approve(address(iporProtocol.router), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
                vm.stopPrank();
                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_18DEC);
            }
        } else if (iporProtocol.asset.decimals() == 6) {
            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                //                iporProtocol.asset.approve(address(iporProtocol.joseph), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
                iporProtocol.asset.approve(address(iporProtocol.router), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
                vm.stopPrank();
                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_6DEC);
            }
        } else {
            revert("Unsupported decimals");
        }
    }
}
