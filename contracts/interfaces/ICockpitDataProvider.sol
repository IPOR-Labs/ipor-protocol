// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface ICockpitDataProvider {
    struct AssetConfig {
        address milton;
        address miltonStorage;
        address joseph;
        address ipToken;
        address ivToken;
    }
    struct IporFront {
        //@notice Asset Symbol like USDT, USDC, DAI etc.
        string asset;
        //@notice IPOR Index Value
        uint256 indexValue;
        //@notice Interest Bearing Token Price
        uint256 ibtPrice;
        //@notice exponential moving average
        uint256 exponentialMovingAverage;
        uint256 exponentialWeightedMovingVariance;
        //@notice block timestamp
        uint256 blockTimestamp;
    }

    function getIndexes() external view returns (IporFront[] memory);	

    function getMyTotalSupply(address asset) external view returns (uint256);

    function getMyIpTokenBalance(address asset) external view returns (uint256);

    function getMyIvTokenBalance(address asset) external view returns (uint256);

    function getMyAllowanceInMilton(address asset) external view returns (uint256);

    function getMyAllowanceInJoseph(address asset) external view returns (uint256);

    function getSwapsPayFixed(
        address,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps);

    function getSwapsReceiveFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps);

    function getMySwapsPayFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps);

    function getMySwapsReceiveFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps);

    function calculateSpread(address asset)
        external
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue);
}
