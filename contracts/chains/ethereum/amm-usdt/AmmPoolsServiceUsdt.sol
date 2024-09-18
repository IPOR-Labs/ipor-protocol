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
import {IAmmPoolsServiceUsdt} from "../interfaces/IAmmPoolsServiceUsdt.sol";
import {AmmPoolsServiceBaseV1} from "../../../base/amm/services/AmmPoolsServiceBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouterEthereum.sol.
contract AmmPoolsServiceUsdt is IAmmPoolsServiceUsdt, AmmPoolsServiceBaseV1 {
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

    /// @dev Method signature compatible with previous version
    function provideLiquidityUsdt(address beneficiary, uint256 assetAmount) external override {
        _provideLiquidity(beneficiary, assetAmount);
    }

    /// @dev Method signature compatible with previous version
    function redeemFromAmmPoolUsdt(address beneficiary, uint256 ipTokenAmount) external override {
        _redeem(beneficiary, ipTokenAmount);
    }

}
