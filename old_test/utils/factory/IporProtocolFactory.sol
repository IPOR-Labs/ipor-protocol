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
import "../builder/AmmStorageBuilder.sol";
import "../builder/MockSpreadBuilder.sol";
import "../builder/AssetManagementBuilder.sol";
import "../builder/AmmTreasuryBuilder.sol";
import "../builder/JosephBuilder.sol";
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
        BuilderUtils.AmmTreasuryTestCase ammTreasuryUsdtTestCase;
        BuilderUtils.AmmTreasuryTestCase ammTreasuryUsdcTestCase;
        BuilderUtils.AmmTreasuryTestCase ammTreasuryDaiTestCase;
    }

    struct IporProtocolConfig {
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        BuilderUtils.AmmTreasuryTestCase ammTreasuryTestCase;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase iporRiskManagementOracleInitialParamsTestCase;
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
    MockSpreadBuilder internal _spreadBuilder;
    AssetManagementBuilder internal _assetManagementBuilder;
    AmmTreasuryBuilder internal _ammTreasuryBuilder;

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
        _ammStorageBuilder = new AmmStorageBuilder(owner);
        _spreadBuilder = new MockSpreadBuilder(owner);
        _assetManagementBuilder = new AssetManagementBuilder(owner);
        _ammTreasuryBuilder = new AmmTreasuryBuilder(owner);
        _josephBuilder = new JosephBuilder(owner);
        _owner = owner;
    }

    function getFullInstance(AmmConfig memory cfg) public returns (Amm memory amm) {
        _assetBuilder.withUSDT();
        _usdt = _assetBuilder.build();

        _assetBuilder.withUSDC();
        _usdc = _assetBuilder.build();

        _assetBuilder.withDAI();
        _dai = _assetBuilder.build();

        address[] memory assets = new address[](3);
        assets[0] = address(_dai);
        assets[1] = address(_usdt);
        assets[2] = address(_usdc);

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

        IpToken ipToken = _ipTokenBuilder.withName("IP USDT").withSymbol("ipUSDT").withAsset(address(_usdt)).build();

        IvToken ivToken = _ivTokenBuilder.withName("IV USDT").withSymbol("ivUSDT").withAsset(address(_usdt)).build();

        MockIporWeighted iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();

        AmmStorage ammStorage = _ammStorageBuilder.build();

        MockSpreadModel spreadModel = _spreadBuilder.build();

        ItfAssetManagement assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(_usdt))
            .withIvToken(address(ivToken))
            .build();

        ItfAmmTreasury ammTreasury = _ammTreasuryBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(_usdt))
            .withIporOracle(address(iporOracle))
            .withAmmStorage(address(ammStorage))
            .withAssetManagement(address(assetManagement))
            .withSpreadModel(address(spreadModel))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .withTestCase(cfg.ammTreasuryUsdtTestCase)
            .build();

        ItfJoseph joseph = _josephBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(_usdt))
            .withIpToken(address(ipToken))
            .withAmmStorage(address(ammStorage))
            .withAmmTreasury(address(ammTreasury))
            .withAssetManagement(address(assetManagement))
            .build();

        vm.startPrank(address(_owner));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        ivToken.setAssetManagement(address(assetManagement));
        ammStorage.setAmmTreasury(address(ammTreasury));
        assetManagement.setAmmTreasury(address(ammTreasury));
        ammTreasury.setupMaxAllowanceForAsset(address(assetManagement));

        ipToken.setJoseph(address(joseph));
        ammStorage.setJoseph(address(joseph));
        ammTreasury.setJoseph(address(joseph));
        ammTreasury.setupMaxAllowanceForAsset(address(joseph));

        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        amm.usdt = BuilderUtils.IporProtocol({
            asset: _usdt,
            ipToken: ipToken,
            ivToken: ivToken,
            iporOracle: iporOracle,
            iporRiskManagementOracle: iporRiskManagementOracle,
            iporWeighted: iporWeighted,
            ammStorage: ammStorage,
            spreadModel: spreadModel,
            assetManagement: assetManagement,
            ammTreasury: ammTreasury,
            joseph: joseph
        });

        ipToken = _ipTokenBuilder.withName("IP USDC").withSymbol("ipUSDC").withAsset(address(_usdc)).build();
        ivToken = _ivTokenBuilder.withName("IV USDC").withSymbol("ivUSDC").withAsset(address(_usdc)).build();
        iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
        ammStorage = _ammStorageBuilder.build();
        spreadModel = _spreadBuilder.build();

        assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(_usdc))
            .withIvToken(address(ivToken))
            .build();

        ammTreasury = _ammTreasuryBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(_usdc))
            .withIporOracle(address(iporOracle))
            .withAmmStorage(address(ammStorage))
            .withAssetManagement(address(assetManagement))
            .withSpreadModel(address(spreadModel))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .withTestCase(cfg.ammTreasuryUsdcTestCase)
            .build();

        joseph = _josephBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(_usdc))
            .withIpToken(address(ipToken))
            .withAmmStorage(address(ammStorage))
            .withAmmTreasury(address(ammTreasury))
            .withAssetManagement(address(assetManagement))
            .build();

        vm.startPrank(address(_owner));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        ivToken.setAssetManagement(address(assetManagement));
        ammStorage.setAmmTreasury(address(ammTreasury));
        assetManagement.setAmmTreasury(address(ammTreasury));
        ammTreasury.setupMaxAllowanceForAsset(address(assetManagement));

        ipToken.setJoseph(address(joseph));
        ammStorage.setJoseph(address(joseph));
        ammTreasury.setJoseph(address(joseph));
        ammTreasury.setupMaxAllowanceForAsset(address(joseph));

        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        amm.usdc = BuilderUtils.IporProtocol({
            asset: _usdc,
            ipToken: ipToken,
            ivToken: ivToken,
            iporOracle: iporOracle,
            iporRiskManagementOracle: iporRiskManagementOracle,
            iporWeighted: iporWeighted,
            ammStorage: ammStorage,
            spreadModel: spreadModel,
            assetManagement: assetManagement,
            ammTreasury: ammTreasury,
            joseph: joseph
        });

        ipToken = _ipTokenBuilder.withName("IP DAI").withSymbol("ipDAI").withAsset(address(_dai)).build();
        ivToken = _ivTokenBuilder.withName("IV DAI").withSymbol("ivDAI").withAsset(address(_dai)).build();
        iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();
        ammStorage = _ammStorageBuilder.build();
        spreadModel = _spreadBuilder.build();

        assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(_dai))
            .withIvToken(address(ivToken))
            .build();

        ammTreasury = _ammTreasuryBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(_dai))
            .withIporOracle(address(iporOracle))
            .withAmmStorage(address(ammStorage))
            .withAssetManagement(address(assetManagement))
            .withSpreadModel(address(spreadModel))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .withTestCase(cfg.ammTreasuryDaiTestCase)
            .build();

        joseph = _josephBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(_dai))
            .withIpToken(address(ipToken))
            .withAmmStorage(address(ammStorage))
            .withAmmTreasury(address(ammTreasury))
            .withAssetManagement(address(assetManagement))
            .build();

        vm.startPrank(address(_owner));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        ivToken.setAssetManagement(address(assetManagement));
        ammStorage.setAmmTreasury(address(ammTreasury));
        assetManagement.setAmmTreasury(address(ammTreasury));
        ammTreasury.setupMaxAllowanceForAsset(address(assetManagement));

        ipToken.setJoseph(address(joseph));
        ammStorage.setJoseph(address(joseph));
        ammTreasury.setJoseph(address(joseph));
        ammTreasury.setupMaxAllowanceForAsset(address(joseph));

        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        amm.dai = BuilderUtils.IporProtocol({
            asset: _dai,
            ipToken: ipToken,
            ivToken: ivToken,
            iporOracle: iporOracle,
            iporRiskManagementOracle: iporRiskManagementOracle,
            iporWeighted: iporWeighted,
            ammStorage: ammStorage,
            spreadModel: spreadModel,
            assetManagement: assetManagement,
            ammTreasury: ammTreasury,
            joseph: joseph
        });
    }

    function getDaiInstance(IporProtocolConfig memory cfg)
        public
        returns (BuilderUtils.IporProtocol memory iporProtocol)
    {
        _assetBuilder.withDAI();
        MockTestnetToken dai = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(dai);

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

        IpToken ipToken = _ipTokenBuilder.withName("IP DAI").withSymbol("ipDAI").withAsset(address(dai)).build();

        IvToken ivToken = _ivTokenBuilder.withName("IV DAI").withSymbol("ivDAI").withAsset(address(dai)).build();

        MockIporWeighted iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();

        AmmStorage ammStorage = _ammStorageBuilder.build();

        MockSpreadModel spreadModel = _spreadBuilder.withSpreadImplementation(cfg.spreadImplementation).build();

        ItfAssetManagement assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(dai))
            .withIvToken(address(ivToken))
            .withAssetManagementImplementation(cfg.assetManagementImplementation)
            .build();

        ItfAmmTreasury ammTreasury = _ammTreasuryBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(dai))
            .withIporOracle(address(iporOracle))
            .withAmmStorage(address(ammStorage))
            .withAssetManagement(address(assetManagement))
            .withSpreadModel(address(spreadModel))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .withTestCase(cfg.ammTreasuryTestCase)
            .build();

        ItfJoseph joseph = _josephBuilder
            .withAssetType(BuilderUtils.AssetType.DAI)
            .withAsset(address(dai))
            .withIpToken(address(ipToken))
            .withAmmStorage(address(ammStorage))
            .withAmmTreasury(address(ammTreasury))
            .withAssetManagement(address(assetManagement))
            .withJosephImplementation(cfg.josephImplementation)
            .build();

        vm.startPrank(address(_owner));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        ivToken.setAssetManagement(address(assetManagement));
        ammStorage.setAmmTreasury(address(ammTreasury));
        assetManagement.setAmmTreasury(address(ammTreasury));
        ammTreasury.setupMaxAllowanceForAsset(address(assetManagement));

        ipToken.setJoseph(address(joseph));
        ammStorage.setJoseph(address(joseph));
        ammTreasury.setJoseph(address(joseph));
        ammTreasury.setupMaxAllowanceForAsset(address(joseph));

        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        iporProtocol = BuilderUtils.IporProtocol({
            asset: dai,
            ipToken: ipToken,
            ivToken: ivToken,
            iporOracle: iporOracle,
            iporRiskManagementOracle: iporRiskManagementOracle,
            iporWeighted: iporWeighted,
            ammStorage: ammStorage,
            spreadModel: spreadModel,
            assetManagement: assetManagement,
            ammTreasury: ammTreasury,
            joseph: joseph
        });

        //setup
        setupUsers(cfg, iporProtocol);

        return iporProtocol;
    }

    function getUsdtInstance(IporProtocolConfig memory cfg)
        public
        returns (BuilderUtils.IporProtocol memory iporProtocol)
    {
        _assetBuilder.withUSDT();
        MockTestnetToken usdt = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(usdt);

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

        IpToken ipToken = _ipTokenBuilder.withName("IP USDT").withSymbol("ipUSDT").withAsset(address(usdt)).build();

        IvToken ivToken = _ivTokenBuilder.withName("IV USDT").withSymbol("ivUSDT").withAsset(address(usdt)).build();

        MockIporWeighted iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();

        AmmStorage ammStorage = _ammStorageBuilder.build();

        MockSpreadModel spreadModel = _spreadBuilder.withSpreadImplementation(cfg.spreadImplementation).build();

        ItfAssetManagement assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(usdt))
            .withIvToken(address(ivToken))
            .withAssetManagementImplementation(cfg.assetManagementImplementation)
            .build();

        ItfAmmTreasury ammTreasury = _ammTreasuryBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(usdt))
            .withIporOracle(address(iporOracle))
            .withAmmStorage(address(ammStorage))
            .withAssetManagement(address(assetManagement))
            .withSpreadModel(address(spreadModel))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .withTestCase(cfg.ammTreasuryTestCase)
            .build();

        ItfJoseph joseph = _josephBuilder
            .withAssetType(BuilderUtils.AssetType.USDT)
            .withAsset(address(usdt))
            .withIpToken(address(ipToken))
            .withAmmStorage(address(ammStorage))
            .withAmmTreasury(address(ammTreasury))
            .withAssetManagement(address(assetManagement))
            .withJosephImplementation(cfg.josephImplementation)
            .build();

        vm.startPrank(address(_owner));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        ivToken.setAssetManagement(address(assetManagement));
        ammStorage.setAmmTreasury(address(ammTreasury));
        assetManagement.setAmmTreasury(address(ammTreasury));
        ammTreasury.setupMaxAllowanceForAsset(address(assetManagement));

        ipToken.setJoseph(address(joseph));
        ammStorage.setJoseph(address(joseph));
        ammTreasury.setJoseph(address(joseph));
        ammTreasury.setupMaxAllowanceForAsset(address(joseph));

        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        iporProtocol = BuilderUtils.IporProtocol({
            asset: usdt,
            ipToken: ipToken,
            ivToken: ivToken,
            iporOracle: iporOracle,
            iporRiskManagementOracle: iporRiskManagementOracle,
            iporWeighted: iporWeighted,
            ammStorage: ammStorage,
            spreadModel: spreadModel,
            assetManagement: assetManagement,
            ammTreasury: ammTreasury,
            joseph: joseph
        });

        //setup
        setupUsers(cfg, iporProtocol);

        return iporProtocol;
    }

    function getUsdcInstance(IporProtocolConfig memory cfg)
        public
        returns (BuilderUtils.IporProtocol memory iporProtocol)
    {
        _assetBuilder.withUSDC();
        MockTestnetToken usdc = _assetBuilder.build();

        address[] memory assets = new address[](1);
        assets[0] = address(usdc);

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

        IpToken ipToken = _ipTokenBuilder.withName("IP USDC").withSymbol("ipUSDC").withAsset(address(usdc)).build();

        IvToken ivToken = _ivTokenBuilder.withName("IV USDC").withSymbol("ivUSDC").withAsset(address(usdc)).build();

        MockIporWeighted iporWeighted = _iporWeightedBuilder.withIporOracle(address(iporOracle)).build();

        AmmStorage ammStorage = _ammStorageBuilder.build();

        MockSpreadModel spreadModel = _spreadBuilder.withSpreadImplementation(cfg.spreadImplementation).build();

        ItfAssetManagement assetManagement = _assetManagementBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(usdc))
            .withIvToken(address(ivToken))
            .withAssetManagementImplementation(cfg.assetManagementImplementation)
            .build();

        ItfAmmTreasury ammTreasury = _ammTreasuryBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(usdc))
            .withIporOracle(address(iporOracle))
            .withAmmStorage(address(ammStorage))
            .withAssetManagement(address(assetManagement))
            .withSpreadModel(address(spreadModel))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .withTestCase(cfg.ammTreasuryTestCase)
            .build();

        ItfJoseph joseph = _josephBuilder
            .withAssetType(BuilderUtils.AssetType.USDC)
            .withAsset(address(usdc))
            .withIpToken(address(ipToken))
            .withAmmStorage(address(ammStorage))
            .withAmmTreasury(address(ammTreasury))
            .withAssetManagement(address(assetManagement))
            .withJosephImplementation(cfg.josephImplementation)
            .build();

        vm.startPrank(address(_owner));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));
        ivToken.setAssetManagement(address(assetManagement));
        ammStorage.setAmmTreasury(address(ammTreasury));
        assetManagement.setAmmTreasury(address(ammTreasury));
        ammTreasury.setupMaxAllowanceForAsset(address(assetManagement));

        ipToken.setJoseph(address(joseph));
        ammStorage.setJoseph(address(joseph));
        ammTreasury.setJoseph(address(joseph));
        ammTreasury.setupMaxAllowanceForAsset(address(joseph));

        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        iporProtocol = BuilderUtils.IporProtocol({
            asset: usdc,
            ipToken: ipToken,
            ivToken: ivToken,
            iporOracle: iporOracle,
            iporRiskManagementOracle: iporRiskManagementOracle,
            iporWeighted: iporWeighted,
            ammStorage: ammStorage,
            spreadModel: spreadModel,
            assetManagement: assetManagement,
            ammTreasury: ammTreasury,
            joseph: joseph
        });

        //setup
        setupUsers(cfg, iporProtocol);

        return iporProtocol;
    }

    function setupUsers(
        IporProtocolFactory.IporProtocolConfig memory cfg,
        BuilderUtils.IporProtocol memory iporProtocol
    ) public {
        if (iporProtocol.asset.decimals() == 18) {
            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                iporProtocol.asset.approve(address(iporProtocol.joseph), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
                iporProtocol.asset.approve(address(iporProtocol.ammTreasury), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
                vm.stopPrank();
                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_18DEC);
            }
        } else if (iporProtocol.asset.decimals() == 6) {
            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                iporProtocol.asset.approve(address(iporProtocol.joseph), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
                iporProtocol.asset.approve(address(iporProtocol.ammTreasury), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
                vm.stopPrank();
                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_6DEC);
            }
        } else {
            revert("Unsupported decimals");
        }
    }
}
