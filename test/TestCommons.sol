// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/mocks/tokens/MockTestnetToken.sol";
import "./utils/factory/IporProtocolFactory.sol";

contract TestCommons is Test {
    IporProtocolFactory internal _iporProtocolFactory = new IporProtocolFactory(address(this));


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
}
