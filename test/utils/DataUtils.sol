// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../utils/TestConstants.sol";
import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/tokens/IpToken.sol";

contract DataUtils is Test, IporOracleUtils, MiltonUtils, MiltonStorageUtils, JosephUtils, StanleyUtils {
    /// ---------------- MOCKED TOKENS  ----------------
    function getTokenUsdt() public returns (MockTestnetTokenUsdt) {
        MockTestnetTokenUsdt tokenUsdt = new MockTestnetTokenUsdt(TestConstants.TOTAL_SUPPLY_6_DECIMALS);
        return tokenUsdt;
    }

    function getTokenUsdc() public returns (MockTestnetTokenUsdc) {
        MockTestnetTokenUsdc tokenUsdc = new MockTestnetTokenUsdc(TestConstants.TOTAL_SUPPLY_6_DECIMALS);
        return tokenUsdc;
    }

    function getTokenDai() public returns (MockTestnetTokenDai) {
        MockTestnetTokenDai tokenDai = new MockTestnetTokenDai(TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        return tokenDai;
    }

    function getTokenAddresses(address tokenUsdt, address tokenUsdc, address tokenDai)
        public
        pure
        returns (address[] memory)
    {
        address[] memory tokenAddresses = new address[](3);
        tokenAddresses[0] = tokenUsdt;
        tokenAddresses[1] = tokenUsdc;
        tokenAddresses[2] = tokenDai;
        return tokenAddresses;
    }
    /// ---------------- MOCKED TOKENS  ----------------

    /// ---------------- IP TOKENS  ----------------
    function getIpTokenUsdt(address tokenUsdt) public returns (IpToken) {
        IpToken ipTokenUsdt = new IpToken("IP USDT", "ipUSDT", tokenUsdt);
        return ipTokenUsdt;
    }

    function prepareIpTokenUsdt(IpToken ipTokenUsdt, address josephUsdt) public {
        ipTokenUsdt.setJoseph(josephUsdt);
    }

    function getIpTokenUsdc(address tokenUsdc) public returns (IpToken) {
        IpToken ipTokenUsdc = new IpToken("IP USDC", "ipUSDC", tokenUsdc);
        return ipTokenUsdc;
    }

    function prepareIpTokenUsdc(IpToken ipTokenUsdc, address josephUsdc) public {
        ipTokenUsdc.setJoseph(josephUsdc);
    }

    function getIpTokenDai(address tokenDai) public returns (IpToken) {
        IpToken ipTokenDai = new IpToken("IP DAI", "ipDAI", tokenDai);
        return ipTokenDai;
    }

    function prepareIpTokenDai(IpToken ipTokenDai, address josephDai) public {
        ipTokenDai.setJoseph(josephDai);
    }

    function getIpTokenAddresses(address ipTokenUsdt, address ipTokenUsdc, address ipTokenDai)
        public
        pure
        returns (address[] memory)
    {
        address[] memory ipTokenAddresses = new address[](3);
        ipTokenAddresses[0] = ipTokenUsdt;
        ipTokenAddresses[1] = ipTokenUsdc;
        ipTokenAddresses[2] = ipTokenDai;
        return ipTokenAddresses;
    }

    /// ---------------- IP TOKENS  ----------------

    /// ---------------- APPROVALS ----------------
    function prepareApproveForUsersUsdt(
        address[] memory users,
        MockTestnetTokenUsdt tokenUsdt,
        address josephUsdt,
        address miltonUsdt
    ) public {
        for (uint256 i = 0; i < users.length; ++i) {
            vm.prank(users[i]);
            tokenUsdt.approve(address(josephUsdt), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
            vm.prank(users[i]);
            tokenUsdt.approve(address(miltonUsdt), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
            deal(address(tokenUsdt), users[i], TestConstants.USER_SUPPLY_6_DECIMALS);
        }
    }

    function prepareApproveForUsersUsdc(
        address[] memory users,
        MockTestnetTokenUsdc tokenUsdc,
        address josephUsdc,
        address miltonUsdc
    ) public {
        for (uint256 i = 0; i < users.length; ++i) {
            vm.prank(users[i]);
            tokenUsdc.approve(address(josephUsdc), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
            vm.prank(users[i]);
            tokenUsdc.approve(address(miltonUsdc), TestConstants.TOTAL_SUPPLY_6_DECIMALS);
            deal(address(tokenUsdc), users[i], TestConstants.USER_SUPPLY_6_DECIMALS);
        }
    }

    function prepareApproveForUsersDai(
        address[] memory users,
        MockTestnetTokenDai tokenDai,
        address josephDai,
        address miltonDai
    ) public {
        for (uint256 i = 0; i < users.length; ++i) {
            vm.prank(users[i]);
            tokenDai.approve(address(josephDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
            vm.prank(users[i]);
            tokenDai.approve(address(miltonDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
            deal(address(tokenDai), users[i], TestConstants.USER_SUPPLY_10MLN_18DEC);
        }
    }
    /// ---------------- APPROVALS ----------------

    /// ---------------- USERS ----------------
    function getFiveUsers(address userOne, address userTwo, address userThree, address userFour, address userFive)
        public
        pure
        returns (address[] memory)
    {
        address[] memory users = new address[](5);
        users[0] = userOne;
        users[1] = userTwo;
        users[2] = userThree;
        users[3] = userFour;
        users[4] = userFive;
        return users;
    }

    function getSixUsers(
        address userOne,
        address userTwo,
        address userThree,
        address userFour,
        address userFive,
        address userSix
    ) public pure returns (address[] memory) {
        address[] memory users = new address[](5);
        users[0] = userOne;
        users[1] = userTwo;
        users[2] = userThree;
        users[3] = userFour;
        users[4] = userFive;
        users[5] = userSix;
        return users;
    }
    /// ---------------- USERS ----------------
}
