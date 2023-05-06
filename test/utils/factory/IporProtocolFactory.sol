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
import "forge-std/Test.sol";

contract IporProtocolFactory is Test {
    struct Amm {
        ItfIporOracle iporOracle;
        IporProtocolBuilder.IporProtocol usdt;
        IporProtocolBuilder.IporProtocol usdc;
        IporProtocolBuilder.IporProtocol dai;
    }

    struct AmmConfig {
        address iporOracleUpdater;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        address miltonUsdtImplementation;
        address miltonUsdcImplementation;
        address miltonDaiImplementation;
    }

    struct IporProtocolConfig {
        address iporOracleUpdater;
        BuilderUtils.IporOracleInitialParamsTestCase iporOracleInitialParamsTestCase;
        address[] approvalsForUsers;
        address miltonImplementation;
        address josephImplementation;
        address spreadImplementation;
        address stanleyImplementation;
    }

    IporProtocolBuilder internal iporProtocolBuilder;
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
        iporProtocolBuilder = new IporProtocolBuilder(owner);
        assetBuilder = new AssetBuilder(owner, iporProtocolBuilder);
        ipTokenBuilder = new IpTokenBuilder(owner, iporProtocolBuilder);
        iporOracleBuilder = new IporOracleBuilder(owner, iporProtocolBuilder);
        iporWeightedBuilder = new IporWeightedBuilder(owner, iporProtocolBuilder);
        miltonStorageBuilder = new MiltonStorageBuilder(owner, iporProtocolBuilder);
        ivTokenBuilder = new IvTokenBuilder(owner, iporProtocolBuilder);
        stanleyBuilder = new StanleyBuilder(owner, iporProtocolBuilder);
        miltonBuilder = new MiltonBuilder(owner, iporProtocolBuilder);
        josephBuilder = new JosephBuilder(owner, iporProtocolBuilder);
        mockSpreadBuilder = new MockSpreadBuilder(owner, iporProtocolBuilder);
        _owner = owner;
    }

    function getFullInstance(AmmConfig memory cfg) public returns (Amm memory amm) {
        assetBuilder.withUSDT();
        MockTestnetToken usdt = assetBuilder.build();

        assetBuilder.withUSDC();
        MockTestnetToken usdc = assetBuilder.build();

        assetBuilder.withDAI();
        MockTestnetToken dai = assetBuilder.build();

        address[] memory assets = new address[](3);
        assets[0] = address(dai);
        assets[1] = address(usdt);
        assets[2] = address(usdc);

        iporOracleBuilder.withAssets(assets);
        iporOracleBuilder.withInitialParamsTestCase(cfg.iporOracleInitialParamsTestCase);

        ItfIporOracle iporOracle = iporOracleBuilder.build();

        vm.prank(address(_owner));
        iporOracle.addUpdater(cfg.iporOracleUpdater);

        amm.iporOracle = iporOracle;

        amm.usdt = iporProtocolBuilder
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
            .milton()
            .withMiltonImplementation(cfg.miltonUsdtImplementation)
            .and()
            .build();

        amm.usdc = iporProtocolBuilder
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
            .milton()
            .withMiltonImplementation(cfg.miltonUsdcImplementation)
            .and()
            .build();

        amm.dai = iporProtocolBuilder
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
            .milton()
            .withMiltonImplementation(cfg.miltonDaiImplementation)
            .and()
            .build();
    }

    function getDaiInstance(IporProtocolConfig memory cfg)
        public
        returns (IporProtocolBuilder.IporProtocol memory iporProtocol)
    {
        iporProtocol = iporProtocolBuilder
            .daiBuilder()
            .ipToken()
            .withName("IP DAI")
            .withSymbol("ipDAI")
            .and()
            .ivToken()
            .withName("IV DAI")
            .withSymbol("ivDAI")
            .and()
            .iporOracle()
            .withInitialParamsTestCase(cfg.iporOracleInitialParamsTestCase)
            .and()
            .spread()
            .withSpreadImplementation(cfg.spreadImplementation)
            .and()
            .milton()
            .withMiltonImplementation(cfg.miltonImplementation)
            .and()
            .joseph()
            .withJosephImplementation(cfg.josephImplementation)
            .and()
            .stanley()
            .withStanleyImplementation(cfg.stanleyImplementation)
            .and()
            .build();

        //setup
        vm.prank(address(_owner));
        iporProtocol.iporOracle.addUpdater(cfg.iporOracleUpdater);

        setupUsers(cfg, iporProtocol);

        return iporProtocol;
    }

    function getUsdtInstance(IporProtocolConfig memory cfg)
        public
        returns (IporProtocolBuilder.IporProtocol memory iporProtocol)
    {
        iporProtocol = iporProtocolBuilder
            .usdtBuilder()
            .ipToken()
            .withName("IP USDT")
            .withSymbol("ipUSDT")
            .and()
            .ivToken()
            .withName("IV USDT")
            .withSymbol("ivUSDT")
            .and()
            .iporOracle()
            .withInitialParamsTestCase(cfg.iporOracleInitialParamsTestCase)
            .and()
            .spread()
            .withSpreadImplementation(cfg.spreadImplementation)
            .and()
            .milton()
            .withMiltonImplementation(cfg.miltonImplementation)
            .and()
            .joseph()
            .withJosephImplementation(cfg.josephImplementation)
            .and()
            .stanley()
            .withStanleyImplementation(cfg.stanleyImplementation)
            .and()
            .build();

        //setup
        vm.prank(address(_owner));
        iporProtocol.iporOracle.addUpdater(cfg.iporOracleUpdater);

        setupUsers(cfg, iporProtocol);

        return iporProtocol;
    }

    function getUsdcInstance(IporProtocolConfig memory cfg)
        public
        returns (IporProtocolBuilder.IporProtocol memory iporProtocol)
    {
        iporProtocol = iporProtocolBuilder
            .usdcBuilder()
            .ipToken()
            .withName("IP USDC")
            .withSymbol("ipUSDC")
            .and()
            .ivToken()
            .withName("IV USDC")
            .withSymbol("ivUSDC")
            .and()
            .iporOracle()
            .withInitialParamsTestCase(cfg.iporOracleInitialParamsTestCase)
            .and()
            .spread()
            .withSpreadImplementation(cfg.spreadImplementation)
            .and()
            .milton()
            .withMiltonImplementation(cfg.miltonImplementation)
            .and()
            .joseph()
            .withJosephImplementation(cfg.josephImplementation)
            .and()
            .stanley()
            .withStanleyImplementation(cfg.stanleyImplementation)
            .and()
            .build();

        //setup
        vm.prank(address(_owner));
        iporProtocol.iporOracle.addUpdater(cfg.iporOracleUpdater);

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
        } else if (iporProtocol.asset.decimals() == 6) {
            for (uint256 i = 0; i < cfg.approvalsForUsers.length; ++i) {
                vm.startPrank(cfg.approvalsForUsers[i]);
                iporProtocol.asset.approve(
                    address(iporProtocol.joseph),
                    TestConstants.TOTAL_SUPPLY_6_DECIMALS
                );
                iporProtocol.asset.approve(
                    address(iporProtocol.milton),
                    TestConstants.TOTAL_SUPPLY_6_DECIMALS
                );
                vm.stopPrank();
                deal(
                    address(iporProtocol.asset),
                    cfg.approvalsForUsers[i],
                    TestConstants.USER_SUPPLY_10MLN_6DEC
                );
            }
        } else {
            revert("Unsupported decimals");
        }
    }
}
