// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../../contracts/libraries/math/IporMath.sol";
import "../../contracts/libraries/Constants.sol";
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

contract JosephProvideLiquidity is Test, TestCommons, DataUtils {
    MockSpreadModel internal _miltonSpreadModel;
    ItfIporOracle private _iporOracle;

    MockTestnetTokenUsdt private _usdt;
    IpToken private _ipTokenUsdt;

    ItfMiltonUsdt private _itfMiltonUsdt;
    ItfJosephUsdt private _itfJosephUsdt;
    MiltonStorage private _miltonStorageUsdt;
    MockCase0Stanley private _stanleyUsdt;

    MockTestnetTokenDai private _dai;
    IpToken private _ipTokenDai;
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

        _miltonSpreadModel = prepareMockSpreadModel(0, 0, 0, 0);

        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(_usdt);
        tokenAddresses[1] = address(_dai);

        _iporOracle = getIporOracleForManyAssets(_admin, _userOne, tokenAddresses, 1, 1, 1);
    }

    function testProvideLiquidityAndRebalanceUsdtCase01() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 242000 * 1e6;
        uint256 expectedStanleyBalance = 968000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase02() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 230000 * 1e6;
        uint256 expectedStanleyBalance = 920000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase03() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 50;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e6;

        uint256 expectedMiltonBalance = 210000 * 1e6;
        uint256 expectedStanleyBalance = 840000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase04() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedMiltonBalance = 370000 * 1e6;
        uint256 expectedStanleyBalance = 1480000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase05() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 172500 * 1e6;
        uint256 expectedStanleyBalance = 977500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase06() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 181500 * 1e6;
        uint256 expectedStanleyBalance = 1028500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase07() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedMiltonBalance = 277500 * 1e6;
        uint256 expectedStanleyBalance = 1572500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase08() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 287500 * 1e6;
        uint256 expectedStanleyBalance = 862500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase09() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 302500 * 1e6;
        uint256 expectedStanleyBalance = 907500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase10() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedMiltonBalance = 462500 * 1e6;
        uint256 expectedStanleyBalance = 1387500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase11() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 50000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 57500 * 1e6;
        uint256 expectedStanleyBalance = 1092500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase12() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 950000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 350000 * 1e6;
        uint256 expectedStanleyBalance = 800000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase13() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 10000000000000000;
        uint256 miltonInitPool = 3000 * 1e6;
        uint256 stanleyInitBalance = 0;
        uint256 userPosition = 100000 * 1e6;

        uint256 expectedMiltonBalance = 1030 * 1e6;
        uint256 expectedStanleyBalance = 101970 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase01() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedMiltonBalance = 242000 * 1e18;
        uint256 expectedStanleyBalance = 968000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase02() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 230000 * 1e18;
        uint256 expectedStanleyBalance = 920000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase03() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 50;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e18;

        uint256 expectedMiltonBalance = 210000 * 1e18;
        uint256 expectedStanleyBalance = 840000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase04() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedMiltonBalance = 370000 * 1e18;
        uint256 expectedStanleyBalance = 1480000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase05() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 172500 * 1e18;
        uint256 expectedStanleyBalance = 977500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase06() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedMiltonBalance = 181500 * 1e18;
        uint256 expectedStanleyBalance = 1028500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase07() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedMiltonBalance = 277500 * 1e18;
        uint256 expectedStanleyBalance = 1572500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase08() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 287500 * 1e18;
        uint256 expectedStanleyBalance = 862500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase09() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedMiltonBalance = 302500 * 1e18;
        uint256 expectedStanleyBalance = 907500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase10() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedMiltonBalance = 462500 * 1e18;
        uint256 expectedStanleyBalance = 1387500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase11() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 50000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 57500 * 1e18;
        uint256 expectedStanleyBalance = 1092500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase12() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 950000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 350000 * 1e18;
        uint256 expectedStanleyBalance = 800000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase13() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 10000000000000000;
        uint256 miltonInitPool = 3000 * 1e18;
        uint256 stanleyInitBalance = 0;
        uint256 userPosition = 100000 * 1e18;

        uint256 expectedMiltonBalance = 1030 * 1e18;
        uint256 expectedStanleyBalance = 101970 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase01() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 158210 * 1e6;
        uint256 expectedStanleyBalance = 632840 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase02() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 170150 * 1e6;
        uint256 expectedStanleyBalance = 680600 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase03() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 40;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e6;

        uint256 expectedMiltonBalance = 190050 * 1e6;
        uint256 expectedStanleyBalance = 760200 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase04() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedMiltonBalance = 30850 * 1e6;
        uint256 expectedStanleyBalance = 123400 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase05() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 1276125 * 1e5;
        uint256 expectedStanleyBalance = 7231375 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase06() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 1186575 * 1e5;
        uint256 expectedStanleyBalance = 6723925 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase07() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedMiltonBalance = 231375 * 1e5;
        uint256 expectedStanleyBalance = 1311125 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase08() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 2126875 * 1e5;
        uint256 expectedStanleyBalance = 6380625 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase09() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 1977625 * 1e5;
        uint256 expectedStanleyBalance = 5932875 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase10() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedMiltonBalance = 385625 * 1e5;
        uint256 expectedStanleyBalance = 1156875 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndNoRebalanceUsdtCase11() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 50000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        // will stay because treshold is not achieved and Milton has cash for redeem
        uint256 redeemFee = 750 * 1e6;
        uint256 expectedMiltonBalance = 50000 * 1e6 + redeemFee;
        uint256 expectedStanleyBalance = stanleyInitBalance;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase12() public {
        //given
        _clearAndSetupSmartContractsUsdt();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 950000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 8082125 * 1e5;
        uint256 expectedStanleyBalance = 425375 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase01() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedMiltonBalance = 158210 * 1e18;
        uint256 expectedStanleyBalance = 632840 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase02() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 170150 * 1e18;
        uint256 expectedStanleyBalance = 680600 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase03() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 40;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e18;

        uint256 expectedMiltonBalance = 190050 * 1e18;
        uint256 expectedStanleyBalance = 760200 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase04() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedMiltonBalance = 30850 * 1e18;
        uint256 expectedStanleyBalance = 123400 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase05() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 1276125 * 1e17;
        uint256 expectedStanleyBalance = 7231375 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase06() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedMiltonBalance = 1186575 * 1e17;
        uint256 expectedStanleyBalance = 6723925 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase07() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedMiltonBalance = 231375 * 1e17;
        uint256 expectedStanleyBalance = 1311125 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase08() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 2126875 * 1e17;
        uint256 expectedStanleyBalance = 6380625 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase09() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedMiltonBalance = 1977625 * 1e17;
        uint256 expectedStanleyBalance = 5932875 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase10() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 250000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedMiltonBalance = 385625 * 1e17;
        uint256 expectedStanleyBalance = 1156875 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndNoRebalanceDaiCase11() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 50000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        // will stay because treshold is not achieved and Milton has cash for redeem
        uint256 redeemFee = 750 * 1e18;
        uint256 expectedMiltonBalance = 50000 * 1e18 + redeemFee;
        uint256 expectedStanleyBalance = stanleyInitBalance;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCase12() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 950000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedMiltonBalance = 8082125 * 1e17;
        uint256 expectedStanleyBalance = 425375 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndRebalanceDaiCaseBigValues() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 10000;
        uint256 miltonStanleyRatio = 150000000000000000;
        uint256 miltonInitPool = 1000000000 * 1e18;
        uint256 stanleyInitBalance = 800000000 * 1e18;
        uint256 userPosition = 150000000 * 1e18;

        uint256 expectedMiltonBalance = 1276125000 * 1e17;
        uint256 expectedStanleyBalance = 7231375000 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function testRedeemAndNoRebalanceDaiCaseBelowTresholdBecauseOfFee() public {
        //given
        _clearAndSetupSmartContractsDai();

        uint256 autoRebalanceThreshold = 50;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e18;

        uint256 expectedMiltonBalance = 150250 * 1e18;
        uint256 expectedStanleyBalance = 800000 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            miltonStanleyRatio,
            miltonInitPool,
            stanleyInitBalance,
            userPosition,
            expectedStanleyBalance,
            expectedMiltonBalance
        );
    }

    function _clearAndSetupSmartContractsUsdt() private {
        _miltonStorageUsdt = getMiltonStorage();

        _ipTokenUsdt = getIpTokenUsdt(address(_usdt));

        _stanleyUsdt = getMockCase0Stanley(address(_usdt));

        _itfMiltonUsdt = getItfMiltonUsdt(
            address(_usdt),
            address(_iporOracle),
            address(_miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(_stanleyUsdt)
        );

        _itfJosephUsdt = getItfJosephUsdt(
            address(_usdt),
            address(_ipTokenUsdt),
            address(_itfMiltonUsdt),
            address(_miltonStorageUsdt),
            address(_stanleyUsdt)
        );

        prepareIpTokenUsdt(_ipTokenUsdt, address(_itfJosephUsdt));
        prepareJoseph(_itfJosephUsdt);
        prepareMilton(_itfMiltonUsdt, address(_itfJosephUsdt), address(_stanleyUsdt));
    }

    function _clearAndSetupSmartContractsDai() private {
        _miltonStorageDai = getMiltonStorage();
        _ipTokenDai = getIpTokenDai(address(_dai));
        _stanleyDai = getMockCase0Stanley(address(_dai));

        _itfMiltonDai = getItfMiltonDai(
            address(_dai),
            address(_iporOracle),
            address(_miltonStorageDai),
            address(_miltonSpreadModel),
            address(_stanleyDai)
        );

        _itfJosephDai = getItfJosephDai(
            address(_dai),
            address(_ipTokenDai),
            address(_itfMiltonDai),
            address(_miltonStorageDai),
            address(_stanleyDai)
        );

        prepareIpTokenDai(_ipTokenDai, address(_itfJosephDai));
        prepareJoseph(_itfJosephDai);
        prepareMilton(_itfMiltonDai, address(_itfJosephDai), address(_stanleyDai));
    }

    function _executeProvideLiquidityUsdt(
        uint256 autoRebalanceThreshold,
        uint256 miltonStanleyRatio,
        uint256 miltonInitPool,
        uint256 stanleyInitBalance,
        uint256 userPosition,
        uint256 expectedStanleyBalance,
        uint256 expectedMiltonBalance
    ) internal {
        _itfJosephUsdt.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _itfJosephUsdt.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(_usdt), address(_itfMiltonUsdt), miltonInitPool);

        vm.startPrank(address(_itfMiltonUsdt));
        _stanleyUsdt.deposit(stanleyInitBalance);
        vm.stopPrank();

        deal(address(_usdt), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _usdt.approve(address(_itfJosephUsdt), userPosition);

        //when
        _itfJosephUsdt.provideLiquidity(userPosition);
        vm.stopPrank();

        //then

        assertEq(_stanleyUsdt.totalBalance(address(_itfMiltonUsdt)), expectedStanleyBalance);
        assertEq(_usdt.balanceOf(address(_itfMiltonUsdt)), expectedMiltonBalance);
    }

    function _executeProvideLiquidityDai(
        uint256 autoRebalanceThreshold,
        uint256 miltonStanleyRatio,
        uint256 miltonInitPool,
        uint256 stanleyInitBalance,
        uint256 userPosition,
        uint256 expectedStanleyBalance,
        uint256 expectedMiltonBalance
    ) internal {
        _itfJosephDai.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _itfJosephDai.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(_dai), address(_itfMiltonDai), miltonInitPool);

        vm.prank(address(_itfJosephDai));
        _itfMiltonDai.depositToStanley(stanleyInitBalance);

        deal(address(_dai), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _dai.approve(address(_itfJosephDai), userPosition);

        //when
        _itfJosephDai.provideLiquidity(userPosition);
        vm.stopPrank();

        //then

        assertEq(_stanleyDai.totalBalance(address(_itfMiltonDai)), expectedStanleyBalance);
        assertEq(_dai.balanceOf(address(_itfMiltonDai)), expectedMiltonBalance);
    }

    function _executeRedeemUsdt(
        uint256 autoRebalanceThreshold,
        uint256 miltonStanleyRatio,
        uint256 miltonInitPool,
        uint256 stanleyInitBalance,
        uint256 userPosition,
        uint256 expectedStanleyBalance,
        uint256 expectedMiltonBalance
    ) internal {
        uint256 wadUserPosition = userPosition * 1e12;

        deal(address(_usdt), address(_userOne), miltonInitPool);

        _itfJosephUsdt.setAutoRebalanceThreshold(uint32(miltonInitPool + 1000));

        vm.startPrank(address(_userOne));

        _usdt.approve(address(_itfJosephUsdt), miltonInitPool);
        _itfJosephUsdt.provideLiquidity(miltonInitPool);

        vm.stopPrank();
        _itfJosephUsdt.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _itfJosephUsdt.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        vm.prank(address(_itfJosephUsdt));
        _itfMiltonUsdt.depositToStanley(stanleyInitBalance);

        uint256 exchangeRate = _itfJosephUsdt.calculateExchangeRate();

        uint256 userPositionCalculated = IporMath.division(
            wadUserPosition * Constants.D18,
            exchangeRate
        );

        //when
        vm.prank(address(_userOne));
        _itfJosephUsdt.redeem(userPositionCalculated);

        //then
        assertEq(_stanleyUsdt.totalBalance(address(_itfMiltonUsdt)), expectedStanleyBalance);
        assertEq(_usdt.balanceOf(address(_itfMiltonUsdt)), expectedMiltonBalance);
    }

    function _executeRedeemDai(
        uint256 autoRebalanceThreshold,
        uint256 miltonStanleyRatio,
        uint256 miltonInitPool,
        uint256 stanleyInitBalance,
        uint256 userPosition,
        uint256 expectedStanleyBalance,
        uint256 expectedMiltonBalance
    ) internal {
        uint256 wadUserPosition = userPosition;

        deal(address(_dai), address(_userOne), miltonInitPool);

        _itfJosephDai.setAutoRebalanceThreshold(uint32(miltonInitPool + 1000));

        vm.startPrank(address(_userOne));

        _dai.approve(address(_itfJosephDai), miltonInitPool);
        _itfJosephDai.provideLiquidity(miltonInitPool);

        vm.stopPrank();

        _itfJosephDai.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _itfJosephDai.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        vm.prank(address(_itfJosephDai));
        _itfMiltonDai.depositToStanley(stanleyInitBalance);

        uint256 exchangeRate = _itfJosephDai.calculateExchangeRate();
        uint256 userPositionCalculated = IporMath.division(
            wadUserPosition * Constants.D18,
            exchangeRate
        );

        //when
        vm.prank(address(_userOne));
        _itfJosephDai.redeem(userPositionCalculated);

        //then
        assertEq(_stanleyDai.totalBalance(address(_itfMiltonDai)), expectedStanleyBalance);
        assertEq(_dai.balanceOf(address(_itfMiltonDai)), expectedMiltonBalance);
    }
}
