// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {IProvideLiquidityEvents} from "../../../interfaces/IProvideLiquidityEvents.sol";

interface IAmmPoolsServiceUsdcBaseV1 is IProvideLiquidityEvents {
    function provideLiquidityUsdcToAmmPoolUsdc(address beneficiary, uint256 assetAmount) external payable;

    function redeemFromAmmPoolUsdc(address beneficiary, uint256 ipTokenAmount) external;
}
