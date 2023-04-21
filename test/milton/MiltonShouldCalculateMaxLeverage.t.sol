// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../utils/SwapUtils.sol";
import "../utils/DataUtils.sol";
import "../utils/TestConstants.sol";
import "../TestCommons.sol";

contract MiltonShouldCalculateMaxLeverageTest is Test, TestCommons, DataUtils {
    IporProtocol private _iporProtocolDai;
    IporProtocol private _iporProtocolUsdt;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _iporProtocolDai = setupIporProtocolForDai();
        _iporProtocolDai.asset.approve(address(_iporProtocolDai.joseph), TestConstants.USD_100_000_18DEC);
        _iporProtocolDai.joseph.provideLiquidity(TestConstants.USD_100_000_18DEC);
        _iporProtocolUsdt = setupIporProtocolForUsdt();
        _iporProtocolUsdt.asset.approve(address(_iporProtocolUsdt.joseph), TestConstants.USD_100_000_6DEC);
        _iporProtocolUsdt.joseph.provideLiquidity(TestConstants.USD_100_000_6DEC);
    }

    function testShouldCalculateMaxLeverage() public {
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.MSO_NOTIONAL_10B,
            TestConstants.MSO_NOTIONAL_2B,
            1000 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.MSO_NOTIONAL_1B,
            TestConstants.MSO_NOTIONAL_100M,
            1000 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.MSO_NOTIONAL_50M,
            TestConstants.MSO_NOTIONAL_10M,
            1000 * 1e18,
            500 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.MSO_NOTIONAL_50M,
            TestConstants.MSO_NOTIONAL_10M,
            1000 * 1e18,
            500 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.MSO_NOTIONAL_2M_220K,
            TestConstants.MSO_NOTIONAL_1M_500K,
            111 * 1e18,
            75 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolDai,
            TestConstants.MSO_NOTIONAL_1M,
            TestConstants.MSO_NOTIONAL_100K,
            50 * 1e18,
            10 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.MSO_NOTIONAL_10B,
            TestConstants.MSO_NOTIONAL_2B,
            1000 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.MSO_NOTIONAL_1B,
            TestConstants.MSO_NOTIONAL_100M,
            1000 * 1e18,
            1000 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.MSO_NOTIONAL_50M,
            TestConstants.MSO_NOTIONAL_10M,
            1000 * 1e18,
            500 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.MSO_NOTIONAL_50M,
            TestConstants.MSO_NOTIONAL_10M,
            1000 * 1e18,
            500 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.MSO_NOTIONAL_2M_220K,
            TestConstants.MSO_NOTIONAL_1M_500K,
            111 * 1e18,
            75 * 1e18
        );
        updateIndicatorsAndAssertMaxLeverage(
            _iporProtocolUsdt,
            TestConstants.MSO_NOTIONAL_1M,
            TestConstants.MSO_NOTIONAL_100K,
            50 * 1e18,
            10 * 1e18
        );
    }

    function updateIndicatorsAndAssertMaxLeverage(
        IporProtocol memory iporProtocol,
        uint64 maxNotionalPayFixed,
        uint64 maxNotionalReceiveFixed,
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
            TestConstants.MSO_UTILIZATION_RATE_20_PER,
            TestConstants.MSO_UTILIZATION_RATE_20_PER,
            TestConstants.MSO_UTILIZATION_RATE_35_PER
        );

        //when
        (uint256 maxLeveragePayFixed, uint256 maxLeverageReceiveFixed) = iporProtocol.milton.getMaxLeverage();

        //then
        assertEq(maxLeveragePayFixed, expectedMaxLeveragePayFixed);
        assertEq(maxLeverageReceiveFixed, expectedMaxLeverageReceiveFixed);
    }
}
