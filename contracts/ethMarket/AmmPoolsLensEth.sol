// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./AmmLibEth.sol";
import "../libraries/IporContractValidator.sol";
import "./IAmmPoolsLensEth.sol";

contract AmmPoolsLensEth is IAmmPoolsLensEth {
    using IporContractValidator for address;

    address public immutable stEth;
    address public immutable wEth;
    address public immutable ipstEth;
    address public immutable ammTreasuryEth;

    constructor(
        address stEthInput,
        address wEthInput,
        address ipstEthInput,
        address ammTreasuryEthInput
    ) {
        stEth = stEthInput.checkAddress();
        wEth = wEthInput.checkAddress();
        ipstEth = ipstEthInput.checkAddress();
        ammTreasuryEth = ammTreasuryEthInput.checkAddress();
    }

    function getIpstEthExchangeRate() external view returns (uint256) {
        return AmmLibEth.getExchangeRate(stEth, ammTreasuryEth, ipstEth);
    }
}
