// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/mocks/tokens/MockTestnetToken.sol";
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
import "test/utils/factory/IporOracleFactory.sol";
import "test/utils/factory/IporRiskManagementOracleFactory.sol";
import "contracts/interfaces/IAmmSwapsLens.sol";
import "contracts/interfaces/IAmmPoolsLens.sol";
import "contracts/interfaces/IAssetManagementLens.sol";
import "contracts/interfaces/IPowerTokenLens.sol";
import "contracts/interfaces/ILiquidityMiningLens.sol";
import "contracts/interfaces/IPowerTokenFlowsService.sol";
import "contracts/interfaces/IPowerTokenStakeService.sol";
import "contracts/amm/AmmSwapsLens.sol";
import "contracts/amm/AmmPoolsLens.sol";
import "contracts/amm/AssetManagementLens.sol";
import "contracts/amm/AmmOpenSwapService.sol";
import "contracts/amm/AmmCloseSwapService.sol";
import "contracts/amm/AmmPoolsService.sol";
import "contracts/amm/AmmGovernanceService.sol";
import "test/mocks/EmptyImplementation.sol";
import "../builder/PowerTokenLensBuilder.sol";
import "../builder/LiquidityMiningLensBuilder.sol";
import "../builder/PowerTokenFlowsServiceBuilder.sol";
import "../builder/PowerTokenStakeServiceBuilder.sol";

