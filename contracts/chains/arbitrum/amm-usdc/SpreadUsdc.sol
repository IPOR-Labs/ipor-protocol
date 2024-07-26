// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {SpreadBaseV2} from "../../../base/spread/SpreadBaseV2.sol";
import {DemandSpreadStableLibsBaseV1} from "../../../base/spread/DemandSpreadStableLibsBaseV1.sol";
import {SpreadTypesBaseV1} from "../../../base/types/SpreadTypesBaseV1.sol";
import {SpreadInputData} from "../../../base/interfaces/DemandSpreadTypesBaseV1.sol";

contract SpreadUsdc is SpreadBaseV2 {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address iporProtocolRouterInput,
        address assetInput,
        SpreadTypesBaseV1.TimeWeightedNotionalMemory[] memory timeWeightedNotional
    ) SpreadBaseV2(iporProtocolRouterInput, assetInput, timeWeightedNotional) {}

    function spreadFunctionConfig() external pure override returns (uint256[] memory) {
        return DemandSpreadStableLibsBaseV1.spreadFunctionConfig();
    }

    function _calculatePayFixedSpread(
        SpreadInputData memory inputData
    ) internal view override returns (uint256 spreadValue) {
        return DemandSpreadStableLibsBaseV1.calculatePayFixedSpread(inputData);
    }

    function _calculateReceiveFixedSpread(
        SpreadInputData memory inputData
    ) internal view override returns (uint256 spreadValue) {
        return DemandSpreadStableLibsBaseV1.calculateReceiveFixedSpread(inputData);
    }
}
