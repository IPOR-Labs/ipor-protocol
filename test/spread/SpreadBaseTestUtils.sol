// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../contracts/amm/spread/Spread28DaysConfigLibs.sol";
import "../TestCommons.sol";

abstract contract SpreadBaseTestUtils is TestCommons {
    address internal _dai;
    address internal _usdc;
    address internal _usdt;

    struct SpreadBaseConfigTestDataForTest {
        address asset;
        string assetName;
        Spread28DaysConfigLibs.BaseSpreadConfig expectedBaseSpreadConfig;
    }

    SpreadBaseConfigTestDataForTest internal _spreadBaseConfigTestData;

    modifier parameterizedSpreadBaseDataTest(SpreadBaseConfigTestDataForTest[] memory testSets) {
        uint256 length = testSets.length;
        for (uint256 i = 0; i < length; ) {
            _spreadBaseConfigTestData = testSets[i];
            _;
            unchecked {
                i += 1;
            }
        }
    }

    function _getSpreadBaseConfigTestData()
        internal
        returns (SpreadBaseConfigTestDataForTest[] memory)
    {
        SpreadBaseConfigTestDataForTest[] memory testSets = new SpreadBaseConfigTestDataForTest[](
            3
        );
        testSets[0] = SpreadBaseConfigTestDataForTest({
            asset: _dai,
            assetName: "dai",
            expectedBaseSpreadConfig: Spread28DaysConfigLibs._getBaseSpreadDaiConfig()
        });
        testSets[1] = SpreadBaseConfigTestDataForTest({
            asset: _usdc,
            assetName: "usdc",
            expectedBaseSpreadConfig: Spread28DaysConfigLibs._getBaseSpreadUsdcConfig()
        });
        testSets[2] = SpreadBaseConfigTestDataForTest({
            asset: _usdt,
            assetName: "usdt",
            expectedBaseSpreadConfig: Spread28DaysConfigLibs._getBaseSpreadUsdtConfig()
        });
        return testSets;
    }

    function _assertSpreadBaseConfig(
        Spread28DaysConfigLibs.BaseSpreadConfig memory expectedBaseSpreadConfig,
        Spread28DaysConfigLibs.BaseSpreadConfig memory actualBaseSpreadConfig,
        string memory assetName
    ) internal {
        assertEq(
            expectedBaseSpreadConfig.payFixedRegionOneBase,
            actualBaseSpreadConfig.payFixedRegionOneBase,
            string.concat(assetName, ": payFixedRegionOneBase should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.payFixedRegionOneSlopeForVolatility,
            actualBaseSpreadConfig.payFixedRegionOneSlopeForVolatility,
            string.concat(assetName, ":payFixedRegionOneSlopeForVolatility should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.payFixedRegionOneSlopeForMeanReversion,
            actualBaseSpreadConfig.payFixedRegionOneSlopeForMeanReversion,
            string.concat(assetName, ": payFixedRegionOneSlopeForMeanReversion should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.payFixedRegionOneSlopeForMeanReversion,
            actualBaseSpreadConfig.payFixedRegionOneSlopeForMeanReversion,
            string.concat(assetName, ": payFixedRegionOneSlopeForMeanReversion should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.payFixedRegionTwoBase,
            actualBaseSpreadConfig.payFixedRegionTwoBase,
            string.concat(assetName, ": payFixedRegionTwoBase should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.payFixedRegionTwoSlopeForVolatility,
            actualBaseSpreadConfig.payFixedRegionTwoSlopeForVolatility,
            string.concat(assetName, ": payFixedRegionTwoSlopeForVolatility should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.payFixedRegionTwoSlopeForMeanReversion,
            actualBaseSpreadConfig.payFixedRegionTwoSlopeForMeanReversion,
            string.concat(assetName, ": payFixedRegionTwoSlopeForMeanReversion should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.receiveFixedRegionOneBase,
            actualBaseSpreadConfig.receiveFixedRegionOneBase,
            string.concat(assetName, ": receiveFixedRegionOneBase should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.receiveFixedRegionOneSlopeForVolatility,
            actualBaseSpreadConfig.receiveFixedRegionOneSlopeForVolatility,
            string.concat(assetName, ": receiveFixedRegionOneSlopeForVolatility should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.receiveFixedRegionOneSlopeForMeanReversion,
            actualBaseSpreadConfig.receiveFixedRegionOneSlopeForMeanReversion,
            string.concat(
                assetName,
                ": receiveFixedRegionOneSlopeForMeanReversion should be the same"
            )
        );
        assertEq(
            expectedBaseSpreadConfig.receiveFixedRegionTwoBase,
            actualBaseSpreadConfig.receiveFixedRegionTwoBase,
            string.concat(assetName, ": receiveFixedRegionTwoBase should be the same")
        );
        assertEq(
            expectedBaseSpreadConfig.receiveFixedRegionTwoSlopeForVolatility,
            actualBaseSpreadConfig.receiveFixedRegionTwoSlopeForVolatility,
            string.concat(assetName, ": receiveFixedRegionTwoSlopeForVolatility should be the same")
        );
    }
}
