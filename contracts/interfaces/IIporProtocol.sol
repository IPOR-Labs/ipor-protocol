// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@ipor-protocol/contracts/interfaces/types/AmmTypes.sol";
import "@ipor-protocol/contracts/interfaces/IAmmSwapsLens.sol";
import "@ipor-protocol/contracts/interfaces/IAmmPoolsLens.sol";
import "@ipor-protocol/contracts/interfaces/IAssetManagementLens.sol";
import "@ipor-protocol/contracts/interfaces/ILiquidityMiningLens.sol";
import "@ipor-protocol/contracts/interfaces/IPowerTokenLens.sol";
import "@ipor-protocol/contracts/interfaces/IAmmOpenSwapService.sol";
import "@ipor-protocol/contracts/interfaces/IAmmCloseSwapService.sol";
import "@ipor-protocol/contracts/interfaces/IAmmPoolsService.sol";
import "@ipor-protocol/contracts/interfaces/IAmmGovernanceService.sol";
import "@ipor-protocol/contracts/interfaces/IPowerTokenStakeService.sol";
import "@ipor-protocol/contracts/interfaces/IPowerTokenFlowsService.sol";

/// @title Interface for interaction with IPOR protocol. Interface combines all IPOR protocol services and lenses.
interface IIporProtocol is
    IAmmSwapsLens,
    IAmmPoolsLens,
    IAssetManagementLens,
    ILiquidityMiningLens,
    IPowerTokenLens,
    IAmmOpenSwapService,
    IAmmCloseSwapService,
    IAmmPoolsService,
    IAmmGovernanceService,
    IPowerTokenStakeService,
    IPowerTokenFlowsService
{

}
