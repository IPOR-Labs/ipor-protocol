// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../contracts/amm/spread/ISpreadLens.sol";

contract MockSpreadLens is ISpreadLens {
    function getSupportedAssets() external view returns (address[] memory) {
        return new address[](0);
    }

    function getBaseSpreadConfig(address asset)
        external
        view
        returns (Spread28DaysConfigLibs.BaseSpreadConfig memory)
    {
        return
            Spread28DaysConfigLibs.BaseSpreadConfig({
                payFixedRegionOneBase: 1,
                payFixedRegionOneSlopeForVolatility: 1,
                payFixedRegionOneSlopeForMeanReversion: 1,
                payFixedRegionTwoBase: 2,
                payFixedRegionTwoSlopeForVolatility: 2,
                payFixedRegionTwoSlopeForMeanReversion: 2,
                receiveFixedRegionOneBase: 3,
                receiveFixedRegionOneSlopeForVolatility: 3,
                receiveFixedRegionOneSlopeForMeanReversion: 3,
                receiveFixedRegionTwoBase: 4,
                receiveFixedRegionTwoSlopeForVolatility: 4,
                receiveFixedRegionTwoSlopeForMeanReversion: 4
            });
    }

    function calculateBaseSpreadPayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue) {
        spreadValue = -1;
    }

    function calculateSpreadPayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue) {
        spreadValue = -2;
    }
}
