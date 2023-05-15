// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
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
import "../builder/IporProtocolBuilder.sol";
import "./IporOracleFactory.sol";
import "./IporRiskManagementOracleFactory.sol";

contract IporProtocolFactory is Test {
    struct Amm {
        ItfIporOracle iporOracle;
        IporRiskManagementOracle iporRiskManagementOracle;
        IporProtocolBuilder.IporProtocol usdt;
        IporProtocolBuilder.IporProtocol usdc;
        IporProtocolBuilder.IporProtocol dai;
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
    IporProtocolBuilder internal _iporProtocolBuilder;
    AssetBuilder internal _assetBuilder;
    IpTokenBuilder internal _ipTokenBuilder;
    IporWeightedBuilder internal _iporWeightedBuilder;
    MiltonStorageBuilder internal _miltonStorageBuilder;
    IvTokenBuilder internal _ivTokenBuilder;
    StanleyBuilder internal _stanleyBuilder;
    MiltonBuilder internal _miltonBuilder;
    JosephBuilder internal _josephBuilder;
    MockSpreadBuilder internal _mockSpreadBuilder;

    address internal _owner;

    constructor(address owner) {
        _iporOracleFactory = new IporOracleFactory(owner);
        _iporRiskManagementOracleFactory = new IporRiskManagementOracleFactory(owner);
        _iporProtocolBuilder = new IporProtocolBuilder(owner);
        _assetBuilder = new AssetBuilder(owner, _iporProtocolBuilder);
        _ipTokenBuilder = new IpTokenBuilder(owner, _iporProtocolBuilder);
        _iporWeightedBuilder = new IporWeightedBuilder(owner, _iporProtocolBuilder);
        _miltonStorageBuilder = new MiltonStorageBuilder(owner, _iporProtocolBuilder);
        _ivTokenBuilder = new IvTokenBuilder(owner, _iporProtocolBuilder);
        _stanleyBuilder = new StanleyBuilder(owner, _iporProtocolBuilder);
        _miltonBuilder = new MiltonBuilder(owner, _iporProtocolBuilder);
        _josephBuilder = new JosephBuilder(owner, _iporProtocolBuilder);
        _mockSpreadBuilder = new MockSpreadBuilder(owner, _iporProtocolBuilder);
        _owner = owner;
    }

    function getFullInstance(AmmConfig memory cfg) public returns (Amm memory amm) {
        _assetBuilder.withUSDT();
        MockTestnetToken usdt = _assetBuilder.build();

        _assetBuilder.withUSDC();
        MockTestnetToken usdc = _assetBuilder.build();

        _assetBuilder.withDAI();
        MockTestnetToken dai = _assetBuilder.build();

        address[] memory assets = new address[](3);
        assets[0] = address(dai);
        assets[1] = address(usdt);
        assets[2] = address(usdc);

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

        amm.usdt = _iporProtocolBuilder
            .usdtBuilder()
            .withAsset(address(usdt))
            .ipToken()
            .withName("IP USDT")
            .withSymbol("ipUSDT")
            .and()
            .ivToken()
            .withName("IV USDT")
            .withSymbol("ivUSDT")
            .and()
            .withIporOracle(address(iporOracle))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .milton()
            .withTestCase(cfg.miltonUsdtTestCase)
            .and()
            .build();

        amm.usdc = _iporProtocolBuilder
            .usdcBuilder()
            .withAsset(address(usdc))
            .ipToken()
            .withName("IP USDC")
            .withSymbol("ipUSDC")
            .and()
            .ivToken()
            .withName("IV USDC")
            .withSymbol("ivUSDC")
            .and()
            .withIporOracle(address(iporOracle))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .milton()
            .withTestCase(cfg.miltonUsdcTestCase)
            .and()
            .build();

        amm.dai = _iporProtocolBuilder
            .daiBuilder()
            .withAsset(address(dai))
            .ipToken()
            .withName("IP DAI")
            .withSymbol("ipDAI")
            .and()
            .ivToken()
            .withName("IV DAI")
            .withSymbol("ivDAI")
            .and()
            .withIporOracle(address(iporOracle))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .milton()
            .withTestCase(cfg.miltonDaiTestCase)
            .and()
            .build();
    }

    function getDaiInstance(IporProtocolConfig memory cfg)
        public
        returns (IporProtocolBuilder.IporProtocol memory iporProtocol)
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

        iporProtocol = _iporProtocolBuilder
            .daiBuilder()
            .withAsset(address(dai))
            .ipToken()
            .withName("IP DAI")
            .withSymbol("ipDAI")
            .and()
            .ivToken()
            .withName("IV DAI")
            .withSymbol("ivDAI")
            .and()
            .withIporOracle(address(iporOracle))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .and()
            .spread()
            .withSpreadImplementation(cfg.spreadImplementation)
            .and()
            .joseph()
            .withJosephImplementation(cfg.josephImplementation)
            .and()
            .stanley()
            .withStanleyImplementation(cfg.stanleyImplementation)
            .and()
            .milton()
            .withTestCase(cfg.miltonTestCase)
            .and()
            .build();

        //setup
        setupUsers(cfg, iporProtocol);

        return iporProtocol;
    }

        function getUsdtInstance(IporProtocolConfig memory cfg)
        public
        returns (IporProtocolBuilder.IporProtocol memory iporProtocol)
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

        iporProtocol = _iporProtocolBuilder
            .usdtBuilder()
            .withAsset(address(usdt))
            .ipToken()
            .withName("IP USDT")
            .withSymbol("ipUSDT")
            .and()
            .ivToken()
            .withName("IV USDT")
            .withSymbol("ivUSDT")
            .and()
            .withIporOracle(address(iporOracle))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .and()
            .spread()
            .withSpreadImplementation(cfg.spreadImplementation)
            .and()
            .milton()
            .withTestCase(cfg.miltonTestCase)
            .and()
            .joseph()
            .withJosephImplementation(cfg.josephImplementation)
            .and()
            .stanley()
            .withStanleyImplementation(cfg.stanleyImplementation)
            .and()
            .build();

        //setup
        setupUsers(cfg, iporProtocol);

        return iporProtocol;
    }

    function getUsdcInstance(IporProtocolConfig memory cfg)
        public
        returns (IporProtocolBuilder.IporProtocol memory iporProtocol)
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

        iporProtocol = _iporProtocolBuilder
            .usdcBuilder()
            .withAsset(address(usdc))
            .ipToken()
            .withName("IP USDC")
            .withSymbol("ipUSDC")
            .and()
            .ivToken()
            .withName("IV USDC")
            .withSymbol("ivUSDC")
            .and()
            .withIporOracle(address(iporOracle))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .and()
            .spread()
            .withSpreadImplementation(cfg.spreadImplementation)
            .and()
            .milton()
            .withTestCase(cfg.miltonTestCase)
            .and()
            .joseph()
            .withJosephImplementation(cfg.josephImplementation)
            .and()
            .stanley()
            .withStanleyImplementation(cfg.stanleyImplementation)
            .and()
            .build();

        //setup
        setupUsers(cfg, iporProtocol);

        return iporProtocol;
    }

    function setupUsers(
        IporProtocolFactory.IporProtocolConfig memory cfg,
        IporProtocolBuilder.IporProtocol memory iporProtocol
    ) public {
        if (iporProtocol.asset.decimals() == 18) {
            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                iporProtocol.asset.approve(address(iporProtocol.joseph), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
                iporProtocol.asset.approve(address(iporProtocol.milton), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
                vm.stopPrank();
                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_18DEC);
            }
        } else if (iporProtocol.asset.decimals() == 6) {
            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                iporProtocol.asset.approve(address(iporProtocol.joseph), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
                iporProtocol.asset.approve(address(iporProtocol.milton), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
                vm.stopPrank();
                deal(address(iporProtocol.asset), cfg.approvalsForUsers[i], TestConstants.USER_SUPPLY_10MLN_6DEC);
            }
        } else {
            revert("Unsupported decimals");
        }
    }
}
