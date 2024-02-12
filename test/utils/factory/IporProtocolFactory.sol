// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "forge-std/Test.sol";
import "../../../contracts/tokens/IpToken.sol";
import "../../../contracts/oracles/IporOracle.sol";

import "../builder/AssetBuilder.sol";
import "../builder/IpTokenBuilder.sol";
import "../builder/IporWeightedBuilder.sol";
import "../builder/AmmStorageBuilder.sol";
import "../builder/AssetManagementBuilder.sol";
import "../builder/SpreadRouterBuilder.sol";
import "../builder/AmmTreasuryBuilder.sol";
import "../builder/IporProtocolRouterBuilder.sol";
import "../../utils/factory/IporOracleFactory.sol";
import "../../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../../contracts/interfaces/IAmmPoolsLens.sol";
import "../../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../../contracts/interfaces/IAssetManagementLens.sol";
import "../../../contracts/interfaces/IPowerTokenLens.sol";
import "../../../contracts/interfaces/ILiquidityMiningLens.sol";
import "../../../contracts/interfaces/IPowerTokenFlowsService.sol";
import "../../../contracts/interfaces/IPowerTokenStakeService.sol";
import "../../../contracts/chains/ethereum/amm-commons/AmmSwapsLens.sol";
import "../../../contracts/amm/AmmPoolsLens.sol";
import "../../../contracts/amm/AssetManagementLens.sol";
import "../../../contracts/amm/AmmOpenSwapService.sol";
import "../../../contracts/amm/AmmCloseSwapServiceUsdt.sol";
import "../../../contracts/amm/AmmCloseSwapServiceUsdc.sol";
import "../../../contracts/amm/AmmCloseSwapServiceDai.sol";
import "../../../contracts/chains/ethereum/amm-commons/AmmCloseSwapLens.sol";

import "../../../contracts/amm/AmmPoolsService.sol";
import "../../../contracts/chains/ethereum/amm-commons/AmmGovernanceService.sol";
import "../../mocks/EmptyImplementation.sol";
import "../builder/PowerTokenLensBuilder.sol";
import "../builder/LiquidityMiningLensBuilder.sol";
import "../builder/PowerTokenFlowsServiceBuilder.sol";
import "../builder/PowerTokenStakeServiceBuilder.sol";

