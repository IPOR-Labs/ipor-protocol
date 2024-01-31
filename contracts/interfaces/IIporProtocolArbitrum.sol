// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1967Upgradeable.sol";
import "./IIporContractCommonGov.sol";
import "./IProxyImplementation.sol";
import "./IAmmSwapsLens.sol";
import "./IAmmPoolsLens.sol";
import "./IAssetManagementLens.sol";
import "./ILiquidityMiningLens.sol";
import "./IPowerTokenLens.sol";
import "./IAmmCloseSwapServiceWstEth.sol";
import "./IAmmCloseSwapLens.sol";
import "./IAmmPoolsService.sol";
import "./IAmmGovernanceService.sol";
import "./IAmmGovernanceLens.sol";
import "./IPowerTokenStakeService.sol";
import "./IPowerTokenFlowsService.sol";
import "./ISwapEventsBaseV1.sol";
import "../amm-eth/interfaces/IAmmPoolsLensWstEth.sol";
import "../amm-eth/interfaces/IAmmPoolsServiceWstEth.sol";
import "../interfaces/IAmmOpenSwapServiceWstEth.sol";

/// @title Interface for interaction with IPOR protocol.
/// Interface combines all IporProtocolRouter interfaces and supported services and lenses by router.
interface IIporProtocolArbitrum is
    IERC1822ProxiableUpgradeable,
    IERC1967Upgradeable,
    IIporContractCommonGov,
    IProxyImplementation,
    IAmmSwapsLens,
    IAmmCloseSwapLens,
    IAmmGovernanceService,
    IAmmGovernanceLens,
    ISwapEventsBaseV1,
    ILiquidityMiningLens,
    IPowerTokenLens,
    IPowerTokenStakeService,
    IPowerTokenFlowsService,
    IAmmPoolsServiceWstEth,
    IAmmPoolsLensWstEth,
    IAmmOpenSwapServiceWstEth,
    IAmmCloseSwapServiceWstEth
{
}
