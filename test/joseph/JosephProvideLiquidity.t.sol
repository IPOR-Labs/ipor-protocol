// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonUsdc.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/itf/ItfJosephUsdt.sol";
import "../../contracts/itf/ItfJosephUsdc.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";

contract JosephProvideLiquidity is
    Test,
    TestCommons,
    DataUtils,
    IporOracleUtils,
    MiltonUtils,
    MiltonStorageUtils,
    JosephUtils,
    StanleyUtils
{
    MockSpreadModel internal _miltonSpreadModel;
    ItfIporOracle private _iporOracle;

    MockTestnetTokenUsdt private _usdt;
    IpToken private _ipTokenUsdt;
    ERC1967Proxy private _josephUsdtProxy;
    ERC1967Proxy private _miltonUsdtProxy;
    ERC1967Proxy private _miltonStorageUsdtProxy;
    ItfMiltonUsdt private _itfMiltonUsdt;
    ItfJosephUsdt private _itfJosephUsdt;
    MiltonStorage private _miltonStorageUsdt;
    MockCase0Stanley private _stanleyUsdt;

    MockTestnetTokenDai private _dai;
    IpToken private _ipTokenDai;
    ERC1967Proxy private _josephDaiProxy;
    ERC1967Proxy private _miltonDaiProxy;
    ERC1967Proxy private _miltonStorageDaiProxy;
    ItfMiltonDai private _itfMiltonDai;
    ItfJosephDai private _itfJosephDai;
    MiltonStorage private _miltonStorageDai;
    MockCase0Stanley private _stanleyDai;

    address internal _admin;
    address internal _userOne;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _usdt = getTokenUsdt();
        _dai = getTokenDai();

        _ipTokenUsdt = getIpTokenUsdt(address(_usdt));
        _ipTokenDai = getIpTokenDai(address(_dai));
        _miltonSpreadModel = prepareMockSpreadModel(0, 0, 0, 0);
        (_miltonStorageUsdtProxy, _miltonStorageUsdt) = getMiltonStorage();
        (_miltonStorageDaiProxy, _miltonStorageDai) = getMiltonStorage();

        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(_usdt);
        tokenAddresses[1] = address(_dai);

        _iporOracle = getIporOracleForManyAssets(_admin, _userOne, tokenAddresses, 1, 1, 1);
    }

    function testProvideLiquidityAndRebalanceUsdtCase01() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 210000 * 1e6;

        uint256 expectedMiltonBalance = 242000 * 1e6;
        uint256 expectedStanleyBalance = 968000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase02() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e6;

        uint256 expectedMiltonBalance = 230000 * 1e6;
        uint256 expectedStanleyBalance = 920000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase03() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 50000;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 50000 * 1e6;

        uint256 expectedMiltonBalance = 210000 * 1e6;
        uint256 expectedStanleyBalance = 840000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase04() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 850000 * 1e6;

        uint256 expectedMiltonBalance = 370000 * 1e6;
        uint256 expectedStanleyBalance = 1480000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase05() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e6;

        uint256 expectedMiltonBalance = 172500 * 1e6;
        uint256 expectedStanleyBalance = 977500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase06() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 210000 * 1e6;

        uint256 expectedMiltonBalance = 181500 * 1e6;
        uint256 expectedStanleyBalance = 1028500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase07() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 850000 * 1e6;

        uint256 expectedMiltonBalance = 277500 * 1e6;
        uint256 expectedStanleyBalance = 1572500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase08() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e6;

        uint256 expectedMiltonBalance = 287500 * 1e6;
        uint256 expectedStanleyBalance = 862500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase09() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 210000 * 1e6;

        uint256 expectedMiltonBalance = 302500 * 1e6;
        uint256 expectedStanleyBalance = 907500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase10() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 850000 * 1e6;

        uint256 expectedMiltonBalance = 462500 * 1e6;
        uint256 expectedStanleyBalance = 1387500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase11() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 50000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e6;

        uint256 expectedMiltonBalance = 57500 * 1e6;
        uint256 expectedStanleyBalance = 1092500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase12() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 950000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e6;

        uint256 expectedMiltonBalance = 350000 * 1e6;
        uint256 expectedStanleyBalance = 800000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase13() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 10000000000000000;
        uint256 miltonInitPool = 3000 * 1e6;
        uint256 stanleyInitBalance = 0;
        uint256 userInitBalance = 100000 * 1e6;

        uint256 expectedMiltonBalance = 1030 * 1e6;
        uint256 expectedStanleyBalance = 101970 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase01() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 210000 * 1e18;

        uint256 expectedMiltonBalance = 242000 * 1e18;
        uint256 expectedStanleyBalance = 968000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase02() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e18;

        uint256 expectedMiltonBalance = 230000 * 1e18;
        uint256 expectedStanleyBalance = 920000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase03() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 50000;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 50000 * 1e18;

        uint256 expectedMiltonBalance = 210000 * 1e18;
        uint256 expectedStanleyBalance = 840000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase04() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 850000 * 1e18;

        uint256 expectedMiltonBalance = 370000 * 1e18;
        uint256 expectedStanleyBalance = 1480000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase05() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e18;

        uint256 expectedMiltonBalance = 172500 * 1e18;
        uint256 expectedStanleyBalance = 977500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase06() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 210000 * 1e18;

        uint256 expectedMiltonBalance = 181500 * 1e18;
        uint256 expectedStanleyBalance = 1028500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase07() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 850000 * 1e18;

        uint256 expectedMiltonBalance = 277500 * 1e18;
        uint256 expectedStanleyBalance = 1572500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase08() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e18;

        uint256 expectedMiltonBalance = 287500 * 1e18;
        uint256 expectedStanleyBalance = 862500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase09() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 210000 * 1e18;

        uint256 expectedMiltonBalance = 302500 * 1e18;
        uint256 expectedStanleyBalance = 907500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase10() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 850000 * 1e18;

        uint256 expectedMiltonBalance = 462500 * 1e18;
        uint256 expectedStanleyBalance = 1387500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase11() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 50000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e18;

        uint256 expectedMiltonBalance = 57500 * 1e18;
        uint256 expectedStanleyBalance = 1092500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase12() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 950000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userInitBalance = 150000 * 1e18;

        uint256 expectedMiltonBalance = 350000 * 1e18;
        uint256 expectedStanleyBalance = 800000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase13() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100000;
        uint256 miltonStanleyRatio = 10000000000000000;
        uint256 miltonInitPool = 3000 * 1e18;
        uint256 stanleyInitBalance = 0;
        uint256 userInitBalance = 100000 * 1e18;

        uint256 expectedMiltonBalance = 1030 * 1e18;
        uint256 expectedStanleyBalance = 101970 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userInitBalance,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function _clearAndSetupSmartContractsUsdt() private {
        _stanleyUsdt = getMockCase0Stanley(address(_usdt));

        (_miltonUsdtProxy, _itfMiltonUsdt) = getItfMiltonUsdt(
            address(_usdt),
            address(_iporOracle),
            address(_miltonStorageUsdtProxy),
            address(_miltonSpreadModel),
            address(_stanleyUsdt)
        );

        (_josephUsdtProxy, _itfJosephUsdt) = getItfJosephUsdt(
            address(_usdt),
            address(_ipTokenUsdt),
            address(_miltonUsdtProxy),
            address(_miltonStorageUsdtProxy),
            address(_stanleyUsdt)
        );

        prepareItfMiltonUsdt(_itfMiltonUsdt, address(_josephUsdtProxy), address(_stanleyUsdt));

        _ipTokenUsdt.setJoseph(address(_josephUsdtProxy));
        _miltonStorageUsdt.setMilton(address(_miltonUsdtProxy));
        _itfJosephUsdt.setMaxLpAccountContribution(1000000);
    }

    function _clearAndSetupSmartContractsDai() private {
        _stanleyDai = getMockCase0Stanley(address(_dai));

        (_miltonDaiProxy, _itfMiltonDai) = getItfMiltonDai(
            address(_dai),
            address(_iporOracle),
            address(_miltonStorageDaiProxy),
            address(_miltonSpreadModel),
            address(_stanleyDai)
        );

        (_josephDaiProxy, _itfJosephDai) = getItfJosephDai(
            address(_dai),
            address(_ipTokenDai),
            address(_miltonDaiProxy),
            address(_miltonStorageDaiProxy),
            address(_stanleyDai)
        );

        prepareItfMiltonDai(_itfMiltonDai, address(_josephDaiProxy), address(_stanleyDai));

        _ipTokenDai.setJoseph(address(_josephDaiProxy));
        _miltonStorageDai.setMilton(address(_miltonDaiProxy));
        _itfJosephDai.setMaxLpAccountContribution(1000000);
    }

    function _executeProvideLiquidityUsdt(
        uint256 autoRebalanceThreshold,
        uint256 miltonStanleyRatio,
        uint256 miltonInitPool,
        uint256 stanleyInitBalance,
        uint256 userInitBalance,
        uint256 expectedStanleyBalance,
        uint256 expectedMiltonBalance
    ) internal {
        _itfJosephUsdt.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _itfJosephUsdt.setMiltonStanleyBalanceRatio(miltonStanleyRatio);
        deal(address(_usdt), address(_itfMiltonUsdt), miltonInitPool);

        vm.startPrank(address(_itfMiltonUsdt));
        _stanleyUsdt.deposit(stanleyInitBalance);
        vm.stopPrank();

        deal(address(_usdt), address(_userOne), userInitBalance);

        vm.startPrank(address(_userOne));
        _usdt.approve(address(_itfJosephUsdt), userInitBalance);

        //when
        _itfJosephUsdt.provideLiquidity(userInitBalance);

        //then
        vm.stopPrank();

        assertEq(_stanleyUsdt.totalBalance(address(_itfMiltonUsdt)), expectedStanleyBalance);
        assertEq(_usdt.balanceOf(address(_itfMiltonUsdt)), expectedMiltonBalance);
    }

    function _executeProvideLiquidityDai(
        uint256 autoRebalanceThreshold,
        uint256 miltonStanleyRatio,
        uint256 miltonInitPool,
        uint256 stanleyInitBalance,
        uint256 userInitBalance,
        uint256 expectedStanleyBalance,
        uint256 expectedMiltonBalance
    ) internal {
        _itfJosephDai.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _itfJosephDai.setMiltonStanleyBalanceRatio(miltonStanleyRatio);
        deal(address(_dai), address(_itfMiltonDai), miltonInitPool);

        vm.startPrank(address(_itfMiltonDai));
        _stanleyDai.deposit(stanleyInitBalance);
        vm.stopPrank();

        deal(address(_dai), address(_userOne), userInitBalance);

        vm.startPrank(address(_userOne));
        _dai.approve(address(_itfJosephDai), userInitBalance);

        //when
        _itfJosephDai.provideLiquidity(userInitBalance);

        //then
        vm.stopPrank();

        assertEq(_stanleyDai.totalBalance(address(_itfMiltonDai)), expectedStanleyBalance);
        assertEq(_dai.balanceOf(address(_itfMiltonDai)), expectedMiltonBalance);
    }
}
