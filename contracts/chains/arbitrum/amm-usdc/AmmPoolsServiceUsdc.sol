// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../libraries/AmmLib.sol";
import {IAmmPoolsServiceUsdc} from "../interfaces/IAmmPoolsServiceUsdc.sol";
import {AmmPoolsServiceBaseV1} from "../../../base/amm/services/AmmPoolsServiceBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceUsdc is IAmmPoolsServiceUsdc, AmmPoolsServiceBaseV1 {
    constructor(
        address asset_,
        address ipToken_,
        address ammTreasury_,
        address ammStorage_,
        address ammAssetManagement_,
        address iporOracle_,
        address iporProtocolRouter_,
        uint256 redeemFeeRate_,
        uint256 autoRebalanceThresholdMultiplier_
    )
        AmmPoolsServiceBaseV1(
            asset_,
            ipToken_,
            ammTreasury_,
            ammStorage_,
            ammAssetManagement_,
            iporOracle_,
            iporProtocolRouter_,
            redeemFeeRate_,
            autoRebalanceThresholdMultiplier_
        )
    {}

    function provideLiquidityUsdcToAmmPoolUsdc(address beneficiary, uint256 assetAmount) external payable override {
        _provideLiquidity(beneficiary, assetAmount);
    }

    function redeemFromAmmPoolUsdc(address beneficiary, uint256 ipTokenAmount) external {
        _redeem(beneficiary, ipTokenAmount);
    }
}
