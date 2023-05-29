// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../utils/TestConstants.sol";
import "contracts/amm/AmmStorage.sol";
import "contracts/libraries/Constants.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/tokens/IpToken.sol";

contract DataUtils is Test {

    function getTokenUsdt() public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked USDT", "USDT", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6);
    }

    function getTokenUsdc() public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked USDC", "USDC", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6);
    }

    function getTokenDai() public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked DAI", "DAI", TestConstants.TOTAL_SUPPLY_18_DECIMALS, 18);
    }

    function getIpTokenUsdt(address tokenUsdt) public returns (IpToken) {
        return new IpToken("IP USDT", "ipUSDT", tokenUsdt);
    }

    function getIpTokenUsdc(address tokenUsdc) public returns (IpToken) {
        return new IpToken("IP USDC", "ipUSDC", tokenUsdc);
    }

    function getIpTokenDai(address tokenDai) public returns (IpToken) {
        return new IpToken("IP DAI", "ipDAI", tokenDai);
    }

    function prepareApproveForUsersUsd(
        address[] memory users,
        MockTestnetToken tokenUsd,
        address josephUsd,
        address miltonUsd
    ) public {
        for (uint256 i = 0; i < users.length; ++i) {
            vm.startPrank(users[i]);
            tokenUsd.approve(address(josephUsd), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
            tokenUsd.approve(address(miltonUsd), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
            vm.stopPrank();
            deal(address(tokenUsd), users[i], TestConstants.USER_SUPPLY_6_DECIMALS);
        }
    }

    function prepareApproveForUsersDai(
        address[] memory users,
        MockTestnetToken tokenDai,
        address josephDai,
        address miltonDai
    ) public {
        for (uint256 i = 0; i < users.length; ++i) {
            vm.startPrank(users[i]);
            tokenDai.approve(address(josephDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
            tokenDai.approve(address(miltonDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
            vm.stopPrank();
            deal(address(tokenDai), users[i], TestConstants.USER_SUPPLY_10MLN_18DEC);
        }
    }
}
