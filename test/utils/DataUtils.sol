// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/tokens/IpToken.sol";

contract DataUtils is Test {
    /// ---------------- MOCKED TOKENS  ----------------
    function getTokenUsdt() public returns (MockTestnetTokenUsdt) {
        MockTestnetTokenUsdt tokenUsdt = new MockTestnetTokenUsdt(100000000000000 * 10**6);
        return tokenUsdt;
    }

    function getTokenUsdc() public returns (MockTestnetTokenUsdc) {
        MockTestnetTokenUsdc tokenUsdc = new MockTestnetTokenUsdc(100000000000000 * 10**6);
        return tokenUsdc;
    }

    function getTokenDai() public returns (MockTestnetTokenDai) {
        MockTestnetTokenDai tokenDai = new MockTestnetTokenDai(10000000000000000 * Constants.D18);
        return tokenDai;
    }

    function getTokenAddresses(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    ) public pure returns (address[] memory) {
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

    function getIpTokenAddresses(
        address ipTokenUsdt,
        address ipTokenUsdc,
        address ipTokenDai
    ) public pure returns (address[] memory) {
        address[] memory ipTokenAddresses = new address[](3);
        ipTokenAddresses[0] = ipTokenUsdt;
        ipTokenAddresses[1] = ipTokenUsdc;
        ipTokenAddresses[2] = ipTokenDai;
        return ipTokenAddresses;
    }

    /// ---------------- USERS ----------------
    function getFiveUsers(
        address userOne,
        address userTwo,
        address userThree,
        address userFour,
        address userFive
    ) public pure returns (address[] memory) {
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
