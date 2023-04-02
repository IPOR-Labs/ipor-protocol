// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../TestCommons.sol";
import {DataUtils} from "../../utils/DataUtils.sol";
import "../../../contracts/mocks/MockIporSwapLogic.sol";

contract IporSwapLogicTest is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10OppositeLegRateHigher() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 688150684931506849315);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysOppositeLegRateEqual() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 195000000000000000000);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysOppositeLegRateLower() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -298150684931506849314);
    }
}
