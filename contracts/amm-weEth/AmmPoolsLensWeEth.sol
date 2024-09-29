// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "./interfaces/IAmmPoolsLensWeEth.sol";
import "../interfaces/types/AmmTypes.sol";
import "../base/interfaces/IAmmTreasuryBaseV1.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsLensWeEth is IAmmPoolsLensWeEth {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable weEth;
    address public immutable ipWeEth;
    address public immutable ammTreasuryWeEth;
    address public immutable ammStorageWeEth;
    address public immutable iporOracle;

    constructor(
        address weEthInput,
        address ipWeEthInput,
        address ammTreasuryWeEthInput,
        address ammStorageWeEthInput,
        address iporOracleInput
    ) {
        weEth = weEthInput.checkAddress();
        ipWeEth = ipWeEthInput.checkAddress();
        ammTreasuryWeEth = ammTreasuryWeEthInput.checkAddress();
        ammStorageWeEth = ammStorageWeEthInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
    }

    function getIpWeEthExchangeRate() external view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: weEth,
            assetDecimals: 18,
            ipToken: ipWeEth,
            ammStorage: ammStorageWeEth,
            ammTreasury: ammTreasuryWeEth,
            assetManagement: address(0),
            iporOracle: iporOracle
        });
        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasuryWeEth).getLiquidityPoolBalance();
        return model.getExchangeRate(liquidityPoolBalance);
    }
}
