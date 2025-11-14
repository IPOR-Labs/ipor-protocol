// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import "@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1967Upgradeable.sol";
import "./IProxyImplementation.sol";
import {IRouterAccessControl} from "./IRouterAccessControl.sol";
import "./IAmmSwapsLens.sol";
import "./IAmmPoolsLens.sol";
import "./IAssetManagementLens.sol";
import "./ILiquidityMiningLens.sol";
import "./IPowerTokenLens.sol";
import "./IAmmOpenSwapService.sol";
import "./IAmmCloseSwapServiceUsdt.sol";
import "./IAmmCloseSwapServiceUsdc.sol";
import "./IAmmCloseSwapServiceDai.sol";
import "./IAmmCloseSwapServiceStEth.sol";
import "./IAmmCloseSwapLens.sol";
import "./IAmmPoolsService.sol";
import "./IAmmGovernanceService.sol";
import "./IAmmGovernanceLens.sol";
import "./IPowerTokenStakeService.sol";
import "./IPowerTokenFlowsService.sol";
import "./ISwapEventsBaseV1.sol";
import "../amm-eth/interfaces/IAmmPoolsServiceStEth.sol";
import "../amm-weEth/interfaces/IAmmPoolsServiceWeEth.sol";
import "../amm-usdm/interfaces/IAmmPoolsServiceUsdm.sol";
import "./IAmmOpenSwapServiceStEth.sol";
import "./IProvideLiquidityEvents.sol";

/// @title Interface for interaction with IPOR protocol.
/// Interface combines all IporProtocolRouter interfaces and supported services and lenses by router.
interface IIporProtocol is
    IERC1822ProxiableUpgradeable,
    IERC1967Upgradeable,
    IRouterAccessControl,
    IProxyImplementation,
    IAmmSwapsLens,
    IAmmPoolsLens,
    IAssetManagementLens,
    ILiquidityMiningLens,
    IPowerTokenLens,
    IAmmOpenSwapService,
    IAmmOpenSwapServiceStEth,
    IAmmCloseSwapServiceUsdt,
    IAmmCloseSwapServiceUsdc,
    IAmmCloseSwapServiceDai,
    IAmmCloseSwapServiceStEth,
    IAmmCloseSwapLens,
    IAmmPoolsService,
    IAmmPoolsServiceWeEth,
    IAmmGovernanceService,
    IAmmGovernanceLens,
    IPowerTokenStakeService,
    IPowerTokenFlowsService,
    IAmmPoolsServiceStEth,
    ISwapEventsBaseV1,
    IAmmPoolsServiceUsdm,
    IProvideLiquidityEvents
{

}
