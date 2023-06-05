// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../utils/SwapUtils.sol";
import "../utils/DataUtils.sol";
import "../utils/TestConstants.sol";
import "../TestCommons.sol";

contract AmmTreasuryShouldCalculateMaxLeverageTest is Test, TestCommons, DataUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;

    BuilderUtils.IporProtocol internal _iporProtocolDai;
    BuilderUtils.IporProtocol internal _iporProtocolUsdt;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        address[] memory users = new address[](2);
        users[0] = _admin;
        users[1] = _userOne;

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.iporRiskManagementOracleUpdater = _userOne;

        _iporProtocolDai = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocolUsdt = _iporProtocolFactory.getUsdtInstance(_cfg);

        _iporProtocolDai.asset.approve(address(_iporProtocolDai.joseph), TestConstants.USD_100_000_18DEC);
        _iporProtocolDai.joseph.provideLiquidity(TestConstants.USD_100_000_18DEC);
        _iporProtocolUsdt.asset.approve(address(_iporProtocolUsdt.joseph), TestConstants.USD_100_000_6DEC);
        _iporProtocolUsdt.joseph.provideLiquidity(TestConstants.USD_100_000_6DEC);
    }

    function testShouldCalculateMaxLeverage() public {
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.RMO_NOTIONAL_10B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            1000 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_NOTIONAL_100M,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            1000 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.RMO_NOTIONAL_50M,
            TestConstants.RMO_NOTIONAL_10M,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            1000 * 1e18,
            500 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.RMO_NOTIONAL_50M,
            TestConstants.RMO_NOTIONAL_10M,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            1000 * 1e18,
            500 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.RMO_NOTIONAL_2M_220K,
            TestConstants.RMO_NOTIONAL_1M_500K,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            111 * 1e18,
            75 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.RMO_NOTIONAL_1M,
            TestConstants.RMO_NOTIONAL_100K,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            50 * 1e18,
            10 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.RMO_NOTIONAL_10B,
            TestConstants.RMO_NOTIONAL_2B,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            1000 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_NOTIONAL_100M,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            1000 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.RMO_NOTIONAL_50M,
            TestConstants.RMO_NOTIONAL_10M,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            1000 * 1e18,
            500 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.RMO_NOTIONAL_50M,
            TestConstants.RMO_NOTIONAL_10M,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            1000 * 1e18,
            500 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.RMO_NOTIONAL_2M_220K,
            TestConstants.RMO_NOTIONAL_1M_500K,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            111 * 1e18,
            75 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.RMO_NOTIONAL_1M,
            TestConstants.RMO_NOTIONAL_100K,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            50 * 1e18,
            10 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            type(uint64).min,
            type(uint64).max,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_20_PER,
            TestConstants.RMO_COLLATERAL_RATIO_35_PER,
            10 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            type(uint64).min,
            type(uint64).max,
            0,
            TestConstants.RMO_COLLATERAL_RATIO_100_PER,
            TestConstants.RMO_COLLATERAL_RATIO_100_PER,
            10 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            type(uint64).min,
            type(uint64).max,
            0,
            TestConstants.RMO_COLLATERAL_RATIO_100_PER,
            TestConstants.RMO_COLLATERAL_RATIO_100_PER,
            10 * 1e18,
            1000 * 1e18
        );
    }

    function updateIndicatorsAndAssertMaxLeverage(
        BuilderUtils.IporProtocol memory iporProtocol,
        uint64 maxNotionalPayFixed,
        uint64 maxNotionalReceiveFixed,
        uint16 maxCollateralRatioPayFixed,
        uint16 maxCollateralRatioReceiveFixed,
        uint16 maxCollateralRatio,
        uint256 expectedMaxLeveragePayFixed,
        uint256 expectedMaxLeverageReceiveFixed
    ) internal {
        //given
        IIporRiskManagementOracle iporRiskManagementOracle = iporProtocol.iporRiskManagementOracle;
        iporRiskManagementOracle.addUpdater(address(this));
        iporRiskManagementOracle.updateRiskIndicators(
            address(iporProtocol.asset),
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxCollateralRatioPayFixed,
            maxCollateralRatioReceiveFixed,
            maxCollateralRatio
        );

        //when
        (uint256 maxLeveragePayFixed, uint256 maxLeverageReceiveFixed) = iporProtocol.ammTreasury.getMaxLeverage();

        //then
        assertEq(maxLeveragePayFixed, expectedMaxLeveragePayFixed);
        assertEq(maxLeverageReceiveFixed, expectedMaxLeverageReceiveFixed);
    }
}
