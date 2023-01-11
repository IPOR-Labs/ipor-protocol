// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/tokens/IpToken.sol";

contract DataUtils is
    Test,
    IporOracleUtils,
    MiltonUtils,
    MiltonStorageUtils,
    JosephUtils,
    StanleyUtils
{
    function getTokenUsdt() public returns (MockTestnetTokenUsdt) {
        return new MockTestnetTokenUsdt(100000000000000 * 10**6);
    }

    function getTokenUsdc() public returns (MockTestnetTokenUsdc) {
        return new MockTestnetTokenUsdc(100000000000000 * 10**6);
    }

    function getTokenDai() public returns (MockTestnetTokenDai) {
        return new MockTestnetTokenDai(10000000000000000 * Constants.D18);
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

    function prepareIpTokenUsdt(IpToken ipTokenUsdt, address josephUsdt) public {
        ipTokenUsdt.setJoseph(josephUsdt);
    }

    function prepareIpTokenUsdc(IpToken ipTokenUsdc, address josephUsdc) public {
        ipTokenUsdc.setJoseph(josephUsdc);
    }

    function prepareIpTokenDai(IpToken ipTokenDai, address josephDai) public {
        ipTokenDai.setJoseph(josephDai);
    }
}
