// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import {IporRiskManagementOracleUtils} from "../utils/IporRiskManagementOracleUtils.sol";
import "contracts/amm/MiltonStorage.sol";
import "contracts/libraries/Constants.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";
import "contracts/mocks/stanley/MockCaseBaseStanley.sol";
import "contracts/interfaces/IIporRiskManagementOracle.sol";
import "contracts/itf/ItfIporOracle.sol";
import "contracts/itf/ItfMilton.sol";
import "contracts/itf/ItfStanley.sol";
import "contracts/itf/ItfJoseph.sol";
import "contracts/itf/ItfIporOracle.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/mocks/MockIporWeighted.sol";

contract DataUtils is
    Test,
    TestCommons,
    IporOracleUtils,
    IporRiskManagementOracleUtils,
    MiltonUtils,
    MiltonStorageUtils,
    JosephUtils,
    StanleyUtils
{
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;
    address internal _userThree;
    address internal _liquidityProvider;
    address[] internal _users;

    function getTokenUsdt() public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked USDT", "USDT", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6);
    }

    function getTokenUsdc() public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked USDC", "USDC", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6);
    }

    function getTokenDai() public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked DAI", "DAI", TestConstants.TOTAL_SUPPLY_18_DECIMALS, 18);
    }

    function prepareIpToken(IpToken ipToken, address joseph) public {
        ipToken.setJoseph(joseph);
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

    function usersToArray(
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
}