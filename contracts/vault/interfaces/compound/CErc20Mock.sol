// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface CErc20Mock {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function redeem(uint256) external returns (uint256);
}
