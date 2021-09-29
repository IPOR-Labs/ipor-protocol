// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;
import "../libraries/types/DataTypes.sol";

interface IMiltonFrontendDataProvider {

    struct IporSpreadFront {
        address asset;
        uint256 spreadPayFixedValue;
        uint256 spreadRecFixedValue;
    }

    struct IporConfigurationFront {
        uint256 minCollateralizationValue;
        uint256 maxCollateralizationValue;
        uint256 openingFeePercentage;
        uint256 iporPublicationFeeAmount;
        uint256 liquidationDepositAmount;
        uint256 incomeTaxPercentage;
        IporSpreadFront[] spreads;
    }

    struct IporDerivativeFront {
        uint256 id;
        uint256 depositAmount;
        uint256 notionalAmount;
        uint256 collateralization;
        uint8 direction;
        uint256 fixedInterestRate;
        uint256 startingTimestamp;
        uint256 endingTimestamp;
    }

    function getMyPositions() external view returns (IporDerivativeFront[] memory items);

    function getConfiguration() external view returns (IporConfigurationFront memory iporConfiguration);
}