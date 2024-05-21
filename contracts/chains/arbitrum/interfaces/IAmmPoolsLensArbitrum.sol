// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IAmmPoolsLensArbitrum {
    function getIpTokenExchangeRate(address asset) external view returns (uint256);
}
