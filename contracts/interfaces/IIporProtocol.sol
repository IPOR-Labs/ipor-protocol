// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "contracts/interfaces/types/AmmTypes.sol";
import "contracts/interfaces/IAmmSwapsLens.sol";
import "contracts/interfaces/IAmmPoolsLens.sol";
import "contracts/interfaces/IAssetManagementLens.sol";
import "contracts/interfaces/ILiquidityMiningLens.sol";
import "contracts/interfaces/IPowerTokenLens.sol";
import "contracts/interfaces/IAmmOpenSwapService.sol";
import "contracts/interfaces/IAmmCloseSwapService.sol";
import "contracts/interfaces/IAmmPoolsService.sol";
import "contracts/interfaces/IAmmGovernanceService.sol";
import "contracts/interfaces/IPowerTokenStakeService.sol";
import "contracts/interfaces/IPowerTokenFlowsService.sol";

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
