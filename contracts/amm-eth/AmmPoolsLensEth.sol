// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./AmmLibEth.sol";
import "../libraries/IporContractValidator.sol";
import "./interfaces/IAmmPoolsLensEth.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsLensEth is IAmmPoolsLensEth {
    using IporContractValidator for address;

    address public immutable stEth;
    address public immutable ipstEth;
    address public immutable ammTreasuryEth;

    constructor(address stEthInput, address ipstEthInput, address ammTreasuryEthInput) {
        stEth = stEthInput.checkAddress();
        ipstEth = ipstEthInput.checkAddress();
        ammTreasuryEth = ammTreasuryEthInput.checkAddress();
    }

    function getIpstEthExchangeRate() external view returns (uint256) {
        return AmmLibEth.getExchangeRate(stEth, ipstEth, ammTreasuryEth);
    }
}
