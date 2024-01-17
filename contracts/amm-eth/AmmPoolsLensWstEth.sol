// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./interfaces/IAmmPoolsLensWstEth.sol";
import "../interfaces/types/AmmTypes.sol";
import "../base/interfaces/IAmmTreasuryBaseV1.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsLensWstEth is IAmmPoolsLensWstEth {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable wstEth;
    address public immutable ipwstEth;
    address public immutable ammTreasuryWstEth;
    address public immutable ammStorageWstEth;
    address public immutable iporOracle;

    constructor(
        address wstEthInput,
        address ipwstEthInput,
        address ammTreasuryWstEthInput,
        address ammStorageWstEthInput,
        address iporOracleInput
    ) {
        wstEth = wstEthInput.checkAddress();
        ipwstEth = ipwstEthInput.checkAddress();
        ammTreasuryWstEth = ammTreasuryWstEthInput.checkAddress();
        ammStorageWstEth = ammStorageWstEthInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
    }

    function getIpwstEthExchangeRate() external view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: wstEth,
            assetDecimals: 18,
            ipToken: ipwstEth,
            ammStorage: ammStorageWstEth,
            ammTreasury: ammTreasuryWstEth,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWstEth).getLiquidityPoolBalance();
        return model.getExchangeRate(liquidityPoolBalance);
    }
}
