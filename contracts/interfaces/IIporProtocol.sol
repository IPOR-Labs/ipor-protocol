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
import "./IAmmOpenSwapService.sol";
import "./IAmmCloseSwapService.sol";
import "./IAmmPoolsService.sol";
import "./IAmmGovernanceService.sol";
import "./IPowerTokenStakeService.sol";
import "./IPowerTokenFlowsService.sol";
import "../amm-eth/interfaces/IAmmPoolsLensEth.sol";
import "../amm-eth/interfaces/IAmmPoolsServiceEth.sol";

/// @title Interface for interaction with IPOR protocol.
/// Interface combines all IporProtocolRouter interfaces and supported services and lenses by router.
interface IIporProtocol is
    IERC1822ProxiableUpgradeable,
    IERC1967Upgradeable,
    IIporContractCommonGov,
    IProxyImplementation,
    IAmmSwapsLens,
    IAmmPoolsLens,
    IAssetManagementLens,
    ILiquidityMiningLens,
    IPowerTokenLens,
    IAmmPoolsLensEth,
    IAmmOpenSwapService,
    IAmmCloseSwapService,
    IAmmPoolsService,
    IAmmGovernanceService,
    IPowerTokenStakeService,
    IPowerTokenFlowsService,
    IAmmPoolsServiceEth
{

}
