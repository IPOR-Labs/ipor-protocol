// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/mocks/tokens/MockTestnetToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/amm/spread/SpreadRouter.sol";
import "../contracts/amm/spread/SpreadLens.sol";

contract TestCommons is Test {
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

    function _createSpread(address dai, address usdc, address usdt) internal returns (address) {
        SpreadLens spreadLens = new SpreadLens(dai, usdc, usdt);


        SpreadRouter implementation = new SpreadRouter(
            SpreadRouter.DeployedContracts({
                dai: dai,
                usdc: usdc,
                usdt: usdt,
                governance: address(0x0), // TODO: add governance
                lens: address(spreadLens),
                spread28DaysDai: address(0x0), // TODO: add spread28DaysDai
                spread28DaysUsdc: address(0x0), // TODO: add spread28DaysUsdc
                spread28DaysUsdt: address(0x0) // TODO: add spread28DaysUsdt
            })
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool)",
                false
            )
        );


        return address(proxy);
    }
}
