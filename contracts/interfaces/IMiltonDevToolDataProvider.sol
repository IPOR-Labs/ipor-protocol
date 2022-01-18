// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonDevToolDataProvider {
    function getMyTotalSupply(address asset) external view returns (uint256);

    function getMyIpTokenBalance(address asset) external view returns (uint256);

    function getMyAllowanceInMilton(address asset)
        external
        view
        returns (uint256);

    function getMyAllowanceInJoseph(address asset)
        external
        view
        returns (uint256);

    function getSwapsPayFixed(address asset)
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory);

		function getSwapsReceiveFixed(address asset)
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory);

    function getMySwapsPayFixed(address asset)
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory items);

		function getMySwapsReceiveFixed(address asset)
        external
        view
        returns (DataTypes.IporDerivativeMemory[] memory items);
}
