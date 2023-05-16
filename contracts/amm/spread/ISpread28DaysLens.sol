// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Spread28DaysConfigLibs.sol";
import "../../interfaces/types/IporTypes.sol";


interface ISpread28DaysLens {

    function getSupportedAssets() external view returns (address[] memory);

    function calculateBaseSpreadPayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) external view returns (int256 spreadValue);

    function calculateSpreadPayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) external view returns (int256 spreadValue);

    function SpreadFunction28DaysConfig() public pure returns (uint256[20] memory);

}

