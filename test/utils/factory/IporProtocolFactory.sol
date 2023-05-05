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
    struct TestCaseConfig {
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

    function getDaiInstance(TestCaseConfig memory cfg)
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
                TestConstants.USER_SUPPLY_6_DECIMALS
            );
        }

        return iporProtocol;
    }

    function getUsdcInstance(TestCaseConfig memory cfg)
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
                TestConstants.USER_SUPPLY_6_DECIMALS
            );
        }

        return iporProtocol;
    }
}
