// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1967Upgradeable.sol";
import "./IProxyImplementation.sol";
import "./IAmmSwapsLens.sol";
import "./IAssetManagementLens.sol";
import "./ILiquidityMiningLens.sol";
import "./IPowerTokenLens.sol";
import "./IAmmCloseSwapServiceWstEth.sol";
import "./IAmmCloseSwapLens.sol";
import "./IAmmGovernanceService.sol";
import "./IAmmGovernanceLens.sol";
import "./IPowerTokenStakeService.sol";
import "./IPowerTokenFlowsService.sol";
import "./ISwapEventsBaseV1.sol";
import "../chains/arbitrum/interfaces/IAmmPoolsServiceWstEth.sol";
import "../interfaces/IAmmOpenSwapServiceWstEth.sol";
import "./IProvideLiquidityEvents.sol";
import {IRouterAccessControl} from "./IRouterAccessControl.sol";
import {IAmmPoolsLensArbitrum} from "../chains/arbitrum/interfaces/IAmmPoolsLensArbitrum.sol";
import {IAmmGovernanceServiceArbitrum} from "../chains/arbitrum/interfaces/IAmmGovernanceServiceArbitrum.sol";
import {IAmmGovernanceLensArbitrum} from "../chains/arbitrum/interfaces/IAmmGovernanceLensArbitrum.sol";
import {IAmmPoolsServiceUsdm} from "../amm-usdm/interfaces/IAmmPoolsServiceUsdm.sol";
import {IAmmPoolsServiceUsdc} from "../chains/arbitrum/interfaces/IAmmPoolsServiceUsdc.sol";
import {IAmmOpenSwapServiceUsdc} from "../chains/arbitrum/interfaces/IAmmOpenSwapServiceUsdc.sol";
import {IAmmCloseSwapServiceUsdc} from "../interfaces/IAmmCloseSwapServiceUsdc.sol";


/// @title Interface for interaction with IPOR protocol.
/// Interface combines all IporProtocolRouter interfaces and supported services and lenses by router.
interface IIporProtocolArbitrum is
    IERC1822ProxiableUpgradeable,
    IERC1967Upgradeable,
    IRouterAccessControl,
    IProxyImplementation,
    IAmmPoolsLensArbitrum,
    IAmmSwapsLens,
    IAmmCloseSwapLens,
    IAmmGovernanceService,
    IAmmGovernanceServiceArbitrum,
    IAmmGovernanceLens,
    IAmmGovernanceLensArbitrum,
    ISwapEventsBaseV1,
    ILiquidityMiningLens,
    IPowerTokenLens,
    IPowerTokenStakeService,
    IPowerTokenFlowsService,
    IAmmPoolsServiceWstEth,
    IAmmOpenSwapServiceWstEth,
    IAmmCloseSwapServiceWstEth,
    IAmmPoolsServiceUsdm,
    IAmmPoolsServiceUsdc,
    IAmmOpenSwapServiceUsdc,
    IAmmCloseSwapServiceUsdc
{
}
