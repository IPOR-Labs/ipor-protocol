// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract MockPlasmaVault is ERC4626 {
    constructor(IERC20 underlyingAsset, string memory assetName, string memory assetSymbol)
        ERC4626(underlyingAsset) ERC20(assetName, assetSymbol) {}
}