// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@ipor-protocol/test/mocks/tokens/MockTestnetToken.sol";
import "@ipor-protocol/test/mocks/tokens/MockTestnetToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./utils/factory/IporProtocolFactory.sol";

contract TestCommons is Test {
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;
    address internal _userThree;
    address internal _liquidityProvider;
    address[] internal _users;

    IporProtocolFactory internal _iporProtocolFactory = new IporProtocolFactory(address(this));
    IporRiskManagementOracleFactory internal _iporRiskManagementOracleFactory =
        new IporRiskManagementOracleFactory(address(this));

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _getStables()
        internal
        returns (
            MockTestnetToken dai,
            MockTestnetToken usdc,
            MockTestnetToken usdt
        )
    {
        dai = new MockTestnetToken("Mocked DAI", "DAI", 100_000_000 * 1e18, uint8(18));
        usdc = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
        usdt = new MockTestnetToken("Mocked USDT", "USDT", 100_000_000 * 1e6, uint8(6));
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
