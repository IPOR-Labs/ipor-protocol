// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../interfaces/IJosephConfiguration.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporVault.sol";

contract JosephConfiguration is IJosephConfiguration {
    uint256 internal constant _REDEEM_LP_MAX_UTILIZATION_PERCENTAGE = 1e18;
    uint256 internal constant _IDEAL_MILTON_VAULT_REBALANCE_RATIO = 85e15;

    uint8 internal _decimals;
    address internal _asset;
    IIpToken internal _ipToken;
    IMilton internal _milton;
    IMiltonStorage internal _miltonStorage;
    IIporVault internal _iporVault;

    address internal _charlieTreasurer;
    address internal _treasureTreasurer;
    address internal _publicationFeeTransferer;

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function asset() external view override returns (address) {
        return _asset;
    }
}