contract IporProtocolFactory is Test {
    struct Amm {
        IporProtocolRouter router;
        SpreadRouter spreadRouter;
        IporOracle iporOracle;
        MockIporWeighted iporWeighted;
        BuilderUtils.IporProtocol usdt;
        BuilderUtils.IporProtocol usdc;
        BuilderUtils.IporProtocol dai;
        BuilderUtils.IporProtocol stEth;
        BuilderUtils.IporProtocol usdm;
    }

    struct AmmConfig {
        address ammPoolsTreasury;
        address ammPoolsTreasuryManager;
        address ammCharlieTreasury;
        address ammCharlieTreasuryManager;
        address iporOracleUpdater;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
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
        BuilderUtils.AmmOpenSwapServiceTestCase openSwapServiceTestCase;
        BuilderUtils.AmmCloseSwapServiceTestCase closeSwapServiceTestCase;
        BuilderUtils.AmmPoolsServiceTestCase poolsServiceTestCase;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        BuilderUtils.Spread28DaysTestCase spread28DaysTestCase;
        BuilderUtils.Spread60DaysTestCase spread60DaysTestCase;
        BuilderUtils.Spread90DaysTestCase spread90DaysTestCase;
        address[] approvalsForUsers;
        address spreadImplementation;
        address assetManagementImplementation;
    }

    IporOracleFactory internal _iporOracleFactory;

    AssetBuilder internal _assetBuilder;
    IpTokenBuilder internal _ipTokenBuilder;
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
    uint256 public messageSignerPrivateKey;
    address public messageSignerAddress;

    constructor(address owner) {
        _iporOracleFactory = new IporOracleFactory(owner);
        _assetBuilder = new AssetBuilder(owner);
        _ipTokenBuilder = new IpTokenBuilder(owner);
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
        messageSignerPrivateKey = 0x12341234;
        messageSignerAddress = vm.addr(messageSignerPrivateKey);
    }

    function getFullInstance(AmmConfig memory cfg) public returns (Amm memory amm) {
        amm.router = _iporProtocolRouterBuilder.buildEmptyProxy();

        amm.usdt.assetManagement = _assetManagementBuilder.buildEmptyProxy();
        amm.usdc.assetManagement = _assetManagementBuilder.buildEmptyProxy();
        amm.dai.assetManagement = _assetManagementBuilder.buildEmptyProxy();


        amm.usdt.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();
        amm.usdc.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();
        amm.dai.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();
        amm.stEth.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();
        amm.usdm.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();

        amm.usdt.router = amm.router;
        amm.usdc.router = amm.router;
        amm.dai.router = amm.router;
        amm.stEth.router = amm.router;
        amm.usdm.router = amm.router;

        _assetBuilder.withUSDT();
        amm.usdt.asset = _assetBuilder.build();

        _assetBuilder.withUSDC();
        amm.usdc.asset = _assetBuilder.build();

        _assetBuilder.withDAI();
        amm.dai.asset = _assetBuilder.build();

        _assetBuilder.withStEth();
        amm.stEth.asset = _assetBuilder.build();

        _assetBuilder.withUSDM();
        amm.usdm.asset = _assetBuilder.build();

        address[] memory assets = new address[](5);
        assets[0] = address(amm.dai.asset);
        assets[1] = address(amm.usdt.asset);
        assets[2] = address(amm.usdc.asset);
        assets[3] = address(amm.stEth.asset);
        assets[4] = address(amm.usdm.asset);

        amm.iporOracle = _iporOracleFactory.getEmptyInstance(assets, cfg.iporOracleInitialParamsTestCase);

        amm.usdt.iporOracle = amm.iporOracle;
        amm.usdc.iporOracle = amm.iporOracle;
        amm.dai.iporOracle = amm.iporOracle;
        amm.stEth.iporOracle = amm.iporOracle;
        amm.usdm.iporOracle = amm.iporOracle;

        amm.iporWeighted = _iporWeightedBuilder.withIporOracle(address(amm.iporOracle)).build();
        amm.usdt.iporWeighted = amm.iporWeighted;
        amm.usdc.iporWeighted = amm.iporWeighted;
        amm.dai.iporWeighted = amm.iporWeighted;
        amm.stEth.iporWeighted = amm.iporWeighted;
        amm.usdm.iporWeighted = amm.iporWeighted;

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

        amm.usdt.ipToken = _ipTokenBuilder
            .withName("IP USDT")
            .withSymbol("ipUSDT")
            .withAsset(address(amm.usdt.asset))
            .build();

        amm.usdc.ipToken = _ipTokenBuilder
            .withName("IP USDC")
            .withSymbol("ipUSDC")
            .withAsset(address(amm.usdc.asset))
            .build();

        amm.dai.ipToken = _ipTokenBuilder
            .withName("IP DAI")
            .withSymbol("ipDAI")
            .withAsset(address(amm.dai.asset))
            .build();

        amm.stEth.ipToken = _ipTokenBuilder
            .withName("IP stETH")
            .withSymbol("ipstETH")
            .withAsset(address(amm.stEth.asset))
            .build();

        amm.usdm.ipToken = _ipTokenBuilder
            .withName("IP USDM")
            .withSymbol("ipUSDM")
            .withAsset(address(amm.usdm.asset))
            .build();

        _ammStorageBuilder.withIporProtocolRouter(address(amm.router));
        _ammStorageBuilder.withAmmTreasury(address(amm.usdt.ammTreasury));
        amm.usdt.ammStorage = _ammStorageBuilder.build();

        _ammStorageBuilder.withAmmTreasury(address(amm.usdc.ammTreasury));
        amm.usdc.ammStorage = _ammStorageBuilder.build();

        _ammStorageBuilder.withAmmTreasury(address(amm.dai.ammTreasury));
        amm.dai.ammStorage = _ammStorageBuilder.build();

        _ammStorageBuilder.withAmmTreasury(address(amm.stEth.ammTreasury));
        amm.stEth.ammStorage = _ammStorageBuilder.build();

        _ammStorageBuilder.withAmmTreasury(address(amm.usdm.ammTreasury));
        amm.usdm.ammStorage = _ammStorageBuilder.build();

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
        amm.stEth.spreadRouter = amm.spreadRouter;
        amm.usdm.spreadRouter = amm.spreadRouter;

        _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(amm.usdt.asset))
            .withAmmTreasury(address(amm.usdt.ammTreasury))
            .withAssetManagementProxyAddress(address(amm.usdt.assetManagement))
            .upgrade();

        _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(amm.usdc.asset))
            .withAmmTreasury(address(amm.usdc.ammTreasury))
            .withAssetManagementProxyAddress(address(amm.usdc.assetManagement))
            .upgrade();

        _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(amm.dai.asset))
            .withAmmTreasury(address(amm.dai.ammTreasury))
            .withAssetManagementProxyAddress(address(amm.dai.assetManagement))
            .upgrade();

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

        amm.usdt.ipToken.setTokenManager(address(amm.router));
        amm.usdc.ipToken.setTokenManager(address(amm.router));
        amm.dai.ipToken.setTokenManager(address(amm.router));
        amm.stEth.ipToken.setTokenManager(address(amm.router));
        amm.usdm.ipToken.setTokenManager(address(amm.router));

        amm.usdt.ammTreasury.grantMaxAllowanceForSpender(address(amm.usdt.assetManagement));
        amm.usdc.ammTreasury.grantMaxAllowanceForSpender(address(amm.usdc.assetManagement));
        amm.dai.ammTreasury.grantMaxAllowanceForSpender(address(amm.dai.assetManagement));

        amm.usdt.ammTreasury.grantMaxAllowanceForSpender(address(amm.router));
        amm.usdc.ammTreasury.grantMaxAllowanceForSpender(address(amm.router));
        amm.dai.ammTreasury.grantMaxAllowanceForSpender(address(amm.router));
        //        amm.stEth.ammTreasury.grantMaxAllowanceForSpender(address(amm.router));

        IAmmGovernanceService(address(amm.router)).setAmmPoolsParams(address(amm.usdt.asset), 1000000000, 50, 8500);

        IAmmGovernanceService(address(amm.router)).setAmmPoolsParams(address(amm.usdc.asset), 1000000000, 50, 8500);

        IAmmGovernanceService(address(amm.router)).setAmmPoolsParams(address(amm.dai.asset), 1000000000, 50, 8500);

        IAmmGovernanceService(address(amm.router)).setAmmPoolsParams(address(amm.stEth.asset), 1000000000, 50, 8500);

        IAmmGovernanceService(address(amm.router)).setAmmPoolsParams(address(amm.usdm.asset), 1000000000, 50, 8500);

        vm.stopPrank();
    }

    function getUsdtInstance(
        IporProtocolConfig memory cfg
    ) public returns (BuilderUtils.IporProtocol memory iporProtocol) {
        iporProtocol.router = _iporProtocolRouterBuilder.buildEmptyProxy();
        iporProtocol.ammTreasury = _ammTreasuryBuilder.buildEmptyProxy();
        iporProtocol.assetManagement = _assetManagementBuilder.buildEmptyProxy();

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

        iporProtocol.ipToken = _ipTokenBuilder
            .withName("IP USDT")
            .withSymbol("ipUSDT")
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

        _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(iporProtocol.asset))
            .withAmmTreasury(address(iporProtocol.ammTreasury))
            .withAssetManagementProxyAddress(address(iporProtocol.assetManagement))
            .upgrade();

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
        iporProtocol.ammCloseSwapLens = IAmmCloseSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceUsdt = IAmmCloseSwapServiceUsdt(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceUsdc = IAmmCloseSwapServiceUsdc(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceDai = IAmmCloseSwapServiceDai(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));

        vm.startPrank(address(_owner));

        iporProtocol.ammTreasury.grantMaxAllowanceForSpender(address(iporProtocol.assetManagement));

        iporProtocol.ipToken.setTokenManager(address(iporProtocol.router));
        iporProtocol.ammTreasury.grantMaxAllowanceForSpender(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmPoolsParams(
            address(iporProtocol.asset),
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
        iporProtocol.assetManagement = _assetManagementBuilder.buildEmptyProxy();

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

        iporProtocol.ipToken = _ipTokenBuilder
            .withName("IP USDC")
            .withSymbol("ipUSDC")
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

        _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(iporProtocol.asset))
            .withAmmTreasury(address(iporProtocol.ammTreasury))
            .withAssetManagementProxyAddress(address(iporProtocol.assetManagement))
            .upgrade();

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
        iporProtocol.ammCloseSwapLens = IAmmCloseSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceUsdt = IAmmCloseSwapServiceUsdt(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceUsdc = IAmmCloseSwapServiceUsdc(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceDai = IAmmCloseSwapServiceDai(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));

        vm.startPrank(address(_owner));

        iporProtocol.ammTreasury.grantMaxAllowanceForSpender(address(iporProtocol.assetManagement));

        iporProtocol.ipToken.setTokenManager(address(iporProtocol.router));
        iporProtocol.ammTreasury.grantMaxAllowanceForSpender(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmPoolsParams(
            address(iporProtocol.asset),
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
        iporProtocol.assetManagement = _assetManagementBuilder.buildEmptyProxy();

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

        iporProtocol.ipToken = _ipTokenBuilder
            .withName("IP DAI")
            .withSymbol("ipDAI")
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
        _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(iporProtocol.asset))
            .withAmmTreasury(address(iporProtocol.ammTreasury))
            .withAssetManagementProxyAddress(address(iporProtocol.assetManagement))
            .upgrade();
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
        iporProtocol.ammCloseSwapLens = IAmmCloseSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceUsdt = IAmmCloseSwapServiceUsdt(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceUsdc = IAmmCloseSwapServiceUsdc(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceDai = IAmmCloseSwapServiceDai(address(iporProtocol.router));
        iporProtocol.ammGovernanceService = IAmmGovernanceService(address(iporProtocol.router));
        iporProtocol.ammGovernanceLens = IAmmGovernanceLens(address(iporProtocol.router));

        vm.startPrank(address(_owner));

        iporProtocol.ammTreasury.grantMaxAllowanceForSpender(address(iporProtocol.assetManagement));

        iporProtocol.ipToken.setTokenManager(address(iporProtocol.router));
        iporProtocol.ammTreasury.grantMaxAllowanceForSpender(address(iporProtocol.router));

        IAmmGovernanceService(address(iporProtocol.router)).setAmmPoolsParams(
            address(iporProtocol.asset),
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
                    spread: address(amm.spreadRouter)
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(amm.usdc.asset),
                    ammStorage: address(amm.usdc.ammStorage),
                    ammTreasury: address(amm.usdc.ammTreasury),
                    spread: address(amm.spreadRouter)
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(amm.dai.asset),
                    ammStorage: address(amm.dai.ammStorage),
                    ammTreasury: address(amm.dai.ammTreasury),
                    spread: address(amm.spreadRouter)
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(amm.stEth.asset),
                    ammStorage: address(amm.stEth.ammStorage),
                    ammTreasury: address(amm.stEth.ammTreasury),
                    spread: address(amm.spreadRouter)
                }),
                address(amm.iporOracle),
                messageSignerAddress
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
                iporOracleInput: address(amm.iporOracle),
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: address(amm.spreadRouter)
            })
        );

        deployerContracts.ammCloseSwapServiceUsdt = address(
            new AmmCloseSwapServiceUsdt({
                poolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(amm.usdt.asset),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage),
                    address(amm.usdt.assetManagement),
                    address(amm.usdt.spreadRouter)
                ),
                iporOracleInput: address(amm.iporOracle),
                messageSignerInput: messageSignerAddress
            })
        );

        deployerContracts.ammCloseSwapServiceUsdc = address(
            new AmmCloseSwapServiceUsdc({
                poolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(amm.usdc.asset),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage),
                    address(amm.usdc.assetManagement),
                    address(amm.usdc.spreadRouter)
                ),
                iporOracleInput: address(amm.iporOracle),
                messageSignerInput: messageSignerAddress
            })
        );

        deployerContracts.ammCloseSwapServiceDai = address(
            new AmmCloseSwapServiceDai({
                poolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(amm.dai.asset),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage),
                    address(amm.dai.assetManagement),
                    address(amm.dai.spreadRouter)
                ),
                iporOracleInput: address(amm.iporOracle),
                messageSignerInput: messageSignerAddress
            })
        );

        deployerContracts.ammCloseSwapLens = address(
            new AmmCloseSwapLens({
                usdtInput: address(amm.usdt.asset),
                usdcInput: address(amm.usdc.asset),
                daiInput: address(amm.dai.asset),
                stETHInput: _fakeContract,
                iporOracleInput: address(amm.iporOracle),
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: address(amm.spreadRouter),
                closeSwapServiceUsdtInput: deployerContracts.ammCloseSwapServiceUsdt,
                closeSwapServiceUsdcInput: deployerContracts.ammCloseSwapServiceUsdc,
                closeSwapServiceDaiInput: deployerContracts.ammCloseSwapServiceDai,
                closeSwapServiceStEthInput: _fakeContract
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
                iporOracleInput: address(amm.iporOracle)
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
                ),
                stEthPoolCfg: _preparePoolCfgForGovernanceService(
                    address(amm.stEth.asset),
                    address(amm.stEth.ammTreasury),
                    address(amm.stEth.ammStorage),
                    cfg.ammPoolsTreasury,
                    cfg.ammPoolsTreasuryManager,
                    cfg.ammCharlieTreasury,
                    cfg.ammCharlieTreasuryManager
                ),
                usdmPoolCfg: _preparePoolCfgForGovernanceService(
                    address(amm.usdm.asset),
                    address(amm.usdm.ammTreasury),
                    address(amm.usdm.ammStorage),
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
        //      todo fix addresses
        deployerContracts.ammPoolsLensStEth = _fakeContract;
        deployerContracts.ammPoolsServiceStEth = _fakeContract;
        deployerContracts.ammPoolsLensWusdm = _fakeContract;
        deployerContracts.ammPoolsServiceWusdm = _fakeContract;
        deployerContracts.ammOpenSwapServiceStEth = _fakeContract;
        deployerContracts.ammCloseSwapServiceStEth = _fakeContract;

        vm.startPrank(address(_owner));
        IporProtocolRouter(amm.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        amm.usdt.ammSwapsLens = IAmmSwapsLens(address(amm.router));
        amm.usdt.ammPoolsService = IAmmPoolsService(address(amm.router));
        amm.usdt.ammPoolsLens = IAmmPoolsLens(address(amm.router));
        amm.usdt.ammOpenSwapService = IAmmOpenSwapService(address(amm.router));
        amm.usdt.ammOpenSwapLens = IAmmOpenSwapLens(address(amm.router));
        amm.usdt.ammCloseSwapLens = IAmmCloseSwapLens(address(amm.router));
        amm.usdt.ammCloseSwapServiceUsdt = IAmmCloseSwapServiceUsdt(address(amm.router));
        amm.usdt.ammCloseSwapServiceUsdc = IAmmCloseSwapServiceUsdc(address(amm.router));
        amm.usdt.ammCloseSwapServiceDai = IAmmCloseSwapServiceDai(address(amm.router));
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
        amm.usdc.ammCloseSwapLens = IAmmCloseSwapLens(address(amm.router));
        amm.usdc.ammCloseSwapServiceUsdc = IAmmCloseSwapServiceUsdc(address(amm.router));
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
        amm.dai.ammCloseSwapLens = IAmmCloseSwapLens(address(amm.router));
        amm.dai.ammCloseSwapServiceDai = IAmmCloseSwapServiceDai(address(amm.router));
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
                    spread: address(iporProtocol.spreadRouter)
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    spread: _fakeContract
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    spread: _fakeContract
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    spread: _fakeContract
                }),
                address(iporProtocol.iporOracle),
                messageSignerAddress
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
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: address(iporProtocol.spreadRouter)
            })
        );

        deployerContracts.ammCloseSwapServiceUsdt = address(
            new AmmCloseSwapServiceUsdt({
                poolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement),
                    address(iporProtocol.spreadRouter)
                ),
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress
            })
        );

        deployerContracts.ammCloseSwapServiceUsdc = address(_fakeContract);
        deployerContracts.ammCloseSwapServiceDai = address(_fakeContract);

        deployerContracts.ammCloseSwapLens = address(
            new AmmCloseSwapLens({
                usdtInput: address(iporProtocol.asset),
                usdcInput: _fakeContract,
                daiInput: _fakeContract,
                stETHInput: _fakeContract,
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: address(iporProtocol.spreadRouter),
                closeSwapServiceUsdtInput: deployerContracts.ammCloseSwapServiceUsdt,
                closeSwapServiceUsdcInput: deployerContracts.ammCloseSwapServiceUsdc,
                closeSwapServiceDaiInput: deployerContracts.ammCloseSwapServiceDai,
                closeSwapServiceStEthInput: _fakeContract
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
                iporOracleInput: address(iporProtocol.iporOracle)
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
                daiPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                stEthPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                usdmPoolCfg: _prepareFakePoolCfgForGovernanceService()
            })
        );

        deployerContracts.powerTokenLens = address(_powerTokenLensBuilder.build());
        deployerContracts.liquidityMiningLens = address(_liquidityMiningLensBuilder.build());
        deployerContracts.flowService = address(_powerTokenFlowsServiceBuilder.build());
        deployerContracts.stakeService = address(_powerTokenStakeServiceBuilder.build());
        //        todo fix addresses
        deployerContracts.ammPoolsServiceStEth = _fakeContract;
        deployerContracts.ammPoolsLensStEth = _fakeContract;
        deployerContracts.ammOpenSwapServiceStEth = _fakeContract;
        deployerContracts.ammCloseSwapServiceStEth = _fakeContract;
        deployerContracts.ammPoolsServiceWusdm = _fakeContract;
        deployerContracts.ammPoolsLensWusdm = _fakeContract;


        vm.startPrank(address(_owner));
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapLens = IAmmCloseSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceUsdt = IAmmCloseSwapServiceUsdt(address(iporProtocol.router));
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
                    spread: _fakeContract
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(iporProtocol.asset),
                    ammStorage: address(iporProtocol.ammStorage),
                    ammTreasury: address(iporProtocol.ammTreasury),
                    spread: address(iporProtocol.spreadRouter)
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    spread: _fakeContract
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    spread: _fakeContract
                }),
                address(iporProtocol.iporOracle),
                messageSignerAddress
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
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: address(iporProtocol.spreadRouter)
            })
        );

        deployerContracts.ammCloseSwapServiceUsdc = address(
            new AmmCloseSwapServiceUsdc({
                poolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement),
                    address(iporProtocol.spreadRouter)
                ),
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress
            })
        );

        deployerContracts.ammCloseSwapServiceUsdt = address(_fakeContract);
        deployerContracts.ammCloseSwapServiceDai = address(_fakeContract);

        deployerContracts.ammCloseSwapLens = address(
            new AmmCloseSwapLens({
                usdtInput: _fakeContract,
                usdcInput: address(iporProtocol.asset),
                daiInput: _fakeContract,
                stETHInput: _fakeContract,
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: address(iporProtocol.spreadRouter),
                closeSwapServiceUsdtInput: deployerContracts.ammCloseSwapServiceUsdt,
                closeSwapServiceUsdcInput: deployerContracts.ammCloseSwapServiceUsdc,
                closeSwapServiceDaiInput: deployerContracts.ammCloseSwapServiceDai,
                closeSwapServiceStEthInput: _fakeContract
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
                iporOracleInput: address(iporProtocol.iporOracle)
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
                daiPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                stEthPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                usdmPoolCfg: _prepareFakePoolCfgForGovernanceService()
            })
        );

        deployerContracts.powerTokenLens = address(_powerTokenLensBuilder.build());
        deployerContracts.liquidityMiningLens = address(_liquidityMiningLensBuilder.build());
        deployerContracts.flowService = address(_powerTokenFlowsServiceBuilder.build());
        deployerContracts.stakeService = address(_powerTokenStakeServiceBuilder.build());

        //        todo fix addresses
        deployerContracts.ammPoolsLensStEth = _fakeContract;
        deployerContracts.ammPoolsServiceStEth = _fakeContract;
        deployerContracts.ammPoolsLensWusdm = _fakeContract;
        deployerContracts.ammPoolsServiceWusdm = _fakeContract;
        deployerContracts.ammOpenSwapServiceStEth = _fakeContract;
        deployerContracts.ammCloseSwapServiceStEth = _fakeContract;

        vm.startPrank(address(_owner));
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapLens = IAmmCloseSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceUsdc = IAmmCloseSwapServiceUsdc(address(iporProtocol.router));
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

        //todo Fix
        deployerContracts.ammPoolsLensStEth = address(123);
        deployerContracts.ammPoolsServiceStEth = address(123);
        deployerContracts.ammPoolsLensWusdm = address(123);
        deployerContracts.ammPoolsServiceWusdm = address(123);

        deployerContracts.ammSwapsLens = address(
            new AmmSwapsLens(
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    spread: _fakeContract
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    spread: _fakeContract
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: address(iporProtocol.asset),
                    ammStorage: address(iporProtocol.ammStorage),
                    ammTreasury: address(iporProtocol.ammTreasury),
                    spread: address(iporProtocol.spreadRouter)
                }),
                IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: _fakeContract,
                    ammStorage: _fakeContract,
                    ammTreasury: _fakeContract,
                    spread: _fakeContract
                }),
                address(iporProtocol.iporOracle),
                messageSignerAddress
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
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: address(iporProtocol.spreadRouter)
            })
        );
        deployerContracts.ammCloseSwapServiceDai = address(
            new AmmCloseSwapServiceDai({
                poolCfg: _preparePoolCfgForCloseSwapService(
                    cfg.closeSwapServiceTestCase,
                    address(iporProtocol.asset),
                    address(iporProtocol.ammTreasury),
                    address(iporProtocol.ammStorage),
                    address(iporProtocol.assetManagement),
                    address(iporProtocol.spreadRouter)
                ),
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress
            })
        );

        deployerContracts.ammCloseSwapServiceUsdt = address(_fakeContract);
        deployerContracts.ammCloseSwapServiceUsdc = address(_fakeContract);

        deployerContracts.ammCloseSwapLens = address(
            new AmmCloseSwapLens({
                usdtInput: _fakeContract,
                usdcInput: _fakeContract,
                daiInput: address(iporProtocol.asset),
                stETHInput: _fakeContract,
                iporOracleInput: address(iporProtocol.iporOracle),
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: address(iporProtocol.spreadRouter),
                closeSwapServiceUsdtInput: deployerContracts.ammCloseSwapServiceUsdt,
                closeSwapServiceUsdcInput: deployerContracts.ammCloseSwapServiceUsdc,
                closeSwapServiceDaiInput: deployerContracts.ammCloseSwapServiceDai,
                closeSwapServiceStEthInput: _fakeContract
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
                iporOracleInput: address(iporProtocol.iporOracle)
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
                ),
                stEthPoolCfg: _prepareFakePoolCfgForGovernanceService(),
                usdmPoolCfg: _prepareFakePoolCfgForGovernanceService()
            })
        );
        deployerContracts.powerTokenLens = address(_powerTokenLensBuilder.build());
        deployerContracts.liquidityMiningLens = address(_liquidityMiningLensBuilder.build());
        deployerContracts.flowService = address(_powerTokenFlowsServiceBuilder.build());
        deployerContracts.stakeService = address(_powerTokenStakeServiceBuilder.build());

        deployerContracts.ammPoolsLensStEth = address(_fakeContract);
        deployerContracts.ammPoolsServiceStEth = address(_fakeContract);
        deployerContracts.ammOpenSwapServiceStEth = address(_fakeContract);
        deployerContracts.ammCloseSwapServiceStEth = address(_fakeContract);

        vm.startPrank(address(_owner));

        address ammOpenSwapServiceStEth;
        address ammCloseSwapService;
        address ammPoolsService;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
        address ammPoolsServiceStEth;
        address ammPoolsLensStEth;
        IporProtocolRouter(iporProtocol.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
        vm.stopPrank();

        iporProtocol.ammSwapsLens = IAmmSwapsLens(address(iporProtocol.router));
        iporProtocol.ammPoolsService = IAmmPoolsService(address(iporProtocol.router));
        iporProtocol.ammPoolsLens = IAmmPoolsLens(address(iporProtocol.router));
        iporProtocol.ammOpenSwapService = IAmmOpenSwapService(address(iporProtocol.router));
        iporProtocol.ammOpenSwapLens = IAmmOpenSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapLens = IAmmCloseSwapLens(address(iporProtocol.router));
        iporProtocol.ammCloseSwapServiceDai = IAmmCloseSwapServiceDai(address(iporProtocol.router));
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
        returns (IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg)
    {
        poolCfg = IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
            asset: address(_fakeContract),
            decimals: 0,
            ammStorage: address(_fakeContract),
            ammTreasury: address(_fakeContract),
            assetManagement: address(_fakeContract),
            spread: address(_fakeContract),
            unwindingFeeRate: 0,
            unwindingFeeTreasuryPortionRate: 0,
            maxLengthOfLiquidatedSwapsPerLeg: 0,
            timeBeforeMaturityAllowedToCloseSwapByCommunity: 0,
            timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 0,
            timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 0,
            timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 0,
            minLiquidationThresholdToCloseBeforeMaturityByCommunity: 0,
            minLiquidationThresholdToCloseBeforeMaturityByBuyer: 0,
            minLeverage: 0,
            timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 0,
            timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 0,
            timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 0
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
        address assetManagement,
        address spreadRouter
    ) internal returns (IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg) {
        if (closeSwapServiceTestCase == BuilderUtils.AmmCloseSwapServiceTestCase.DEFAULT) {
            poolCfg = IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                asset: address(asset),
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                spread: spreadRouter,
                unwindingFeeRate: 5 * 1e14,
                unwindingFeeTreasuryPortionRate: 5 * 1e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 1 days
            });
        } else if (closeSwapServiceTestCase == BuilderUtils.AmmCloseSwapServiceTestCase.CASE1) {
            poolCfg = IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                asset: address(asset),
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                spread: spreadRouter,
                unwindingFeeRate: 99 * 1e16,
                unwindingFeeTreasuryPortionRate: 5 * 1e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 1 days
            });
        } else if (closeSwapServiceTestCase == BuilderUtils.AmmCloseSwapServiceTestCase.CASE2) {
            poolCfg = IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                asset: address(asset),
                decimals: IERC20MetadataUpgradeable(asset).decimals(),
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: assetManagement,
                spread: spreadRouter,
                unwindingFeeRate: 15 * 1e16,
                unwindingFeeTreasuryPortionRate: 5 * 1e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 1 days
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
