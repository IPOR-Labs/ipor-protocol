// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../interfaces/types/MiltonFacadeTypes.sol";

interface IMiltonFacadeDataProvider {
    function getConfiguration() external returns (MiltonFacadeTypes.AssetConfiguration[] memory);

    function getBalance(address asset) external view returns (MiltonFacadeTypes.Balance memory);

    function getIpTokenExchangeRate(address asset) external view returns (uint256);

    function getMySwaps(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, MiltonFacadeTypes.IporSwap[] memory swaps);
}
