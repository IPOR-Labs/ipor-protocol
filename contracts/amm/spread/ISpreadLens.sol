// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "./Spread28DaysConfigLibs.sol";


interface ISpreadLens {

    function getSupportedAssets() external view returns (address[] memory);

    function getBaseSpreadConfig(address asset) external view returns (Spread28DaysConfigLibs.BaseSpreadConfig memory);

}

