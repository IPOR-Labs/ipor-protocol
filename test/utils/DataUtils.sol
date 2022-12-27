// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/mocks/tokens/UsdtMockedToken.sol";
import "../../contracts/mocks/tokens/UsdcMockedToken.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/tokens/IpToken.sol";

contract DataUtils is Test {
	
	/// ---------------- MOCKED TOKENS  ----------------
	function getTokenUsdt() public returns(UsdtMockedToken) {
		UsdtMockedToken tokenUsdt =  new UsdtMockedToken(100000000000000 * 10 ** 6, 6);
		return tokenUsdt;
	}
	
	function getTokenUsdc() public returns(UsdcMockedToken) {
		UsdcMockedToken tokenUsdc =  new UsdcMockedToken(100000000000000 * 10 ** 6, 6);
		return tokenUsdc;
	}

	function getTokenDai() public returns(DaiMockedToken) {
		DaiMockedToken tokenDai =  new DaiMockedToken(10000000000000000 * Constants.D18, 18);
		return tokenDai;
	}
	/// ---------------- MOCKED TOKENS  ----------------

	/// ---------------- IP TOKENS  ----------------
	function getIpTokenUsdt(address tokenUsdt) public returns(IpToken) {
		IpToken ipTokenUsdt = new IpToken("IP USDT", "ipUSDT", tokenUsdt);
		return ipTokenUsdt;
	}

	function prepareIpTokenUsdt(IpToken ipTokenUsdt, address josephUsdt) public {
		ipTokenUsdt.setJoseph(josephUsdt);
	}

	function getIpTokenUsdc(address tokenUsdc) public returns(IpToken) {
		IpToken ipTokenUsdc = new IpToken("IP USDC", "ipUSDC", tokenUsdc);
		return ipTokenUsdc;
	}

	function prepareIpTokenUsdc(IpToken ipTokenUsdc, address josephUsdc) public {
		ipTokenUsdc.setJoseph(josephUsdc);
	}

	function getIpTokenDai(address tokenDai) public returns(IpToken) {
		IpToken ipTokenDai = new IpToken("IP DAI", "ipDAI", tokenDai);
		return ipTokenDai;
	}

	function prepareIpTokenDai(IpToken ipTokenDai, address josephDai) public {
		ipTokenDai.setJoseph(josephDai);
	}
	/// ---------------- IP TOKENS  ----------------
	
	/// ---------------- APPROVALS ----------------
	function prepareApproveForUsersUsdt(
		address[] memory users,
		UsdtMockedToken tokenUsdt,
		address josephUsdt,
		address miltonUsdt
	) public {
		for (uint256 i=0; i < users.length; ++i) {
			vm.prank(users[i]);
			tokenUsdt.approve(address(josephUsdt), 1*10**14 * 1*10**6);	// TOTAL_SUPPLY_6_DECIMALS
			vm.prank(users[i]);
			tokenUsdt.approve(address(miltonUsdt), 1*10**14 * 1*10**6); // TOTAL_SUPPLY_6_DECIMALS
			tokenUsdt.setupInitialAmount(address(users[i]), 1*10**7 * 10**6); // USER_SUPPLY_6_DECIMALS
		}
	}
	function prepareApproveForUsersUsdc(
		address[] memory users,
		UsdcMockedToken tokenUsdc,
		address josephUsdc,
		address miltonUsdc
	) public {
		for (uint256 i=0; i < users.length; ++i) {
			vm.prank(users[i]);
			tokenUsdc.approve(address(josephUsdc), 1*10**14 * 1*10**6);	// TOTAL_SUPPLY_6_DECIMALS
			vm.prank(users[i]);
			tokenUsdc.approve(address(miltonUsdc), 1*10**14 * 1*10**6); // TOTAL_SUPPLY_6_DECIMALS
			tokenUsdc.setupInitialAmount(address(users[i]), 1*10**7 * 10**6); // USER_SUPPLY_6_DECIMALS
		}
	}
	function prepareApproveForUsersDai(
		address[] memory users,
		DaiMockedToken tokenDai,
		address josephDai,
		address miltonDai
	) public {
		for (uint256 i=0; i < users.length; ++i) {
			vm.prank(users[i]);
			tokenDai.approve(address(josephDai), 1*10**16 * 1*10**18);	// TOTAL_SUPPLY_18_DECIMALS
			vm.prank(users[i]);
			tokenDai.approve(address(miltonDai), 1*10**16 * 1*10**18); // TOTAL_SUPPLY_18_DECIMALS
			tokenDai.setupInitialAmount(address(users[i]), 1*10**7 * 10**18); // USER_SUPPLY_10MLN_18DEC
		}
	}
	/// ---------------- APPROVALS ----------------
}