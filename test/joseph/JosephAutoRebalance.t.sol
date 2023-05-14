// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
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
import "../../contracts/itf/ItfStanley.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";

contract JosephAutoRebalance is Test, TestCommons, DataUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
        _cfg.iporOracleUpdater = _admin;
        _cfg.iporRiskManagementOracleUpdater = _admin;
    }

    function testProvideLiquidityAndRebalanceUsdtCase01() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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

    function testProvideLiquidityAndNOTRebalanceUsdtCaseBelowThreshold() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 300;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 200000 * 1e6 + userPosition;
        uint256 expectedStanleyBalance = stanleyInitBalance;

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

    function testProvideLiquidityAndNOTRebalanceUsdtCaseAutoRebalanceThresholdZERO() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 0;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 200000 * 1e6 + userPosition;
        uint256 expectedStanleyBalance = stanleyInitBalance;

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 50000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        // will stay because threshold is not achieved and Milton has cash for redeem
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
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 miltonStanleyRatio = 50000000000000000;
        uint256 miltonInitPool = 1000000 * 1e18;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        // will stay because threshold is not achieved and Milton has cash for redeem
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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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

    function testRedeemAndNoRebalanceDaiCaseBelowThresholdBecauseOfFee() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

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

    function testRedeemAndNOTRebalanceUsdtCaseBelowThresholdMiltonBalanceIsOK() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 300;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 50750 * 1e6;
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

    function testRedeemAndRebalanceUsdtCaseBelowThresholdButMiltonBalanceTooLow() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 300;
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

    function testRedeemAndRebalanceUsdtCaseAutoRebalanceThresholdZEROMiltonBalanceTooLow() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 0;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedMiltonBalance = 158210 * 1e6;
        uint256 expectedStanleyBalance = 632840 * 1e18;

        uint256 wadUserPosition = userPosition * 1e12;

        deal(address(_iporProtocol.asset), address(_userOne), miltonInitPool);

        _iporProtocol.joseph.setAutoRebalanceThreshold(uint32(miltonInitPool + 1000));

        vm.startPrank(address(_userOne));

        _iporProtocol.asset.approve(address(_iporProtocol.joseph), miltonInitPool);
        _iporProtocol.joseph.provideLiquidity(miltonInitPool);

        vm.stopPrank();
        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        vm.prank(address(_iporProtocol.joseph));
        _iporProtocol.milton.depositToStanley(stanleyInitBalance);

        uint256 exchangeRate = _iporProtocol.joseph.calculateExchangeRate();

        uint256 userPositionCalculated = IporMath.division(
            wadUserPosition * Constants.D18,
            exchangeRate
        );

        vm.prank(address(_userOne));

        //when
        _iporProtocol.joseph.redeem(userPositionCalculated);

        //then
        assertEq(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedMiltonBalance
        );
    }

    function testRedeemAndNOTRebalanceUsdtCaseAutoRebalanceThresholdZEROMiltonBalanceIsOK() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 0;
        uint256 miltonStanleyRatio = 200000000000000000;
        uint256 miltonInitPool = 1000000 * 1e6;
        uint256 stanleyInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedMiltonBalance = 50750 * 1e6;
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

    function _executeProvideLiquidityUsdt(
        uint256 autoRebalanceThreshold,
        uint256 miltonStanleyRatio,
        uint256 miltonInitPool,
        uint256 stanleyInitBalance,
        uint256 userPosition,
        uint256 expectedStanleyBalance,
        uint256 expectedMiltonBalance
    ) internal {
        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(_iporProtocol.asset), address(_iporProtocol.milton), miltonInitPool);

        if (stanleyInitBalance > 0) {
            vm.prank(address(_iporProtocol.joseph));
            _iporProtocol.milton.depositToStanley(stanleyInitBalance);
        }

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), userPosition);

        //when
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        //then

        assertEq(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedMiltonBalance
        );
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
        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        deal(address(_iporProtocol.asset), address(_iporProtocol.milton), miltonInitPool);

        if (stanleyInitBalance > 0) {
            vm.prank(address(_iporProtocol.joseph));
            _iporProtocol.milton.depositToStanley(stanleyInitBalance);
        }

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), userPosition);

        //when
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        //then

        assertEq(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedMiltonBalance
        );
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

        deal(address(_iporProtocol.asset), address(_userOne), miltonInitPool);

        _iporProtocol.joseph.setAutoRebalanceThreshold(uint32(miltonInitPool + 1000));

        vm.startPrank(address(_userOne));

        _iporProtocol.asset.approve(address(_iporProtocol.joseph), miltonInitPool);
        _iporProtocol.joseph.provideLiquidity(miltonInitPool);

        vm.stopPrank();
        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        vm.prank(address(_iporProtocol.joseph));
        _iporProtocol.milton.depositToStanley(stanleyInitBalance);

        uint256 exchangeRate = _iporProtocol.joseph.calculateExchangeRate();

        uint256 userPositionCalculated = IporMath.division(
            wadUserPosition * Constants.D18,
            exchangeRate
        );

        //when
        vm.prank(address(_userOne));
        _iporProtocol.joseph.redeem(userPositionCalculated);

        //then
        assertEq(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedMiltonBalance
        );
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

        deal(address(_iporProtocol.asset), address(_userOne), miltonInitPool);

        _iporProtocol.joseph.setAutoRebalanceThreshold(uint32(miltonInitPool + 1000));

        vm.startPrank(address(_userOne));

        _iporProtocol.asset.approve(address(_iporProtocol.joseph), miltonInitPool);
        _iporProtocol.joseph.provideLiquidity(miltonInitPool);

        vm.stopPrank();

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(miltonStanleyRatio);

        vm.prank(address(_iporProtocol.joseph));
        _iporProtocol.milton.depositToStanley(stanleyInitBalance);

        uint256 exchangeRate = _iporProtocol.joseph.calculateExchangeRate();
        uint256 userPositionCalculated = IporMath.division(
            wadUserPosition * Constants.D18,
            exchangeRate
        );

        //when
        vm.prank(address(_userOne));
        _iporProtocol.joseph.redeem(userPositionCalculated);

        //then
        assertEq(
            _iporProtocol.stanley.totalBalance(address(_iporProtocol.milton)),
            expectedStanleyBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedMiltonBalance
        );
    }
}
