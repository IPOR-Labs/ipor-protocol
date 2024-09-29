// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

interface IAmmPoolsLensArbitrum {
    function getIpTokenExchangeRate(address asset) external view returns (uint256);
}
