// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Issue is Initializable {

	uint8 private constant _DECIMALS = 10;

	function getMyDecimal() external pure returns(uint256) {
		return _DECIMALS;
	}

}