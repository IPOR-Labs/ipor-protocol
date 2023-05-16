// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import "../../test/utils/TestConstants.sol";
import "contracts/itf/ItfMiltonSpreadModelDai.sol";

contract ItfMiltonSpreadModelTest is TestCommons {
    ItfMiltonSpreadModelDai internal _iftMiltonSpreadModelDai;

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
        _iftMiltonSpreadModelDai = new ItfMiltonSpreadModelDai();
    }

    function testShouldCheckIfSetupMethodWorksForDAI() public {
        // given
        SpreadModelParams memory spreadModelParamsBefore;
        spreadModelParamsBefore.payFixedRegionOneBase = _iftMiltonSpreadModelDai.getPayFixedRegionOneBase();
        spreadModelParamsBefore.payFixedRegionOneSlopeForVolatility = _iftMiltonSpreadModelDai
            .getPayFixedRegionOneSlopeForVolatility();
        spreadModelParamsBefore.payFixedRegionOneSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getPayFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsBefore.payFixedRegionTwoBase = _iftMiltonSpreadModelDai.getPayFixedRegionTwoBase();
        spreadModelParamsBefore.payFixedRegionTwoSlopeForVolatility = _iftMiltonSpreadModelDai
            .getPayFixedRegionTwoSlopeForVolatility();
        spreadModelParamsBefore.payFixedRegionTwoSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getPayFixedRegionTwoSlopeForMeanReversion();
        spreadModelParamsBefore.receiveFixedRegionOneBase = _iftMiltonSpreadModelDai.getReceiveFixedRegionOneBase();
        spreadModelParamsBefore.receiveFixedRegionOneSlopeForVolatility = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionOneSlopeForVolatility();
        spreadModelParamsBefore.receiveFixedRegionOneSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsBefore.receiveFixedRegionTwoBase = _iftMiltonSpreadModelDai.getReceiveFixedRegionTwoBase();
        spreadModelParamsBefore.receiveFixedRegionTwoSlopeForVolatility = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionTwoSlopeForVolatility();
        spreadModelParamsBefore.receiveFixedRegionTwoSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        // when
        _iftMiltonSpreadModelDai.setupModelParams(
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
        spreadModelParamsAfter.payFixedRegionOneBase = _iftMiltonSpreadModelDai.getPayFixedRegionOneBase();
        spreadModelParamsAfter.payFixedRegionOneSlopeForVolatility = _iftMiltonSpreadModelDai
            .getPayFixedRegionOneSlopeForVolatility();
        spreadModelParamsAfter.payFixedRegionOneSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getPayFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsAfter.payFixedRegionTwoBase = _iftMiltonSpreadModelDai.getPayFixedRegionTwoBase();
        spreadModelParamsAfter.payFixedRegionTwoSlopeForVolatility = _iftMiltonSpreadModelDai
            .getPayFixedRegionTwoSlopeForVolatility();
        spreadModelParamsAfter.payFixedRegionTwoSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getPayFixedRegionTwoSlopeForMeanReversion();
        spreadModelParamsAfter.receiveFixedRegionOneBase = _iftMiltonSpreadModelDai.getReceiveFixedRegionOneBase();
        spreadModelParamsAfter.receiveFixedRegionOneSlopeForVolatility = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionOneSlopeForVolatility();
        spreadModelParamsAfter.receiveFixedRegionOneSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsAfter.receiveFixedRegionTwoBase = _iftMiltonSpreadModelDai.getReceiveFixedRegionTwoBase();
        spreadModelParamsAfter.receiveFixedRegionTwoSlopeForVolatility = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionTwoSlopeForVolatility();
        spreadModelParamsAfter.receiveFixedRegionTwoSlopeForMeanReversion = _iftMiltonSpreadModelDai
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
        spreadModelParamsBefore.payFixedRegionOneBase = _iftMiltonSpreadModelDai.getPayFixedRegionOneBase();
        spreadModelParamsBefore.payFixedRegionOneSlopeForVolatility = _iftMiltonSpreadModelDai
            .getPayFixedRegionOneSlopeForVolatility();
        spreadModelParamsBefore.payFixedRegionOneSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getPayFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsBefore.payFixedRegionTwoBase = _iftMiltonSpreadModelDai.getPayFixedRegionTwoBase();
        spreadModelParamsBefore.payFixedRegionTwoSlopeForVolatility = _iftMiltonSpreadModelDai
            .getPayFixedRegionTwoSlopeForVolatility();
        spreadModelParamsBefore.payFixedRegionTwoSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getPayFixedRegionTwoSlopeForMeanReversion();
        spreadModelParamsBefore.receiveFixedRegionOneBase = _iftMiltonSpreadModelDai.getReceiveFixedRegionOneBase();
        spreadModelParamsBefore.receiveFixedRegionOneSlopeForVolatility = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionOneSlopeForVolatility();
        spreadModelParamsBefore.receiveFixedRegionOneSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsBefore.receiveFixedRegionTwoBase = _iftMiltonSpreadModelDai.getReceiveFixedRegionTwoBase();
        spreadModelParamsBefore.receiveFixedRegionTwoSlopeForVolatility = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionTwoSlopeForVolatility();
        spreadModelParamsBefore.receiveFixedRegionTwoSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        // when
        _iftMiltonSpreadModelDai.setupModelParams(
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
        spreadModelParamsAfter.payFixedRegionOneBase = _iftMiltonSpreadModelDai.getPayFixedRegionOneBase();
        spreadModelParamsAfter.payFixedRegionOneSlopeForVolatility = _iftMiltonSpreadModelDai
            .getPayFixedRegionOneSlopeForVolatility();
        spreadModelParamsAfter.payFixedRegionOneSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getPayFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsAfter.payFixedRegionTwoBase = _iftMiltonSpreadModelDai.getPayFixedRegionTwoBase();
        spreadModelParamsAfter.payFixedRegionTwoSlopeForVolatility = _iftMiltonSpreadModelDai
            .getPayFixedRegionTwoSlopeForVolatility();
        spreadModelParamsAfter.payFixedRegionTwoSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getPayFixedRegionTwoSlopeForMeanReversion();
        spreadModelParamsAfter.receiveFixedRegionOneBase = _iftMiltonSpreadModelDai.getReceiveFixedRegionOneBase();
        spreadModelParamsAfter.receiveFixedRegionOneSlopeForVolatility = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionOneSlopeForVolatility();
        spreadModelParamsAfter.receiveFixedRegionOneSlopeForMeanReversion = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        spreadModelParamsAfter.receiveFixedRegionTwoBase = _iftMiltonSpreadModelDai.getReceiveFixedRegionTwoBase();
        spreadModelParamsAfter.receiveFixedRegionTwoSlopeForVolatility = _iftMiltonSpreadModelDai
            .getReceiveFixedRegionTwoSlopeForVolatility();
        spreadModelParamsAfter.receiveFixedRegionTwoSlopeForMeanReversion = _iftMiltonSpreadModelDai
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
