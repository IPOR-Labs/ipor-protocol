// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/stanley/MockCase2Stanley.sol";
import "../../contracts/itf/ItfStanley.sol";
import "../../contracts/itf/ItfStanleyUsdt.sol";
import "../../contracts/itf/ItfStanleyDai.sol";
import "../../contracts/tokens/IvToken.sol";
import "../../contracts/mocks/stanley/MockTestnetStrategy.sol";
import "../../contracts/mocks/MockStanleyStrategies.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenAaveUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenCompoundUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenAaveDai.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenCompoundDai.sol";

contract StanleyUtils {
    function getItfStanleyUsdt(address asset) public returns (ItfStanley itfStanley) {
        IvToken ivToken = new IvToken("IV USDT", "ivUSDT", asset);

        MockTestnetStrategy strategyAave = getMockTestnetStrategyAaveUsdt(asset);
        MockTestnetStrategy strategyCompound = getMockTestnetStrategyCompoundUsdt(asset);

        ItfStanleyUsdt itfStanleyImpl = new ItfStanleyUsdt();

        ERC1967Proxy itfStanleyProxy = new ERC1967Proxy(
            address(itfStanleyImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                asset,
                ivToken,
                address(strategyAave),
                address(strategyCompound)
            )
        );

        ivToken.setStanley(address(itfStanleyProxy));
        strategyAave.setStanley(address(itfStanleyProxy));
        strategyCompound.setStanley(address(itfStanleyProxy));

        return ItfStanley(address(itfStanleyProxy));
    }

    function getItfStanleyDai(address asset) public returns (ItfStanley itfStanley) {
        IvToken ivToken = new IvToken("IV DAI", "ivDAI", asset);

        MockTestnetStrategy strategyAave = getMockTestnetStrategyAaveDai(asset);
        MockTestnetStrategy strategyCompound = getMockTestnetStrategyCompoundDai(asset);

        ItfStanleyDai itfStanleyImpl = new ItfStanleyDai();

        ERC1967Proxy itfStanleyProxy = new ERC1967Proxy(
            address(itfStanleyImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                asset,
                ivToken,
                address(strategyAave),
                address(strategyCompound)
            )
        );

        ivToken.setStanley(address(itfStanleyProxy));
        strategyAave.setStanley(address(itfStanleyProxy));
        strategyCompound.setStanley(address(itfStanleyProxy));

        return ItfStanley(address(itfStanleyProxy));
    }

    function getMockTestnetStrategyAaveUsdt(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategyAaveUsdt strategyImpl = new MockTestnetStrategyAaveUsdt();
        MockTestnetShareTokenAaveUsdt shareToken = new MockTestnetShareTokenAaveUsdt(0);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetStrategyCompoundUsdt(address asset)
        public
        returns (MockTestnetStrategy)
    {
        MockTestnetStrategyCompoundUsdt strategyImpl = new MockTestnetStrategyCompoundUsdt();
        MockTestnetShareTokenCompoundUsdt shareToken = new MockTestnetShareTokenCompoundUsdt(0);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetStrategyAaveDai(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategyAaveDai strategyImpl = new MockTestnetStrategyAaveDai();
        MockTestnetShareTokenAaveDai shareToken = new MockTestnetShareTokenAaveDai(0);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetStrategyCompoundDai(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategyCompoundDai strategyImpl = new MockTestnetStrategyCompoundDai();
        MockTestnetShareTokenCompoundDai shareToken = new MockTestnetShareTokenCompoundDai(0);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

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

    function getMockCase2Stanley(address asset) public returns (MockCase2Stanley) {
        MockCase2Stanley mockStanley = new MockCase2Stanley(asset);
        return mockStanley;
    }
}
