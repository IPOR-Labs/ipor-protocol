// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;
import "../libraries/types/DataTypes.sol";

interface IMiltonFrontendDataProvider {

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
}