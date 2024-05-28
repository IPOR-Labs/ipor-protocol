// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../interfaces/IIpToken.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/StorageLib.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmLib.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV1.sol";
import {IAmmPoolsServiceUsdc} from "../interfaces/IAmmPoolsServiceUsdc.sol";
import {AmmPoolsServiceBaseV1} from "../../../base/amm/services/AmmPoolsServiceBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceUsdc is IAmmPoolsServiceUsdc, AmmPoolsServiceBaseV1 {
    constructor(
        address asset_,
        address ipToken_,
        address ammTreasury_,
        address ammStorage_,
        address ammVault_,
        address iporOracle_,
        address iporProtocolRouter_,
        uint256 redeemFeeRate_,
        uint256 autoRebalanceThresholdMultiplier_
    ) AmmPoolsServiceBaseV1(asset_, ipToken_, ammTreasury_, ammStorage_, ammVault_, iporOracle_, iporProtocolRouter_, redeemFeeRate_, autoRebalanceThresholdMultiplier_) {
    }

    function provideLiquidityUsdcToAmmPoolUsdc(address beneficiary, uint256 assetAmount) external payable override {
        _provideLiquidity(beneficiary, assetAmount);
    }

    function redeemFromAmmPoolUsdc(address beneficiary, uint256 ipTokenAmount) external {
        _redeem(beneficiary, ipTokenAmount);
    }
}
