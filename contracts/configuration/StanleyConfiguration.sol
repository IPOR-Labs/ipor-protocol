// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IStanleyConfiguration.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IWarren.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IStanley.sol";
import "../security/IporOwnableUpgradeable.sol";

contract StanleyConfiguration is
    PausableUpgradeable,
    IporOwnableUpgradeable,
    IStanleyConfiguration
{}
