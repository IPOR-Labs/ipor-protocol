// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "test/TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "contracts/libraries/math/IporMath.sol";
import "contracts/libraries/Constants.sol";

contract JosephAutoRebalance is Test, TestCommons, DataUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

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
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 242000 * 1e6;
        uint256 expectedAssetManagementBalance = 968000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase02() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 230000 * 1e6;
        uint256 expectedAssetManagementBalance = 920000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase03() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 50;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 210000 * 1e6;
        uint256 expectedAssetManagementBalance = 840000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase04() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 370000 * 1e6;
        uint256 expectedAssetManagementBalance = 1480000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase05() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 172500 * 1e6;
        uint256 expectedAssetManagementBalance = 977500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase06() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 181500 * 1e6;
        uint256 expectedAssetManagementBalance = 1028500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase07() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 277500 * 1e6;
        uint256 expectedAssetManagementBalance = 1572500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase08() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 287500 * 1e6;
        uint256 expectedAssetManagementBalance = 862500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase09() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 302500 * 1e6;
        uint256 expectedAssetManagementBalance = 907500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 462500 * 1e6;
        uint256 expectedAssetManagementBalance = 1387500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase11() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 50000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 57500 * 1e6;
        uint256 expectedAssetManagementBalance = 1092500 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase12() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 950000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 350000 * 1e6;
        uint256 expectedAssetManagementBalance = 800000 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceUsdtCase13() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 10000000000000000;
        uint256 ammTreasuryInitPool = 3000 * 1e6;
        uint256 assetManagementInitBalance = 0;
        uint256 userPosition = 100000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 1030 * 1e6;
        uint256 expectedAssetManagementBalance = 101970 * 1e18;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndNOTRebalanceUsdtCaseBelowThreshold() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 300;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 200000 * 1e6 + userPosition;
        uint256 expectedAssetManagementBalance = assetManagementInitBalance;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndNOTRebalanceUsdtCaseAutoRebalanceThresholdZERO() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 0;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 200000 * 1e6 + userPosition;
        uint256 expectedAssetManagementBalance = assetManagementInitBalance;

        _executeProvideLiquidityUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase01() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 242000 * 1e18;
        uint256 expectedAssetManagementBalance = 968000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase02() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 230000 * 1e18;
        uint256 expectedAssetManagementBalance = 920000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase03() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 50;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 210000 * 1e18;
        uint256 expectedAssetManagementBalance = 840000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase04() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 370000 * 1e18;
        uint256 expectedAssetManagementBalance = 1480000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase05() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 172500 * 1e18;
        uint256 expectedAssetManagementBalance = 977500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase06() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 181500 * 1e18;
        uint256 expectedAssetManagementBalance = 1028500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase07() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 277500 * 1e18;
        uint256 expectedAssetManagementBalance = 1572500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase08() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 287500 * 1e18;
        uint256 expectedAssetManagementBalance = 862500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase09() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 302500 * 1e18;
        uint256 expectedAssetManagementBalance = 907500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 462500 * 1e18;
        uint256 expectedAssetManagementBalance = 1387500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase11() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 50000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 57500 * 1e18;
        uint256 expectedAssetManagementBalance = 1092500 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase12() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 950000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 350000 * 1e18;
        uint256 expectedAssetManagementBalance = 800000 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testProvideLiquidityAndRebalanceDaiCase13() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 10000000000000000;
        uint256 ammTreasuryInitPool = 3000 * 1e18;
        uint256 assetManagementInitBalance = 0;
        uint256 userPosition = 100000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 1030 * 1e18;
        uint256 expectedAssetManagementBalance = 101970 * 1e18;

        _executeProvideLiquidityDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase01() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 158210 * 1e6;
        uint256 expectedAssetManagementBalance = 632840 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase02() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 170150 * 1e6;
        uint256 expectedAssetManagementBalance = 680600 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase03() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 40;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 190050 * 1e6;
        uint256 expectedAssetManagementBalance = 760200 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase04() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 30850 * 1e6;
        uint256 expectedAssetManagementBalance = 123400 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase05() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 1276125 * 1e5;
        uint256 expectedAssetManagementBalance = 7231375 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase06() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 1186575 * 1e5;
        uint256 expectedAssetManagementBalance = 6723925 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase07() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 231375 * 1e5;
        uint256 expectedAssetManagementBalance = 1311125 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase08() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 2126875 * 1e5;
        uint256 expectedAssetManagementBalance = 6380625 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase09() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 1977625 * 1e5;
        uint256 expectedAssetManagementBalance = 5932875 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 385625 * 1e5;
        uint256 expectedAssetManagementBalance = 1156875 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndNoRebalanceUsdtCase11() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 50000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        // will stay because threshold is not achieved and AmmTreasury has cash for redeem
        uint256 redeemFee = 750 * 1e6;
        uint256 expectedAmmTreasuryBalance = 50000 * 1e6 + redeemFee;
        uint256 expectedAssetManagementBalance = assetManagementInitBalance;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCase12() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 950000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 8082125 * 1e5;
        uint256 expectedAssetManagementBalance = 425375 * 1e17;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase01() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 158210 * 1e18;
        uint256 expectedAssetManagementBalance = 632840 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase02() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 170150 * 1e18;
        uint256 expectedAssetManagementBalance = 680600 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase03() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 40;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 190050 * 1e18;
        uint256 expectedAssetManagementBalance = 760200 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase04() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 30850 * 1e18;
        uint256 expectedAssetManagementBalance = 123400 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase05() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 1276125 * 1e17;
        uint256 expectedAssetManagementBalance = 7231375 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase06() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 1186575 * 1e17;
        uint256 expectedAssetManagementBalance = 6723925 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase07() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 231375 * 1e17;
        uint256 expectedAssetManagementBalance = 1311125 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase08() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 2126875 * 1e17;
        uint256 expectedAssetManagementBalance = 6380625 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase09() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 1977625 * 1e17;
        uint256 expectedAssetManagementBalance = 5932875 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 250000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 850000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 385625 * 1e17;
        uint256 expectedAssetManagementBalance = 1156875 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndNoRebalanceDaiCase11() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 50000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        // will stay because threshold is not achieved and AmmTreasury has cash for redeem
        uint256 redeemFee = 750 * 1e18;
        uint256 expectedAmmTreasuryBalance = 50000 * 1e18 + redeemFee;
        uint256 expectedAssetManagementBalance = assetManagementInitBalance;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCase12() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 100;
        uint256 ammTreasuryAssetManagementRatio = 950000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 8082125 * 1e17;
        uint256 expectedAssetManagementBalance = 425375 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceDaiCaseBigValues() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 10000;
        uint256 ammTreasuryAssetManagementRatio = 150000000000000000;
        uint256 ammTreasuryInitPool = 1000000000 * 1e18;
        uint256 assetManagementInitBalance = 800000000 * 1e18;
        uint256 userPosition = 150000000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 1276125000 * 1e17;
        uint256 expectedAssetManagementBalance = 7231375000 * 1e17;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndNoRebalanceDaiCaseBelowThresholdBecauseOfFee() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 autoRebalanceThreshold = 50;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e18;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 50000 * 1e18;

        uint256 expectedAmmTreasuryBalance = 150250 * 1e18;
        uint256 expectedAssetManagementBalance = 800000 * 1e18;

        _executeRedeemDai(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndNOTRebalanceUsdtCaseBelowThresholdAmmTreasuryBalanceIsOK() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 300;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 50750 * 1e6;
        uint256 expectedAssetManagementBalance = assetManagementInitBalance;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCaseBelowThresholdButAmmTreasuryBalanceTooLow() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 300;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 158210 * 1e6;
        uint256 expectedAssetManagementBalance = 632840 * 1e18;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function testRedeemAndRebalanceUsdtCaseAutoRebalanceThresholdZEROAmmTreasuryBalanceTooLow() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 0;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 210000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 158210 * 1e6;
        uint256 expectedAssetManagementBalance = 632840 * 1e18;

        uint256 wadUserPosition = userPosition * 1e12;

        deal(address(_iporProtocol.asset), address(_userOne), ammTreasuryInitPool);

        _iporProtocol.joseph.setAutoRebalanceThreshold(uint32(ammTreasuryInitPool + 1000));

        vm.startPrank(address(_userOne));

        _iporProtocol.asset.approve(address(_iporProtocol.joseph), ammTreasuryInitPool);
        _iporProtocol.joseph.provideLiquidity(ammTreasuryInitPool);

        vm.stopPrank();
        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

        vm.prank(address(_iporProtocol.joseph));
        _iporProtocol.ammTreasury.depositToAssetManagement(assetManagementInitBalance);

        uint256 exchangeRate = _iporProtocol.joseph.calculateExchangeRate();

        uint256 userPositionCalculated = IporMath.division(wadUserPosition * 1e18, exchangeRate);

        vm.prank(address(_userOne));

        //when
        _iporProtocol.joseph.redeem(userPositionCalculated);

        //then
        assertEq(_iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)), expectedAssetManagementBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
    }

    function testRedeemAndNOTRebalanceUsdtCaseAutoRebalanceThresholdZEROAmmTreasuryBalanceIsOK() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 autoRebalanceThreshold = 0;
        uint256 ammTreasuryAssetManagementRatio = 200000000000000000;
        uint256 ammTreasuryInitPool = 1000000 * 1e6;
        uint256 assetManagementInitBalance = 800000 * 1e18;
        uint256 userPosition = 150000 * 1e6;

        uint256 expectedAmmTreasuryBalance = 50750 * 1e6;
        uint256 expectedAssetManagementBalance = assetManagementInitBalance;

        _executeRedeemUsdt(
            autoRebalanceThreshold,
            ammTreasuryAssetManagementRatio,
            ammTreasuryInitPool,
            assetManagementInitBalance,
            userPosition,
            expectedAssetManagementBalance,
            expectedAmmTreasuryBalance
        );
    }

    function _executeProvideLiquidityUsdt(
        uint256 autoRebalanceThreshold,
        uint256 ammTreasuryAssetManagementRatio,
        uint256 ammTreasuryInitPool,
        uint256 assetManagementInitBalance,
        uint256 userPosition,
        uint256 expectedAssetManagementBalance,
        uint256 expectedAmmTreasuryBalance
    ) internal {
        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

        deal(address(_iporProtocol.asset), address(_iporProtocol.ammTreasury), ammTreasuryInitPool);

        if (assetManagementInitBalance > 0) {
            vm.prank(address(_iporProtocol.joseph));
            _iporProtocol.ammTreasury.depositToAssetManagement(assetManagementInitBalance);
        }

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), userPosition);

        //when
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        //then

        assertEq(_iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)), expectedAssetManagementBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
    }

    function _executeProvideLiquidityDai(
        uint256 autoRebalanceThreshold,
        uint256 ammTreasuryAssetManagementRatio,
        uint256 ammTreasuryInitPool,
        uint256 assetManagementInitBalance,
        uint256 userPosition,
        uint256 expectedAssetManagementBalance,
        uint256 expectedAmmTreasuryBalance
    ) internal {
        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

        deal(address(_iporProtocol.asset), address(_iporProtocol.ammTreasury), ammTreasuryInitPool);

        if (assetManagementInitBalance > 0) {
            vm.prank(address(_iporProtocol.joseph));
            _iporProtocol.ammTreasury.depositToAssetManagement(assetManagementInitBalance);
        }

        deal(address(_iporProtocol.asset), address(_userOne), userPosition);

        vm.startPrank(address(_userOne));
        _iporProtocol.asset.approve(address(_iporProtocol.joseph), userPosition);

        //when
        _iporProtocol.joseph.provideLiquidity(userPosition);
        vm.stopPrank();

        //then

        assertEq(_iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)), expectedAssetManagementBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
    }

    function _executeRedeemUsdt(
        uint256 autoRebalanceThreshold,
        uint256 ammTreasuryAssetManagementRatio,
        uint256 ammTreasuryInitPool,
        uint256 assetManagementInitBalance,
        uint256 userPosition,
        uint256 expectedAssetManagementBalance,
        uint256 expectedAmmTreasuryBalance
    ) internal {
        uint256 wadUserPosition = userPosition * 1e12;

        deal(address(_iporProtocol.asset), address(_userOne), ammTreasuryInitPool);

        _iporProtocol.joseph.setAutoRebalanceThreshold(uint32(ammTreasuryInitPool + 1000));

        vm.startPrank(address(_userOne));

        _iporProtocol.asset.approve(address(_iporProtocol.joseph), ammTreasuryInitPool);
        _iporProtocol.joseph.provideLiquidity(ammTreasuryInitPool);

        vm.stopPrank();
        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

        vm.prank(address(_iporProtocol.joseph));
        _iporProtocol.ammTreasury.depositToAssetManagement(assetManagementInitBalance);

        uint256 exchangeRate = _iporProtocol.joseph.calculateExchangeRate();

        uint256 userPositionCalculated = IporMath.division(wadUserPosition * 1e18, exchangeRate);

        //when
        vm.prank(address(_userOne));
        _iporProtocol.joseph.redeem(userPositionCalculated);

        //then
        assertEq(_iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)), expectedAssetManagementBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
    }

    function _executeRedeemDai(
        uint256 autoRebalanceThreshold,
        uint256 ammTreasuryAssetManagementRatio,
        uint256 ammTreasuryInitPool,
        uint256 assetManagementInitBalance,
        uint256 userPosition,
        uint256 expectedAssetManagementBalance,
        uint256 expectedAmmTreasuryBalance
    ) internal {
        uint256 wadUserPosition = userPosition;

        deal(address(_iporProtocol.asset), address(_userOne), ammTreasuryInitPool);

        _iporProtocol.joseph.setAutoRebalanceThreshold(uint32(ammTreasuryInitPool + 1000));

        vm.startPrank(address(_userOne));

        _iporProtocol.asset.approve(address(_iporProtocol.joseph), ammTreasuryInitPool);
        _iporProtocol.joseph.provideLiquidity(ammTreasuryInitPool);

        vm.stopPrank();

        _iporProtocol.joseph.setAutoRebalanceThreshold(autoRebalanceThreshold);
        _iporProtocol.joseph.setAmmTreasuryAssetManagementBalanceRatio(ammTreasuryAssetManagementRatio);

        vm.prank(address(_iporProtocol.joseph));
        _iporProtocol.ammTreasury.depositToAssetManagement(assetManagementInitBalance);

        uint256 exchangeRate = _iporProtocol.joseph.calculateExchangeRate();
        uint256 userPositionCalculated = IporMath.division(wadUserPosition * 1e18, exchangeRate);

        //when
        vm.prank(address(_userOne));
        _iporProtocol.joseph.redeem(userPositionCalculated);

        //then
        assertEq(_iporProtocol.assetManagement.totalBalance(address(_iporProtocol.ammTreasury)), expectedAssetManagementBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
    }
}
