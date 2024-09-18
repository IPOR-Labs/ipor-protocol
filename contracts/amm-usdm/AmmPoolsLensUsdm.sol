// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./interfaces/IAmmPoolsLensUsdm.sol";
import "../interfaces/types/AmmTypes.sol";
import "../base/interfaces/IAmmTreasuryBaseV1.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouterEthereum.sol.
contract AmmPoolsLensUsdm is IAmmPoolsLensUsdm {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable usdm;
    address public immutable ipUsdm;
    address public immutable ammTreasuryUsdm;
    address public immutable ammStorageUsdm;
    address public immutable iporOracle;

    constructor(
        address usdmInput,
        address ipUsdmInput,
        address ammTreasuryUsdmInput,
        address ammStorageUsdmInput,
        address iporOracleInput
    ) {
        usdm = usdmInput.checkAddress();
        ipUsdm = ipUsdmInput.checkAddress();
        ammTreasuryUsdm = ammTreasuryUsdmInput.checkAddress();
        ammStorageUsdm = ammStorageUsdmInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
    }

    function getIpUsdmExchangeRate() external view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: usdm,
            assetDecimals: 18,
            ipToken: ipUsdm,
            ammStorage: ammStorageUsdm,
            ammTreasury: ammTreasuryUsdm,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryUsdm).getLiquidityPoolBalance();
        return model.getExchangeRate(liquidityPoolBalance);
    }
}
