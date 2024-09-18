// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./interfaces/IAmmPoolsLensStEth.sol";
import "../interfaces/types/AmmTypes.sol";
import "../base/interfaces/IAmmTreasuryBaseV1.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouterEthereum.sol.
contract AmmPoolsLensStEth is IAmmPoolsLensStEth {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable stEth;
    address public immutable ipstEth;
    address public immutable ammTreasuryStEth;
    address public immutable ammStorageStEth;
    address public immutable iporOracle;

    constructor(
        address stEthInput,
        address ipstEthInput,
        address ammTreasuryStEthInput,
        address ammStorageStEthInput,
        address iporOracleInput
    ) {
        stEth = stEthInput.checkAddress();
        ipstEth = ipstEthInput.checkAddress();
        ammTreasuryStEth = ammTreasuryStEthInput.checkAddress();
        ammStorageStEth = ammStorageStEthInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
    }

    function getIpstEthExchangeRate() external view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: stEth,
            assetDecimals: 18,
            ipToken: ipstEth,
            ammStorage: ammStorageStEth,
            ammTreasury: ammTreasuryStEth,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryStEth).getLiquidityPoolBalance();
        return model.getExchangeRate(liquidityPoolBalance);
    }
}
