// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IJoseph {
	function decimals() external view returns (uint8);
	function asset() external view returns (address);
	function getIporConfiguration() external view returns(address);
	function getIporAssetConfiguration() external view returns(address);
    function provideLiquidity(uint256 liquidityAmount) external;

    function redeem(uint256 ipTokenVolume) external;
}
