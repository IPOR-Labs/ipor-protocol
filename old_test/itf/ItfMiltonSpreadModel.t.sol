// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../../test/utils/TestConstants.sol";
import "contracts/itf/ItfAmmTreasurySpreadModelDai.sol";

contract ItfAmmTreasurySpreadModelTest is TestCommons {
    ItfAmmTreasurySpreadModelDai internal _iftAmmTreasurySpreadModelDai;

    struct SpreadModelParams {
        int256 payFixedRegionOneBase;
        int256 payFixedRegionOneSlopeForVolatility;
        int256 payFixedRegionOneSlopeForMeanReversion;
        int256 payFixedRegionTwoBase;
        int256 payFixedRegionTwoSlopeForVolatility;
        int256 payFixedRegionTwoSlopeForMeanReversion;
        int256 receiveFixedRegionOneBase;
        int256 receiveFixedRegionOneSlopeForVolatility;
        int256 receiveFixedRegionOneSlopeForMeanReversion;
        int256 receiveFixedRegionTwoBase;
        int256 receiveFixedRegionTwoSlopeForVolatility;
        int256 receiveFixedRegionTwoSlopeForMeanReversion;
    }

    function setUp() public {
        _iftAmmTreasurySpreadModelDai = new ItfAmmTreasurySpreadModelDai();
    }

    function testShouldCheckIfSetupMethodWorksForDAI() public {
        // given
        SpreadModelParams memory spreadModelParamsBefore;
        spreadModelParamsBefore.payFixedRegionOneBase = _iftAmmTreasurySpreadModelDai.getPayFixedRegionOneBase();
        spreadModelParamsBefore.payFixedRegionOneSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionOneSlopeForVolatility();
        spreadModelParamsBefore.payFixedRegionOneSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsBefore.payFixedRegionTwoBase = _iftAmmTreasurySpreadModelDai.getPayFixedRegionTwoBase();
        spreadModelParamsBefore.payFixedRegionTwoSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionTwoSlopeForVolatility();
        spreadModelParamsBefore.payFixedRegionTwoSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionTwoSlopeForMeanReversion();
        spreadModelParamsBefore.receiveFixedRegionOneBase = _iftAmmTreasurySpreadModelDai.getReceiveFixedRegionOneBase();
        spreadModelParamsBefore.receiveFixedRegionOneSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionOneSlopeForVolatility();
        spreadModelParamsBefore.receiveFixedRegionOneSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsBefore.receiveFixedRegionTwoBase = _iftAmmTreasurySpreadModelDai.getReceiveFixedRegionTwoBase();
        spreadModelParamsBefore.receiveFixedRegionTwoSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionTwoSlopeForVolatility();
        spreadModelParamsBefore.receiveFixedRegionTwoSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        // when
        _iftAmmTreasurySpreadModelDai.setupModelParams(
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT,
            TestConstants.D16_INT
        );
        // then
        SpreadModelParams memory spreadModelParamsAfter;
        spreadModelParamsAfter.payFixedRegionOneBase = _iftAmmTreasurySpreadModelDai.getPayFixedRegionOneBase();
        spreadModelParamsAfter.payFixedRegionOneSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionOneSlopeForVolatility();
        spreadModelParamsAfter.payFixedRegionOneSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsAfter.payFixedRegionTwoBase = _iftAmmTreasurySpreadModelDai.getPayFixedRegionTwoBase();
        spreadModelParamsAfter.payFixedRegionTwoSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionTwoSlopeForVolatility();
        spreadModelParamsAfter.payFixedRegionTwoSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionTwoSlopeForMeanReversion();
        spreadModelParamsAfter.receiveFixedRegionOneBase = _iftAmmTreasurySpreadModelDai.getReceiveFixedRegionOneBase();
        spreadModelParamsAfter.receiveFixedRegionOneSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionOneSlopeForVolatility();
        spreadModelParamsAfter.receiveFixedRegionOneSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsAfter.receiveFixedRegionTwoBase = _iftAmmTreasurySpreadModelDai.getReceiveFixedRegionTwoBase();
        spreadModelParamsAfter.receiveFixedRegionTwoSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionTwoSlopeForVolatility();
        spreadModelParamsAfter.receiveFixedRegionTwoSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        assertTrue(spreadModelParamsBefore.payFixedRegionOneBase != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionOneSlopeForVolatility != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionOneSlopeForMeanReversion != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionTwoBase != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionTwoSlopeForVolatility != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionTwoSlopeForMeanReversion != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionOneBase != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionOneSlopeForVolatility != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionOneSlopeForMeanReversion != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionTwoBase != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionTwoSlopeForVolatility != TestConstants.D16_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionTwoSlopeForMeanReversion != TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionOneBase, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionOneSlopeForVolatility, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionOneSlopeForMeanReversion, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionTwoBase, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionTwoSlopeForVolatility, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionTwoSlopeForMeanReversion, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionOneBase, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionOneSlopeForVolatility, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionOneSlopeForMeanReversion, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionTwoBase, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionTwoSlopeForVolatility, TestConstants.D16_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionTwoSlopeForMeanReversion, TestConstants.D16_INT);
    }

    function testShouldSetupParamsToZeroDAI() public {
        // given
        SpreadModelParams memory spreadModelParamsBefore;
        spreadModelParamsBefore.payFixedRegionOneBase = _iftAmmTreasurySpreadModelDai.getPayFixedRegionOneBase();
        spreadModelParamsBefore.payFixedRegionOneSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionOneSlopeForVolatility();
        spreadModelParamsBefore.payFixedRegionOneSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsBefore.payFixedRegionTwoBase = _iftAmmTreasurySpreadModelDai.getPayFixedRegionTwoBase();
        spreadModelParamsBefore.payFixedRegionTwoSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionTwoSlopeForVolatility();
        spreadModelParamsBefore.payFixedRegionTwoSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionTwoSlopeForMeanReversion();
        spreadModelParamsBefore.receiveFixedRegionOneBase = _iftAmmTreasurySpreadModelDai.getReceiveFixedRegionOneBase();
        spreadModelParamsBefore.receiveFixedRegionOneSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionOneSlopeForVolatility();
        spreadModelParamsBefore.receiveFixedRegionOneSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsBefore.receiveFixedRegionTwoBase = _iftAmmTreasurySpreadModelDai.getReceiveFixedRegionTwoBase();
        spreadModelParamsBefore.receiveFixedRegionTwoSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionTwoSlopeForVolatility();
        spreadModelParamsBefore.receiveFixedRegionTwoSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        // when
        _iftAmmTreasurySpreadModelDai.setupModelParams(
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        // then
        SpreadModelParams memory spreadModelParamsAfter;
        spreadModelParamsAfter.payFixedRegionOneBase = _iftAmmTreasurySpreadModelDai.getPayFixedRegionOneBase();
        spreadModelParamsAfter.payFixedRegionOneSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionOneSlopeForVolatility();
        spreadModelParamsAfter.payFixedRegionOneSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsAfter.payFixedRegionTwoBase = _iftAmmTreasurySpreadModelDai.getPayFixedRegionTwoBase();
        spreadModelParamsAfter.payFixedRegionTwoSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionTwoSlopeForVolatility();
        spreadModelParamsAfter.payFixedRegionTwoSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getPayFixedRegionTwoSlopeForMeanReversion();
        spreadModelParamsAfter.receiveFixedRegionOneBase = _iftAmmTreasurySpreadModelDai.getReceiveFixedRegionOneBase();
        spreadModelParamsAfter.receiveFixedRegionOneSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionOneSlopeForVolatility();
        spreadModelParamsAfter.receiveFixedRegionOneSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsAfter.receiveFixedRegionTwoBase = _iftAmmTreasurySpreadModelDai.getReceiveFixedRegionTwoBase();
        spreadModelParamsAfter.receiveFixedRegionTwoSlopeForVolatility = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionTwoSlopeForVolatility();
        spreadModelParamsAfter.receiveFixedRegionTwoSlopeForMeanReversion = _iftAmmTreasurySpreadModelDai
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        assertTrue(spreadModelParamsBefore.payFixedRegionOneBase != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionOneSlopeForVolatility != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionOneSlopeForMeanReversion != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionTwoBase != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionTwoSlopeForVolatility != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.payFixedRegionTwoSlopeForMeanReversion == TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionOneBase != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionOneSlopeForVolatility != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionOneSlopeForMeanReversion != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionTwoBase != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionTwoSlopeForVolatility != TestConstants.ZERO_INT);
        assertTrue(spreadModelParamsBefore.receiveFixedRegionTwoSlopeForMeanReversion == TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionOneBase, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionOneSlopeForVolatility, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionOneSlopeForMeanReversion, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionTwoBase, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionTwoSlopeForVolatility, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.payFixedRegionTwoSlopeForMeanReversion, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionOneBase, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionOneSlopeForVolatility, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionOneSlopeForMeanReversion, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionTwoBase, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionTwoSlopeForVolatility, TestConstants.ZERO_INT);
        assertEq(spreadModelParamsAfter.receiveFixedRegionTwoSlopeForMeanReversion, TestConstants.ZERO_INT);
    }
}