contract IporProtocolFactory is Test {
    struct Amm {
        IporProtocolRouter router;
        SpreadRouter spreadRouter;
        ItfIporOracle iporOracle;
        MockIporWeighted iporWeighted;
        IporRiskManagementOracle iporRiskManagementOracle;
        BuilderUtils.IporProtocol usdt;
        BuilderUtils.IporProtocol usdc;
        BuilderUtils.IporProtocol dai;
    }

    struct AmmConfig {
        address ammPoolsTreasury;
        address ammPoolsTreasuryManager;
        address ammCharlieTreasury;
        address ammCharlieTreasuryManager;
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase iporRiskManagementOracleInitialParamsTestCase;
        BuilderUtils.Spread28DaysTestCase spread28DaysTestCase;
        BuilderUtils.Spread60DaysTestCase spread60DaysTestCase;
        BuilderUtils.Spread90DaysTestCase spread90DaysTestCase;
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase;
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase;
        BuilderUtils.AmmPoolsServiceTestCase poolsServiceTestCase;
        address usdtAssetManagementImplementation;
        address usdcAssetManagementImplementation;
        address daiAssetManagementImplementation;
    }

    struct IporProtocolConfig {
        address ammPoolsTreasury;
        address ammPoolsTreasuryManager;
        address ammCharlieTreasury;
        address ammCharlieTreasuryManager;
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase;
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase;
        BuilderUtils.AmmPoolsServiceTestCase poolsServiceTestCase;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase iporRiskManagementOracleInitialParamsTestCase;
        BuilderUtils.Spread28DaysTestCase spread28DaysTestCase;
        BuilderUtils.Spread60DaysTestCase spread60DaysTestCase;
        BuilderUtils.Spread90DaysTestCase spread90DaysTestCase;
        address[] approvalsForUsers;
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
    PowerTokenLensBuilder internal _powerTokenLensBuilder;
    LiquidityMiningLensBuilder internal _liquidityMiningLensBuilder;
    PowerTokenFlowsServiceBuilder internal _powerTokenFlowsServiceBuilder;
    PowerTokenStakeServiceBuilder internal _powerTokenStakeServiceBuilder;

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
        _powerTokenLensBuilder = new PowerTokenLensBuilder(owner);
        _liquidityMiningLensBuilder = new LiquidityMiningLensBuilder(owner);
        _powerTokenFlowsServiceBuilder = new PowerTokenFlowsServiceBuilder(owner);
        _powerTokenStakeServiceBuilder = new PowerTokenStakeServiceBuilder(owner);
        _owner = owner;
    }

    function getFullInstance(AmmConfig memory cfg) public returns (Amm memory amm) {
        amm.router = _iporProtocolRouterBuilder.buildEmptyProxy();

        amm.usdt.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();
        amm.usdc.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();
        amm.dai.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();

        amm.usdt.router = amm.router;
        amm.usdc.router = amm.router;
        amm.dai.router = amm.router;

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

        amm.iporOracle = _iporOracleFactory.getEmptyInstance(assets, cfg.iporOracleInitialParamsTestCase);

        amm.usdt.iporOracle = amm.iporOracle;
        amm.usdc.iporOracle = amm.iporOracle;
        amm.dai.iporOracle = amm.iporOracle;

        amm.iporWeighted = _iporWeightedBuilder.withIporOracle(address(amm.iporOracle)).build();
        amm.usdt.iporWeighted = amm.iporWeighted;
        amm.usdc.iporWeighted = amm.iporWeighted;
        amm.dai.iporWeighted = amm.iporWeighted;

        _iporOracleFactory.upgrade(
            address(amm.iporOracle),
            cfg.iporOracleUpdater,
            IporOracleFactory.IporOracleConstructorParams({
                usdt: address(amm.usdt.asset),
                usdtInitialIbtPrice: 1e18,
                usdc: address(amm.usdc.asset),
                usdcInitialIbtPrice: 1e18,
                dai: address(amm.dai.asset),
                daiInitialIbtPrice: 1e18
            })
        );

        amm.iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
            assets,
            cfg.iporRiskManagementOracleUpdater,
            cfg.iporRiskManagementOracleInitialParamsTestCase
        );

        amm.usdt.ipToken = _ipTokenBuilder
            .withName("IP USDT")
            .withSymbol("ipUSDT")
            .withAsset(address(amm.usdt.asset))
            .build();
        amm.usdt.ivToken = _ivTokenBuilder
            .withName("IV USDT")
            .withSymbol("ivUSDT")
            .withAsset(address(amm.usdt.asset))
            .build();

        amm.usdc.ipToken = _ipTokenBuilder
            .withName("IP USDC")
            .withSymbol("ipUSDC")
            .withAsset(address(amm.usdc.asset))
            .build();
        amm.usdc.ivToken = _ivTokenBuilder
            .withName("IV USDC")
            .withSymbol("ivUSDC")
            .withAsset(address(amm.usdc.asset))
            .build();

        amm.dai.ipToken = _ipTokenBuilder
            .withName("IP DAI")
            .withSymbol("ipDAI")
            .withAsset(address(amm.dai.asset))
            .build();
        amm.dai.ivToken = _ivTokenBuilder
            .withName("IV DAI")
            .withSymbol("ivDAI")
            .withAsset(address(amm.dai.asset))
            .build();

        _ammStorageBuilder.withIporProtocolRouter(address(amm.router));
        _ammStorageBuilder.withAmmTreasury(address(amm.usdt.ammTreasury));
        amm.usdt.ammStorage = _ammStorageBuilder.build();

        _ammStorageBuilder.withAmmTreasury(address(amm.usdc.ammTreasury));
        amm.usdc.ammStorage = _ammStorageBuilder.build();

        _ammStorageBuilder.withAmmTreasury(address(amm.dai.ammTreasury));
        amm.dai.ammStorage = _ammStorageBuilder.build();

        _spreadRouterBuilder.withIporRouter(address(amm.router));
        _spreadRouterBuilder.withUsdt(address(amm.usdt.asset));

        _spreadRouterBuilder.withUsdc(address(amm.usdc.asset));
        _spreadRouterBuilder.withDai(address(amm.dai.asset));

        _spreadRouterBuilder.withSpread28DaysTestCase(cfg.spread28DaysTestCase);
        _spreadRouterBuilder.withSpread60DaysTestCase(cfg.spread60DaysTestCase);
        _spreadRouterBuilder.withSpread90DaysTestCase(cfg.spread90DaysTestCase);

        amm.spreadRouter = _spreadRouterBuilder.build();
        amm.usdt.spreadRouter = amm.spreadRouter;
        amm.usdc.spreadRouter = amm.spreadRouter;
        amm.dai.spreadRouter = amm.spreadRouter;

        amm.usdt.assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(amm.usdt.asset))
            .withIvToken(address(amm.usdt.ivToken))
            .withAssetManagementImplementation(cfg.usdtAssetManagementImplementation)
            .build();

        amm.usdc.assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(amm.usdc.asset))
            .withIvToken(address(amm.usdc.ivToken))
            .withAssetManagementImplementation(cfg.usdcAssetManagementImplementation)
            .build();

        amm.dai.assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(amm.dai.asset))
            .withIvToken(address(amm.dai.ivToken))
            .withAssetManagementImplementation(cfg.daiAssetManagementImplementation)
            .build();

        _ammTreasuryBuilder
            .withAsset(address(amm.usdt.asset))
            .withAmmStorage(address(amm.usdt.ammStorage))
            .withAssetManagement(address(amm.usdt.assetManagement))
            .withIporProtocolRouter(address(amm.router))
            .withAmmTreasuryProxyAddress(address(amm.usdt.ammTreasury))
            .upgrade();

        _ammTreasuryBuilder
            .withAsset(address(amm.usdc.asset))
            .withAmmStorage(address(amm.usdc.ammStorage))
            .withAssetManagement(address(amm.usdc.assetManagement))
            .withIporProtocolRouter(address(amm.router))
            .withAmmTreasuryProxyAddress(address(amm.usdc.ammTreasury))
            .upgrade();

        _ammTreasuryBuilder
            .withAsset(address(amm.dai.asset))
            .withAmmStorage(address(amm.dai.ammStorage))
            .withAssetManagement(address(amm.dai.assetManagement))
            .withIporProtocolRouter(address(amm.router))
            .withAmmTreasuryProxyAddress(address(amm.dai.ammTreasury))
            .upgrade();

        amm.router = _getFullIporProtocolRouterInstance(amm, cfg);

        vm.startPrank(address(_owner));

        amm.usdt.ivToken.setAssetManagement(address(amm.usdt.assetManagement));
        amm.usdc.ivToken.setAssetManagement(address(amm.usdc.assetManagement));
        amm.dai.ivToken.setAssetManagement(address(amm.dai.assetManagement));

        amm.usdt.ipToken.setJoseph(address(amm.router));
        amm.usdc.ipToken.setJoseph(address(amm.router));
        amm.dai.ipToken.setJoseph(address(amm.router));

        amm.usdt.assetManagement.setAmmTreasury((address(amm.usdt.ammTreasury)));
        amm.usdc.assetManagement.setAmmTreasury((address(amm.usdc.ammTreasury)));
        amm.dai.assetManagement.setAmmTreasury((address(amm.dai.ammTreasury)));

        amm.usdt.ammTreasury.setupMaxAllowanceForAsset(address(amm.usdt.assetManagement));
        amm.usdc.ammTreasury.setupMaxAllowanceForAsset(address(amm.usdc.assetManagement));
        amm.dai.ammTreasury.setupMaxAllowanceForAsset(address(amm.dai.assetManagement));

        amm.usdt.ammTreasury.setupMaxAllowanceForAsset(address(amm.router));
        amm.usdc.ammTreasury.setupMaxAllowanceForAsset(address(amm.router));
        amm.dai.ammTreasury.setupMaxAllowanceForAsset(address(amm.router));

        IAmmGovernanceService(address(amm.router)).setAmmPoolsParams(
            address(amm.usdt.asset),
            1000000000,
            1000000000,
            50,
            8500
        );

        IAmmGovernanceService(address(amm.router)).setAmmPoolsParams(
            address(amm.usdc.asset),
            1000000000,
            1000000000,
            50,
            8500
        );

        IAmmGovernanceService(address(amm.router)).setAmmPoolsParams(
            address(amm.dai.asset),
            1000000000,
            1000000000,
            50,
            8500
        );

        vm.stopPrank();
    }

    function getUsdtInstance(
        IporProtocolConfig memory cfg
    ) public returns (BuilderUtils.IporProtocol memory iporProtocol) {
        iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        iporProtocol.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();

        _assetBuilder.withUSDT();
        iporProtocol.asset = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(iporProtocol.asset);

        iporProtocol.iporOracle = _iporOracleFactory.getEmptyInstance(assets, cfg.iporOracleInitialParamsTestCase);

        iporProtocol.iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle)).build();

        _iporOracleFactory.upgrade(
            address(iporProtocol.iporOracle),
            cfg.iporOracleUpdater,
            IporOracleFactory.IporOracleConstructorParams({
                usdc: _fakeContract,
                usdcInitialIbtPrice: 0,
                usdt: address(iporProtocol.asset),
                usdtInitialIbtPrice: 1e18,
                dai: _fakeContract,
                daiInitialIbtPrice: 0
            })
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

        _ammStorageBuilder.withIporProtocolRouter(address(iporProtocol.router));
        _ammStorageBuilder.withAmmTreasury(address(iporProtocol.ammTreasury));
        iporProtocol.ammStorage = _ammStorageBuilder.build();

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

        _ammTreasuryBuilder
            .withAsset(address(iporProtocol.asset))
            .withAmmStorage(address(iporProtocol.ammStorage))
            .withAssetManagement(address(iporProtocol.assetManagement))
            .withIporProtocolRouter(address(iporProtocol.router))
            .withAmmTreasuryProxyAddress(address(iporProtocol.ammTreasury))
            .upgrade();

        iporProtocol.router = _getUsdtIporProtocolRouterInstance(iporProtocol, cfg);

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));

        vm.startPrank(address(_owner));

        iporProtocol.ivToken.setAssetManagement(address(iporProtocol.assetManagement));

        iporProtocol.assetManagement.setAmmTreasury((address(iporProtocol.ammTreasury)));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.assetManagement));

        iporProtocol.ipToken.setJoseph(address(iporProtocol.router));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmPoolsParams(
            address(iporProtocol.asset),
            1000000000,
            1000000000,
            50,
            8500
        );

        vm.stopPrank();

        //setup
        setupUsers(cfg, iporProtocol);
    }

    function getUsdcInstance(
        IporProtocolConfig memory cfg
    ) public returns (BuilderUtils.IporProtocol memory iporProtocol) {
        iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        iporProtocol.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();

        _assetBuilder.withUSDC();
        iporProtocol.asset = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(iporProtocol.asset);

        iporProtocol.iporOracle = _iporOracleFactory.getEmptyInstance(assets, cfg.iporOracleInitialParamsTestCase);

        iporProtocol.iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle)).build();

        _iporOracleFactory.upgrade(
            address(iporProtocol.iporOracle),
            cfg.iporOracleUpdater,
            IporOracleFactory.IporOracleConstructorParams({
                usdc: address(iporProtocol.asset),
                usdcInitialIbtPrice: 1e18,
                usdt: _fakeContract,
                usdtInitialIbtPrice: 0,
                dai: _fakeContract,
                daiInitialIbtPrice: 0
            })
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

        _ammStorageBuilder.withIporProtocolRouter(address(iporProtocol.router));
        _ammStorageBuilder.withAmmTreasury(address(iporProtocol.ammTreasury));
        iporProtocol.ammStorage = _ammStorageBuilder.build();

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

        _ammTreasuryBuilder
            .withAsset(address(iporProtocol.asset))
            .withAmmStorage(address(iporProtocol.ammStorage))
            .withAssetManagement(address(iporProtocol.assetManagement))
            .withIporProtocolRouter(address(iporProtocol.router))
            .withAmmTreasuryProxyAddress(address(iporProtocol.ammTreasury))
            .upgrade();

        iporProtocol.router = _getUsdcIporProtocolRouterInstance(iporProtocol, cfg);

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));

        vm.startPrank(address(_owner));

        iporProtocol.ivToken.setAssetManagement(address(iporProtocol.assetManagement));

        iporProtocol.assetManagement.setAmmTreasury((address(iporProtocol.ammTreasury)));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.assetManagement));

        iporProtocol.ipToken.setJoseph(address(iporProtocol.router));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmPoolsParams(
            address(iporProtocol.asset),
            1000000000,
            1000000000,
            50,
            8500
        );

        vm.stopPrank();

        //setup
        setupUsers(cfg, iporProtocol);
    }

    function getDaiInstance(
        IporProtocolConfig memory cfg
    ) public returns (BuilderUtils.IporProtocol memory iporProtocol) {
        iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        iporProtocol.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();

        _assetBuilder.withDAI();

        iporProtocol.asset = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(iporProtocol.asset);

        iporProtocol.iporOracle = _iporOracleFactory.getEmptyInstance(assets, cfg.iporOracleInitialParamsTestCase);

        iporProtocol.iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporProtocol.iporOracle)).build();

        _iporOracleFactory.upgrade(
            address(iporProtocol.iporOracle),
            cfg.iporOracleUpdater,
            IporOracleFactory.IporOracleConstructorParams({
                usdc: _fakeContract,
                usdcInitialIbtPrice: 0,
                usdt: _fakeContract,
                usdtInitialIbtPrice: 0,
                dai: address(iporProtocol.asset),
                daiInitialIbtPrice: 1e18
            })
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

        _ammStorageBuilder.withIporProtocolRouter(address(iporProtocol.router));
        _ammStorageBuilder.withAmmTreasury(address(iporProtocol.ammTreasury));
        iporProtocol.ammStorage = _ammStorageBuilder.build();

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

        _ammTreasuryBuilder
            .withAsset(address(iporProtocol.asset))
            .withAmmStorage(address(iporProtocol.ammStorage))
            .withAssetManagement(address(iporProtocol.assetManagement))
            .withIporProtocolRouter(address(iporProtocol.router))
            .withAmmTreasuryProxyAddress(address(iporProtocol.ammTreasury))
            .upgrade();

        iporProtocol.router = _getDaiIporProtocolRouterInstance(iporProtocol, cfg);

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));

        vm.startPrank(address(_owner));

        iporProtocol.ivToken.setAssetManagement(address(iporProtocol.assetManagement));

        iporProtocol.assetManagement.setAmmTreasury((address(iporProtocol.ammTreasury)));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.assetManagement));

        iporProtocol.ipToken.setJoseph(address(iporProtocol.router));
        iporProtocol.ammTreasury.setupMaxAllowanceForAsset(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmPoolsParams(
            address(iporProtocol.asset),
            1000000000,
            1000000000,
            50,
            8500
        );

        vm.stopPrank();

        //setup
        setupUsers(cfg, iporProtocol);
    }

    function _getFullIporProtocolRouterInstance(
        Amm memory amm,
        AmmConfig memory cfg
    ) public returns (IporProtocolRouter) {
        if (address(amm.router) == address(0)) {
            amm.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        }

        IporProtocolRouter.DeployedContracts memory deployerContracts;

        deployerContracts.ammSwapsLens = address(
            new AmmSwapsLens(
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(amm.usdt.asset),
                    ammStorage: address(amm.usdt.ammStorage),
                    ammTreasury: address(amm.usdt.ammTreasury),
                    minLeverage: 10 * 1e18
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(amm.usdc.asset),
                    ammStorage: address(amm.usdc.ammStorage),
                    ammTreasury: address(amm.usdc.ammTreasury),
                    minLeverage: 10 * 1e18
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(amm.dai.asset),
                    ammStorage: address(amm.dai.ammStorage),
                    ammTreasury: address(amm.dai.ammTreasury),
                    minLeverage: 10 * 1e18
                }),
                address(amm.iporOracle),
                address(amm.iporRiskManagementOracle),
                address(amm.spreadRouter)
            )
        );

        deployerContracts.ammPoolsLens = address(
            new AmmPoolsLens(
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(amm.usdt.asset),
                    decimals: amm.usdt.asset.decimals(),
                    ipToken: address(amm.usdt.ipToken),
                    ammStorage: address(amm.usdt.ammStorage),
                    ammTreasury: address(amm.usdt.ammTreasury),
                    assetManagement: address(amm.usdt.assetManagement)
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(amm.usdc.asset),
                    decimals: amm.usdc.asset.decimals(),
                    ipToken: address(amm.usdc.ipToken),
                    ammStorage: address(amm.usdc.ammStorage),
                    ammTreasury: address(amm.usdc.ammTreasury),
                    assetManagement: address(amm.usdc.assetManagement)
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(amm.dai.asset),
                    decimals: amm.dai.asset.decimals(),
                    ipToken: address(amm.dai.ipToken),
                    ammStorage: address(amm.dai.ammStorage),
                    ammTreasury: address(amm.dai.ammTreasury),
                    assetManagement: address(amm.dai.assetManagement)
                }),
                address(amm.iporOracle)
            )
        );

        deployerContracts.assetManagementLens = address(
            new AssetManagementLens(
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: address(amm.usdt.asset),
                    decimals: amm.usdt.asset.decimals(),
                    assetManagement: address(amm.usdt.assetManagement),
                    ammTreasury: address(amm.usdt.ammTreasury)
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: address(amm.usdc.asset),
                    decimals: amm.usdc.asset.decimals(),
                    assetManagement: address(amm.usdc.assetManagement),
                    ammTreasury: address(amm.usdc.ammTreasury)
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: address(amm.dai.asset),
                    decimals: amm.dai.asset.decimals(),
                    assetManagement: address(amm.dai.assetManagement),
                    ammTreasury: address(amm.dai.ammTreasury)
                })
            )
        );

        deployerContracts.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _preparePoolCfgForOpenSwapService(
                    cfg.openSwapServiceTestCase,
                    address(amm.usdt.asset),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage)
                ),
                usdcPoolCfg: _preparePoolCfgForOpenSwapService(
                    cfg.openSwapServiceTestCase,
                    address(amm.usdc.asset),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage)
                ),
                daiPoolCfg: _preparePoolCfgForOpenSwapService(
                    cfg.openSwapServiceTestCase,
                    address(amm.dai.asset),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage)
                ),
                iporOracle: address(amm.iporOracle),
                iporRiskManagementOracle: address(amm.iporRiskManagementOracle),
                spreadRouter: address(amm.spreadRouter)
            })
        );

        deployerContracts.ammCloseSwapService = address(
            new AmmCloseSwapService({
                usdtPoolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(amm.usdt.asset),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage),
                    address(amm.usdt.assetManagement)
                ),
                usdcPoolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(amm.usdc.asset),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage),
                    address(amm.usdc.assetManagement)
                ),
                daiPoolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(amm.dai.asset),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage),
                    address(amm.dai.assetManagement)
                ),
                iporOracle: address(amm.iporOracle),
                iporRiskManagementOracle: address(amm.iporRiskManagementOracle),
                spreadRouter: address(amm.spreadRouter)
            })
        );

        deployerContracts.ammPoolsService = address(
            new AmmPoolsService({
                usdtPoolCfg: _preparePoolCfgForPoolsService(
                    cfg.poolsServiceTestCase,
                    address(amm.usdt.asset),
                    address(amm.usdt.ipToken),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage),
                    address(amm.usdt.assetManagement)
                ),
                usdcPoolCfg: _preparePoolCfgForPoolsService(
                    cfg.poolsServiceTestCase,
                    address(amm.usdc.asset),
                    address(amm.usdc.ipToken),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage),
                    address(amm.usdc.assetManagement)
                ),
                daiPoolCfg: _preparePoolCfgForPoolsService(
                    cfg.poolsServiceTestCase,
                    address(amm.dai.asset),
                    address(amm.dai.ipToken),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage),
                    address(amm.dai.assetManagement)
                ),
                iporOracle: address(amm.iporOracle)
            })
        );

        deployerContracts.ammGovernanceService = address(
            new AmmGovernanceService({
                usdtPoolCfg: _preparePoolCfgForGovernanceService(
                    address(amm.usdt.asset),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage),
                    cfg.ammPoolsTreasury,
                    cfg.ammPoolsTreasuryManager,
                    cfg.ammCharlieTreasury,
                    cfg.ammCharlieTreasuryManager
                ),
                usdcPoolCfg: _preparePoolCfgForGovernanceService(
                    address(amm.usdc.asset),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage),
                    cfg.ammPoolsTreasury,
                    cfg.ammPoolsTreasuryManager,
                    cfg.ammCharlieTreasury,
                    cfg.ammCharlieTreasuryManager
                ),
                daiPoolCfg: _preparePoolCfgForGovernanceService(
                    address(amm.dai.asset),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage),
                    cfg.ammPoolsTreasury,
                    cfg.ammPoolsTreasuryManager,
                    cfg.ammCharlieTreasury,
                    cfg.ammCharlieTreasuryManager
                )
            })
        );

        deployerContracts.powerTokenLens = address(_powerTokenLensBuilder.build());
        deployerContracts.liquidityMiningLens = address(_liquidityMiningLensBuilder.build());
        deployerContracts.flowService = address(_powerTokenFlowsServiceBuilder.build());
        deployerContracts.stakeService = address(_powerTokenStakeServiceBuilder.build());

        vm.startPrank(address(_owner));
        IporProtocolRouter(amm.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        amm.usdt.ammSwapsLens = IAmmSwapsLens(address(amm.router));
        amm.usdt.ammPoolsService = IAmmPoolsService(address(amm.router));
        amm.usdt.ammPoolsLens = IAmmPoolsLens(address(amm.router));
        amm.usdt.ammOpenSwapService = IAmmOpenSwapService(address(amm.router));
        amm.usdt.ammOpenSwapLens = IAmmOpenSwapLens(address(amm.router));
        amm.usdt.ammCloseSwapService = IAmmCloseSwapService(address(amm.router));
        amm.usdt.ammGovernanceService = IAmmGovernanceService(address(amm.router));
        amm.usdt.ammGovernanceLens = IAmmGovernanceLens(address(amm.router));
        amm.usdt.powerTokenLens = IPowerTokenLens(address(amm.router));
        amm.usdt.liquidityMiningLens = ILiquidityMiningLens(address(amm.router));
        amm.usdt.flowService = IPowerTokenFlowsService(address(amm.router));
        amm.usdt.stakeService = IPowerTokenStakeService(address(amm.router));

        amm.usdc.ammSwapsLens = IAmmSwapsLens(address(amm.router));
        amm.usdc.ammPoolsService = IAmmPoolsService(address(amm.router));
        amm.usdc.ammPoolsLens = IAmmPoolsLens(address(amm.router));
        amm.usdc.ammOpenSwapService = IAmmOpenSwapService(address(amm.router));
        amm.usdc.ammOpenSwapLens = IAmmOpenSwapLens(address(amm.router));
        amm.usdc.ammCloseSwapService = IAmmCloseSwapService(address(amm.router));
        amm.usdc.ammGovernanceService = IAmmGovernanceService(address(amm.router));
        amm.usdc.ammGovernanceLens = IAmmGovernanceLens(address(amm.router));
        amm.usdc.powerTokenLens = IPowerTokenLens(address(amm.router));
        amm.usdc.liquidityMiningLens = ILiquidityMiningLens(address(amm.router));
        amm.usdc.flowService = IPowerTokenFlowsService(address(amm.router));
        amm.usdc.stakeService = IPowerTokenStakeService(address(amm.router));

        amm.dai.ammSwapsLens = IAmmSwapsLens(address(amm.router));
        amm.dai.ammPoolsService = IAmmPoolsService(address(amm.router));
        amm.dai.ammPoolsLens = IAmmPoolsLens(address(amm.router));
        amm.dai.ammOpenSwapService = IAmmOpenSwapService(address(amm.router));
        amm.dai.ammOpenSwapLens = IAmmOpenSwapLens(address(amm.router));
        amm.dai.ammCloseSwapService = IAmmCloseSwapService(address(amm.router));
        amm.dai.ammGovernanceService = IAmmGovernanceService(address(amm.router));
        amm.dai.ammGovernanceLens = IAmmGovernanceLens(address(amm.router));
        amm.dai.powerTokenLens = IPowerTokenLens(address(amm.router));
        amm.dai.liquidityMiningLens = ILiquidityMiningLens(address(amm.router));
        amm.dai.flowService = IPowerTokenFlowsService(address(amm.router));
        amm.dai.stakeService = IPowerTokenStakeService(address(amm.router));

        return IporProtocolRouter(amm.router);
    }

    function _getUsdtIporProtocolRouterInstance(
        BuilderUtils.IporProtocol memory iporProtocol,
        IporProtocolConfig memory cfg
    ) public returns (IporProtocolRouter) {
        if (address(iporProtocol.router) == address(0)) {
            iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        }

        IporProtocolRouter.DeployedContracts memory deployerContracts;

        deployerContracts.ammSwapsLens = address(
            new AmmSwapsLens(
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(iporProtocol.asset),
                    ammStorage: address(iporProtocol.ammStorage),
                    ammTreasury: address(iporProtocol.ammTreasury),
                    minLeverage: 10 * 1e18
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    minLeverage: 0
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    minLeverage: 0
                }),
                address(iporProtocol.iporOracle),
                address(iporProtocol.iporRiskManagementOracle),
                address(iporProtocol.spreadRouter)
            )
        );

        deployerContracts.ammPoolsLens = address(
            new AmmPoolsLens(
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(iporProtocol.asset),
                    decimals: iporProtocol.asset.decimals(),
                    ipToken: address(iporProtocol.ipToken),
                    ammStorage: address(iporProtocol.ammStorage),
                    ammTreasury: address(iporProtocol.ammTreasury),
                    assetManagement: address(iporProtocol.assetManagement)
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    ipToken: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    assetManagement: _fakeContract
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    ipToken: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    assetManagement: _fakeContract
                }),
                address(iporProtocol.iporOracle)
            )
        );

        deployerContracts.assetManagementLens = address(
            new AssetManagementLens(
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: address(iporProtocol.asset),
                    decimals: iporProtocol.asset.decimals(),
                    assetManagement: address(iporProtocol.assetManagement),
                    ammTreasury: address(iporProtocol.ammTreasury)
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    assetManagement: _fakeContract,
                    ammTreasury: _fakeContract
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    assetManagement: _fakeContract,
                    ammTreasury: _fakeContract
                })
            )
        );

        deployerContracts.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _preparePoolCfgForOpenSwapService(
                    cfg.openSwapServiceTestCase,
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
                    cfg.closeSwapServiceTestCase,
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
                    cfg.poolsServiceTestCase,
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
                    address(iporProtocol.ammStorage),
                    cfg.ammPoolsTreasury,
                    cfg.ammPoolsTreasuryManager,
                    cfg.ammCharlieTreasury,
                    cfg.ammCharlieTreasuryManager
                ),
                usdcPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                daiPoolCfg: _prepareFakePoolCfgForGovernanceService()
            })
        );

        deployerContracts.powerTokenLens = address(_powerTokenLensBuilder.build());
        deployerContracts.liquidityMiningLens = address(_liquidityMiningLensBuilder.build());
        deployerContracts.flowService = address(_powerTokenFlowsServiceBuilder.build());
        deployerContracts.stakeService = address(_powerTokenStakeServiceBuilder.build());

        vm.startPrank(address(_owner));
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));
        iporProtocol.powerTokenLens = IPowerTokenLens(address(iporProtocol.router));
        iporProtocol.liquidityMiningLens = ILiquidityMiningLens(address(iporProtocol.router));
        iporProtocol.flowService = IPowerTokenFlowsService(address(iporProtocol.router));
        iporProtocol.stakeService = IPowerTokenStakeService(address(iporProtocol.router));

        return IporProtocolRouter(iporProtocol.router);
    }

    function _getUsdcIporProtocolRouterInstance(
        BuilderUtils.IporProtocol memory iporProtocol,
        IporProtocolConfig memory cfg
    ) public returns (IporProtocolRouter) {
        if (address(iporProtocol.router) == address(0)) {
            iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        }

        IporProtocolRouter.DeployedContracts memory deployerContracts;

        deployerContracts.ammSwapsLens = address(
            new AmmSwapsLens(
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    minLeverage: 0
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(iporProtocol.asset),
                    ammStorage: address(iporProtocol.ammStorage),
                    ammTreasury: address(iporProtocol.ammTreasury),
                    minLeverage: 10 * 1e18
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    minLeverage: 0
                }),
                address(iporProtocol.iporOracle),
                address(iporProtocol.iporRiskManagementOracle),
                address(iporProtocol.spreadRouter)
            )
        );

        deployerContracts.ammPoolsLens = address(
            new AmmPoolsLens(
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    ipToken: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    assetManagement: _fakeContract
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(iporProtocol.asset),
                    decimals: iporProtocol.asset.decimals(),
                    ipToken: address(iporProtocol.ipToken),
                    ammStorage: address(iporProtocol.ammStorage),
                    ammTreasury: address(iporProtocol.ammTreasury),
                    assetManagement: address(iporProtocol.assetManagement)
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    ipToken: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    assetManagement: _fakeContract
                }),
                address(iporProtocol.iporOracle)
            )
        );

        deployerContracts.assetManagementLens = address(
            new AssetManagementLens(
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    assetManagement: _fakeContract,
                    ammTreasury: _fakeContract
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: address(iporProtocol.asset),
                    decimals: iporProtocol.asset.decimals(),
                    assetManagement: address(iporProtocol.assetManagement),
                    ammTreasury: address(iporProtocol.ammTreasury)
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    assetManagement: _fakeContract,
                    ammTreasury: _fakeContract
                })
            )
        );

        deployerContracts.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                usdcPoolCfg: _preparePoolCfgForOpenSwapService(
                    cfg.openSwapServiceTestCase,
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
                    cfg.closeSwapServiceTestCase,
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
                    cfg.poolsServiceTestCase,
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
                    address(iporProtocol.ammStorage),
                    cfg.ammPoolsTreasury,
                    cfg.ammPoolsTreasuryManager,
                    cfg.ammCharlieTreasury,
                    cfg.ammCharlieTreasuryManager
                ),
                daiPoolCfg: _prepareFakePoolCfgForGovernanceService()
            })
        );

        deployerContracts.powerTokenLens = address(_powerTokenLensBuilder.build());
        deployerContracts.liquidityMiningLens = address(_liquidityMiningLensBuilder.build());
        deployerContracts.flowService = address(_powerTokenFlowsServiceBuilder.build());
        deployerContracts.stakeService = address(_powerTokenStakeServiceBuilder.build());

        vm.startPrank(address(_owner));
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));
        iporProtocol.powerTokenLens = IPowerTokenLens(address(iporProtocol.router));
        iporProtocol.liquidityMiningLens = ILiquidityMiningLens(address(iporProtocol.router));
        iporProtocol.flowService = IPowerTokenFlowsService(address(iporProtocol.router));
        iporProtocol.stakeService = IPowerTokenStakeService(address(iporProtocol.router));

        return IporProtocolRouter(iporProtocol.router);
    }

    function _getDaiIporProtocolRouterInstance(
        BuilderUtils.IporProtocol memory iporProtocol,
        IporProtocolConfig memory cfg
    ) public returns (IporProtocolRouter) {
        if (address(iporProtocol.router) == address(0)) {
            iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        }

        IporProtocolRouter.DeployedContracts memory deployerContracts;

        deployerContracts.ammSwapsLens = address(
            new AmmSwapsLens(
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    minLeverage: 0
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    minLeverage: 0
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(iporProtocol.asset),
                    ammStorage: address(iporProtocol.ammStorage),
                    ammTreasury: address(iporProtocol.ammTreasury),
                    minLeverage: 10 * 1e18
                }),
                address(iporProtocol.iporOracle),
                address(iporProtocol.iporRiskManagementOracle),
                address(iporProtocol.spreadRouter)
            )
        );

        deployerContracts.ammPoolsLens = address(
            new AmmPoolsLens(
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    ipToken: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    assetManagement: _fakeContract
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    ipToken: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    assetManagement: _fakeContract
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(iporProtocol.asset),
                    decimals: iporProtocol.asset.decimals(),
                    ipToken: address(iporProtocol.ipToken),
                    ammStorage: address(iporProtocol.ammStorage),
                    ammTreasury: address(iporProtocol.ammTreasury),
                    assetManagement: address(iporProtocol.assetManagement)
                }),
                address(iporProtocol.iporOracle)
            )
        );

        deployerContracts.assetManagementLens = address(
            new AssetManagementLens(
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    assetManagement: _fakeContract,
                    ammTreasury: _fakeContract
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: _fakeContract,
                    decimals: 0,
                    assetManagement: _fakeContract,
                    ammTreasury: _fakeContract
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: address(iporProtocol.asset),
                    decimals: iporProtocol.asset.decimals(),
                    assetManagement: address(iporProtocol.assetManagement),
                    ammTreasury: address(iporProtocol.ammTreasury)
                })
            )
        );

        deployerContracts.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                usdcPoolCfg: _prepareFakePoolCfgForOpenSwapService(),
                daiPoolCfg: _preparePoolCfgForOpenSwapService(
                    cfg.openSwapServiceTestCase,
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
                    cfg.closeSwapServiceTestCase,
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
                    cfg.poolsServiceTestCase,
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
                    address(iporProtocol.ammStorage),
                    cfg.ammPoolsTreasury,
                    cfg.ammPoolsTreasuryManager,
                    cfg.ammCharlieTreasury,
                    cfg.ammCharlieTreasuryManager
                )
            })
        );

        deployerContracts.powerTokenLens = address(_powerTokenLensBuilder.build());
        deployerContracts.liquidityMiningLens = address(_liquidityMiningLensBuilder.build());
        deployerContracts.flowService = address(_powerTokenFlowsServiceBuilder.build());
        deployerContracts.stakeService = address(_powerTokenStakeServiceBuilder.build());

        vm.startPrank(address(_owner));
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapService = IAmmCloseSwapService(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));
        iporProtocol.liquidityMiningLens = ILiquidityMiningLens(address(iporProtocol.router));
        iporProtocol.powerTokenLens = IPowerTokenLens(address(iporProtocol.router));
        iporProtocol.flowService = IPowerTokenFlowsService(address(iporProtocol.router));
        iporProtocol.stakeService = IPowerTokenStakeService(address(iporProtocol.router));

        return IporProtocolRouter(iporProtocol.router);
    }

    function _prepareFakePoolCfgForGovernanceService()
        internal
        returns (IAmmGovernanceLens.AmmGovernancePoolConfiguration memory poolCfg)
    {
        poolCfg = IAmmGovernanceLens.AmmGovernancePoolConfiguration({
            asset: address(_fakeContract),
            decimals: 0,
            ammStorage: address(_fakeContract),
            ammTreasury: address(_fakeContract),
            ammPoolsTreasury: address(_fakeContract),
            ammPoolsTreasuryManager: address(_fakeContract),
            ammCharlieTreasury: address(_fakeContract),
            ammCharlieTreasuryManager: address(_fakeContract)
        });
    }

    function _prepareFakePoolCfgForPoolsService()
        internal
        returns (AmmPoolsService.AmmPoolsServicePoolConfiguration memory poolCfg)
    {
        poolCfg = IAmmPoolsService.AmmPoolsServicePoolConfiguration({
            asset: address(_fakeContract),
            decimals: 0,
            ipToken: address(_fakeContract),
            ammStorage: address(_fakeContract),
            ammTreasury: address(_fakeContract),
            assetManagement: address(_fakeContract),
            redeemFeeRate: 0,
            redeemLpMaxCollateralRatio: 0
        });
    }

    function _prepareFakePoolCfgForCloseSwapService()
        internal
        returns (IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration memory poolCfg)
    {
        poolCfg = IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration({
            asset: address(_fakeContract),
            decimals: 0,
            ammStorage: address(_fakeContract),
            ammTreasury: address(_fakeContract),
            assetManagement: address(_fakeContract),
            openingFeeRateForSwapUnwind: 0,
            openingFeeTreasuryPortionRateForSwapUnwind: 0,
            maxLengthOfLiquidatedSwapsPerLeg: 0,
            timeBeforeMaturityAllowedToCloseSwapByCommunity: 0,
            timeBeforeMaturityAllowedToCloseSwapByBuyer: 0,
            minLiquidationThresholdToCloseBeforeMaturityByCommunity: 0,
            minLiquidationThresholdToCloseBeforeMaturityByBuyer: 0,
            minLeverage: 0
        });
    }

    function _prepareFakePoolCfgForOpenSwapService()
        internal
        returns (IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration memory poolCfg)
    {
        poolCfg = IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration({
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
        address ammStorage,
        address ammPoolsTreasury,
        address ammPoolsTreasuryManager,
        address ammCharlieTreasury,
        address ammCharlieTreasuryManager
    ) internal returns (IAmmGovernanceLens.AmmGovernancePoolConfiguration memory poolCfg) {
        poolCfg = IAmmGovernanceLens.AmmGovernancePoolConfiguration({
            asset: asset,
            decimals: IERC20MetadataUpgradeable(asset).decimals(),
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            ammPoolsTreasury: ammPoolsTreasury == address(0) ? _owner : ammPoolsTreasury,
            ammPoolsTreasuryManager: ammPoolsTreasuryManager == address(0) ? _owner : ammPoolsTreasuryManager,
            ammCharlieTreasury: ammCharlieTreasury == address(0) ? _owner : ammCharlieTreasury,
            ammCharlieTreasuryManager: ammCharlieTreasuryManager == address(0) ? _owner : ammCharlieTreasuryManager
        });
    }

    function _preparePoolCfgForPoolsService(
        BuilderUtils.AmmPoolsServiceTestCase poolsServiceTestCase,
        address asset,
        address ipToken,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) internal returns (AmmPoolsService.AmmPoolsServicePoolConfiguration memory poolCfg) {
        if (poolsServiceTestCase == BuilderUtils.AmmPoolsServiceTestCase.CASE1) {
            poolCfg = IAmmPoolsService.AmmPoolsServicePoolConfiguration({
                asset: asset,
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ipToken: ipToken,
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                redeemFeeRate: 0,
                redeemLpMaxCollateralRatio: 1e18
            });
        } else {
            poolCfg = IAmmPoolsService.AmmPoolsServicePoolConfiguration({
                asset: asset,
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ipToken: ipToken,
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                redeemFeeRate: 5 * 1e15,
                redeemLpMaxCollateralRatio: 1e18
            });
        }
    }

    function _preparePoolCfgForCloseSwapService(
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase,
        address asset,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) internal returns (IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration memory poolCfg) {
        if (closeSwapServiceTestCase == BuilderUtils.AmmCloseSwapServiceTestCase.DEFAULT) {
            poolCfg = IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration({
                asset: address(asset),
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                openingFeeRateForSwapUnwind: 5 * 1e14,
                openingFeeTreasuryPortionRateForSwapUnwind: 5 * 1e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18
            });
        } else if (closeSwapServiceTestCase == BuilderUtils.AmmCloseSwapServiceTestCase.CASE1) {
            poolCfg = IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration({
                asset: address(asset),
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                openingFeeRateForSwapUnwind: 5 * 1e14,
                openingFeeTreasuryPortionRateForSwapUnwind: 5 * 1e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18
            });
        }
    }

    function _preparePoolCfgForOpenSwapService(
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase,
        address asset,
        address ammTreasury,
        address ammStorage
    ) internal returns (IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration memory poolCfg) {
        if (openSwapServiceTestCase == BuilderUtils.AmmOpenSwapServiceTestCase.DEFAULT) {
            poolCfg = IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration({
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
            poolCfg = IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration({
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
        } else if (openSwapServiceTestCase == BuilderUtils.AmmOpenSwapServiceTestCase.CASE2) {
            poolCfg = IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration({
                asset: asset,
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                iporPublicationFee: 10 * 1e18,
                maxSwapCollateralAmount: 100_000 * 1e18,
                liquidationDepositAmount: 20,
                minLeverage: 10 * 1e18,
                openingFeeRate: 3e14,
                openingFeeTreasuryPortionRate: 5e16
            });
        } else if (openSwapServiceTestCase == BuilderUtils.AmmOpenSwapServiceTestCase.CASE3) {
            poolCfg = IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration({
                asset: asset,
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                iporPublicationFee: 10 * 1e18,
                maxSwapCollateralAmount: 100_000 * 1e18,
                liquidationDepositAmount: 25,
                minLeverage: 10 * 1e18,
                openingFeeRate: 5e14,
                openingFeeTreasuryPortionRate: 5e17
            });
        }
    }

    function setupUsers(
        IporProtocolFactory.IporProtocolConfig memory cfg,
        BuilderUtils.IporProtocol memory iporProtocol
    ) public {
        if (iporProtocol.asset.decimals() == 18) {
            for (uint256 i; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                iporProtocol.asset.approve(address(iporProtocol.router), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
                vm.stopPrank();
                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_18DEC);
            }
        } else if (iporProtocol.asset.decimals() == 6) {
            for (uint256 i; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                iporProtocol.asset.approve(address(iporProtocol.router), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
                vm.stopPrank();
                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_6DEC);
            }
        } else {
            revert("Unsupported decimals");
        }
    }
}
