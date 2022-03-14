// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonDevToolDataProvider {
	struct AssetConfig {
		address milton;
		address miltonStorage;
		address joseph;
		address ipToken;
		address ivToken;
		
	}

    function getMyTotalSupply(address asset) external view returns (uint256);

    function getMyIpTokenBalance(address asset) external view returns (uint256);

	function getMyIvTokenBalance(address asset) external view returns (uint256);

    function getMyAllowanceInMilton(address asset)
        external
        view
        returns (uint256);

    function getMyAllowanceInJoseph(address asset)
        external
        view
        returns (uint256);

    function getSwapsPayFixed(address, address account, uint256 offset, uint256 chunkSize)
        external
        view
        returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps);

    function getSwapsReceiveFixed(address asset, address account, uint256 offset, uint256 chunkSize)
        external
        view
        returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps);

    function getMySwapsPayFixed(address asset, uint256 offset, uint256 chunkSize)
        external
        view
        returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps);

    function getMySwapsReceiveFixed(address asset, uint256 offset, uint256 chunkSize)
        external
        view
        returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps);

    function calculateSpread(address asset)
        external
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue);
}
