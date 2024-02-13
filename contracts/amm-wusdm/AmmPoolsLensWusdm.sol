// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./interfaces/IAmmPoolsLensWusdm.sol";
import "../interfaces/types/AmmTypes.sol";
import "../base/interfaces/IAmmTreasuryBaseV1.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsLensWusdm is IAmmPoolsLensWusdm {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable wusdm;
    address public immutable ipWusdm;
    address public immutable ammTreasuryWusdm;
    address public immutable ammStorageWusdm;
    address public immutable iporOracle;

    constructor(
        address wusdmInput,
        address ipWusdmInput,
        address ammTreasuryWusdmInput,
        address ammStorageWusdmInput,
        address iporOracleInput
    ) {
        wusdm = wusdmInput.checkAddress();
        ipWusdm = ipWusdmInput.checkAddress();
        ammTreasuryWusdm = ammTreasuryWusdmInput.checkAddress();
        ammStorageWusdm = ammStorageWusdmInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
    }

    function getIpWusdmExchangeRate() external view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: wusdm,
            assetDecimals: 18,
            ipToken: ipWusdm,
            ammStorage: ammStorageWusdm,
            ammTreasury: ammTreasuryWusdm,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWusdm).getLiquidityPoolBalance();
        return model.getExchangeRate(liquidityPoolBalance);
    }
}
