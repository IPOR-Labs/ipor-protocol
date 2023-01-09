// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/stanley/MockCase2Stanley.sol";

contract StanleyUtils {
    /// ---------------------- Mock Cases Stanley ----------------------
    function getMockCase0Stanley(address asset) public returns (MockCase0Stanley) {
        MockCase0Stanley mockStanley = new MockCase0Stanley(asset);
        return mockStanley;
    }

    function _getMockCase0Stanleys(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    )
        internal
        returns (
            MockCase0Stanley,
            MockCase0Stanley,
            MockCase0Stanley
        )
    {
        MockCase0Stanley mockStanleyUsdt = new MockCase0Stanley(tokenUsdt);
        MockCase0Stanley mockStanleyUsdc = new MockCase0Stanley(tokenUsdc);
        MockCase0Stanley mockStanleyDai = new MockCase0Stanley(tokenDai);
        return (mockStanleyUsdt, mockStanleyUsdc, mockStanleyDai);
    }

    function getMockCase0StanleyAddresses(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    ) public returns (address[] memory) {
        (
            MockCase0Stanley stanleyUsdt,
            MockCase0Stanley stanleyUsdc,
            MockCase0Stanley stanleyDai
        ) = _getMockCase0Stanleys(address(tokenUsdt), address(tokenUsdc), address(tokenDai));
        address[] memory mockStanleyAddresses = new address[](3);
        mockStanleyAddresses[0] = address(stanleyUsdt);
        mockStanleyAddresses[1] = address(stanleyUsdc);
        mockStanleyAddresses[2] = address(stanleyDai);
        return mockStanleyAddresses;
    }

    // ------------------------------------------------------------

    function getMockCase1Stanley(address asset) public returns (MockCase1Stanley) {
        MockCase1Stanley mockStanley = new MockCase1Stanley(asset);
        return mockStanley;
    }

    function _getMockCase1Stanleys(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    )
        internal
        returns (
            MockCase1Stanley,
            MockCase1Stanley,
            MockCase1Stanley
        )
    {
        MockCase1Stanley mockStanleyUsdt = new MockCase1Stanley(tokenUsdt);
        MockCase1Stanley mockStanleyUsdc = new MockCase1Stanley(tokenUsdc);
        MockCase1Stanley mockStanleyDai = new MockCase1Stanley(tokenDai);
        return (mockStanleyUsdt, mockStanleyUsdc, mockStanleyDai);
    }

    function getMockCase1StanleyAddresses(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    ) public returns (address[] memory) {
        (
            MockCase1Stanley stanleyUsdt,
            MockCase1Stanley stanleyUsdc,
            MockCase1Stanley stanleyDai
        ) = _getMockCase1Stanleys(address(tokenUsdt), address(tokenUsdc), address(tokenDai));
        address[] memory mockStanleyAddresses = new address[](3);
        mockStanleyAddresses[0] = address(stanleyUsdt);
        mockStanleyAddresses[1] = address(stanleyUsdc);
        mockStanleyAddresses[2] = address(stanleyDai);
        return mockStanleyAddresses;
    }

    // ------------------------------------------------------------

    function getMockCase2Stanley(address asset) public returns (MockCase2Stanley) {
        MockCase2Stanley mockStanley = new MockCase2Stanley(asset);
        return mockStanley;
    }
    /// ---------------------- Mock Cases Stanley ----------------------
}
