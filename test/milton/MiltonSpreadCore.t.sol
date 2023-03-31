// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdt.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdc.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelDai.sol";

contract MiltonSpreadCoreTest is Test, TestCommons {
    function testShouldReturnProperConstantForUsdt() public {
        // given
        MockBaseMiltonSpreadModelUsdt _miltonSpread = new MockBaseMiltonSpreadModelUsdt();
        // when
        int256 payFixedRegionOneBase = _miltonSpread.getPayFixedRegionOneBase();
        int256 payFixedRegionOneSlopeForVolatility = _miltonSpread
            .getPayFixedRegionOneSlopeForVolatility();
        int256 payFixedRegionOneSlopeForMeanReversion = _miltonSpread
            .getPayFixedRegionOneSlopeForMeanReversion();
        int256 payFixedRegionTwoBase = _miltonSpread.getPayFixedRegionTwoBase();
        int256 payFixedRegionTwoSlopeForVolatility = _miltonSpread
            .getPayFixedRegionTwoSlopeForVolatility();
        int256 payFixedRegionTwoSlopeForMeanReversion = _miltonSpread
            .getPayFixedRegionTwoSlopeForMeanReversion();
        int256 receiveFixedRegionOneBase = _miltonSpread.getReceiveFixedRegionOneBase();
        int256 receiveFixedRegionOneSlopeForVolatility = _miltonSpread
            .getReceiveFixedRegionOneSlopeForVolatility();
        int256 receiveFixedRegionOneSlopeForMeanReversion = _miltonSpread
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        int256 receiveFixedRegionTwoBase = _miltonSpread.getReceiveFixedRegionTwoBase();
        int256 receiveFixedRegionTwoSlopeForVolatility = _miltonSpread
            .getReceiveFixedRegionTwoSlopeForVolatility();
        int256 receiveFixedRegionTwoSlopeForMeanReversion = _miltonSpread
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        // then
        assertEq(payFixedRegionOneBase, 3663986060872150);
        assertEq(payFixedRegionOneSlopeForVolatility, 51167356261242142720);
        assertEq(payFixedRegionOneSlopeForMeanReversion, -1091077232860706176);
        assertEq(payFixedRegionTwoBase, 250000000000000);
        assertEq(payFixedRegionTwoSlopeForVolatility, 12500000093283319808);
        assertEq(payFixedRegionTwoSlopeForMeanReversion, 0);
        assertEq(receiveFixedRegionOneBase, -422356983119848);
        assertEq(receiveFixedRegionOneSlopeForVolatility, -3072419563759);
        assertEq(receiveFixedRegionOneSlopeForMeanReversion, -1037292358695855104);
        assertEq(receiveFixedRegionTwoBase, -250000000000000);
        assertEq(receiveFixedRegionTwoSlopeForVolatility, -12500447141509146624);
        assertEq(receiveFixedRegionTwoSlopeForMeanReversion, 0);
    }

    function testShouldReturnProperConstantForUsdc() public {
        // given
        MockBaseMiltonSpreadModelUsdc _miltonSpread = new MockBaseMiltonSpreadModelUsdc();
        // when
        int256 payFixedRegionOneBase = _miltonSpread.getPayFixedRegionOneBase();
        int256 payFixedRegionOneSlopeForVolatility = _miltonSpread
            .getPayFixedRegionOneSlopeForVolatility();
        int256 payFixedRegionOneSlopeForMeanReversion = _miltonSpread
            .getPayFixedRegionOneSlopeForMeanReversion();
        int256 payFixedRegionTwoBase = _miltonSpread.getPayFixedRegionTwoBase();
        int256 payFixedRegionTwoSlopeForVolatility = _miltonSpread
            .getPayFixedRegionTwoSlopeForVolatility();
        int256 payFixedRegionTwoSlopeForMeanReversion = _miltonSpread
            .getPayFixedRegionTwoSlopeForMeanReversion();
        int256 receiveFixedRegionOneBase = _miltonSpread.getReceiveFixedRegionOneBase();
        int256 receiveFixedRegionOneSlopeForVolatility = _miltonSpread
            .getReceiveFixedRegionOneSlopeForVolatility();
        int256 receiveFixedRegionOneSlopeForMeanReversion = _miltonSpread
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        int256 receiveFixedRegionTwoBase = _miltonSpread.getReceiveFixedRegionTwoBase();
        int256 receiveFixedRegionTwoSlopeForVolatility = _miltonSpread
            .getReceiveFixedRegionTwoSlopeForVolatility();
        int256 receiveFixedRegionTwoSlopeForMeanReversion = _miltonSpread
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        // then
        assertEq(payFixedRegionOneBase, 246221635508210);
        assertEq(payFixedRegionOneSlopeForVolatility, 7175545968273476608);
        assertEq(payFixedRegionOneSlopeForMeanReversion, -998967008815501824);
        assertEq(payFixedRegionTwoBase, 250000000000000);
        assertEq(payFixedRegionTwoSlopeForVolatility, 600000002394766180352);
        assertEq(payFixedRegionTwoSlopeForMeanReversion, 0);
        assertEq(receiveFixedRegionOneBase, -250000000201288);
        assertEq(receiveFixedRegionOneSlopeForVolatility, -2834673328995);
        assertEq(receiveFixedRegionOneSlopeForMeanReversion, 999999997304907264);
        assertEq(receiveFixedRegionTwoBase, -250000000000000);
        assertEq(receiveFixedRegionTwoSlopeForVolatility, -600000000289261748224);
        assertEq(receiveFixedRegionTwoSlopeForMeanReversion, 0);
    }

    function testShouldReturnProperConstantForDai() public {
        // given
        MockBaseMiltonSpreadModelDai _miltonSpread = new MockBaseMiltonSpreadModelDai();
        // when
        int256 payFixedRegionOneBase = _miltonSpread.getPayFixedRegionOneBase();
        int256 payFixedRegionOneSlopeForVolatility = _miltonSpread
            .getPayFixedRegionOneSlopeForVolatility();
        int256 payFixedRegionOneSlopeForMeanReversion = _miltonSpread
            .getPayFixedRegionOneSlopeForMeanReversion();
        int256 payFixedRegionTwoBase = _miltonSpread.getPayFixedRegionTwoBase();
        int256 payFixedRegionTwoSlopeForVolatility = _miltonSpread
            .getPayFixedRegionTwoSlopeForVolatility();
        int256 payFixedRegionTwoSlopeForMeanReversion = _miltonSpread
            .getPayFixedRegionTwoSlopeForMeanReversion();
        int256 receiveFixedRegionOneBase = _miltonSpread.getReceiveFixedRegionOneBase();
        int256 receiveFixedRegionOneSlopeForVolatility = _miltonSpread
            .getReceiveFixedRegionOneSlopeForVolatility();
        int256 receiveFixedRegionOneSlopeForMeanReversion = _miltonSpread
            .getReceiveFixedRegionOneSlopeForMeanReversion();
        int256 receiveFixedRegionTwoBase = _miltonSpread.getReceiveFixedRegionTwoBase();
        int256 receiveFixedRegionTwoSlopeForVolatility = _miltonSpread
            .getReceiveFixedRegionTwoSlopeForVolatility();
        int256 receiveFixedRegionTwoSlopeForMeanReversion = _miltonSpread
            .getReceiveFixedRegionTwoSlopeForMeanReversion();
        // then
        assertEq(payFixedRegionOneBase, 310832623606789);
        assertEq(payFixedRegionOneSlopeForVolatility, 5904923680478814208);
        assertEq(payFixedRegionOneSlopeForMeanReversion, -1068281996426492416);
        assertEq(payFixedRegionTwoBase, 250000000000000);
        assertEq(payFixedRegionTwoSlopeForVolatility, 300000016093683515392);
        assertEq(payFixedRegionTwoSlopeForMeanReversion, 0);
        assertEq(receiveFixedRegionOneBase, -250000000214678);
        assertEq(receiveFixedRegionOneSlopeForVolatility, -3289616086609);
        assertEq(receiveFixedRegionOneSlopeForMeanReversion, 999999996306855424);
        assertEq(receiveFixedRegionTwoBase, -250000000000000);
        assertEq(receiveFixedRegionTwoSlopeForVolatility, -300000000394754064384);
        assertEq(receiveFixedRegionTwoSlopeForMeanReversion, 0);
    }
}
