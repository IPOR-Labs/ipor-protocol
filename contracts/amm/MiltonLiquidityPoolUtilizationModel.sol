// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../libraries/Constants.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLiquidityPoolUtilizationModel.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import {IporMath} from "../libraries/IporMath.sol";
import {IporErrors} from "../IporErrors.sol";

//@notice Milton utilization strategy which - for simplification - is based on Collateral
//(collateral is a total balance of derivatives in Milton)
contract MiltonLiquidityPoolUtilizationModel is
	UUPSUpgradeable,
    OwnableUpgradeable,    
    IMiltonLiquidityPoolUtilizationModel
{
    function initialize() public initializer {
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function calculateUtilizationRate(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralBalance,
        uint256 collateral,
        uint256 openingFee
    ) external pure override returns (uint256) {
        if ((liquidityPoolBalance + openingFee) != 0) {
            return
                IporMath.division(
                    (totalCollateralBalance + collateral) * Constants.D18,
                    liquidityPoolBalance + openingFee
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }
}
