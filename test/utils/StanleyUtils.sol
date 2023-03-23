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
import "../../contracts/mocks/stanley/compound/MockWhitePaper.sol";
import "../../contracts/mocks/stanley/compound/MockCToken.sol";
import "../../contracts/mocks/stanley/compound/MockComptroller.sol";
import "../../contracts/mocks/tokens/MockedCOMPToken.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";

contract StanleyUtils {
    function getCToken(address asset, address interestRateModel, uint8 decimal, string memory name, string memory code)
        public
        returns (MockCToken)
    {
        return new MockCToken(asset, interestRateModel, decimal, name, code);
    }

    function getTokenComp() public returns (MockedCOMPToken) {
        return new MockedCOMPToken(1000000000000000000000000000000, 18);
    }

    function getItfStanleyUsdt(address asset) public returns (ItfStanley itfStanley) {
        IvToken ivToken = new IvToken("IV USDT", "ivUSDT", asset);

        MockTestnetStrategy strategyAave = getMockTestnetStrategyAaveUsdt(asset);
        MockTestnetStrategy strategyCompound = getMockTestnetStrategyCompoundUsdt(asset);

        ItfStanleyUsdt itfStanleyImpl = new ItfStanleyUsdt();

        address itfStanleyProxyAddress = address(
            new ERC1967Proxy(
            address(itfStanleyImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                asset,
                ivToken,
                address(strategyAave),
                address(strategyCompound)
            )
            )
        );

        ivToken.setStanley(itfStanleyProxyAddress);
        strategyAave.setStanley(itfStanleyProxyAddress);
        strategyCompound.setStanley(itfStanleyProxyAddress);

        return ItfStanley(itfStanleyProxyAddress);
    }

    function getItfStanleyDai(address asset) public returns (ItfStanley itfStanley) {
        IvToken ivToken = new IvToken("IV DAI", "ivDAI", asset);

        MockTestnetStrategy strategyAave = getMockTestnetStrategyAaveDai(asset);
        MockTestnetStrategy strategyCompound = getMockTestnetStrategyCompoundDai(asset);

        ItfStanleyDai itfStanleyImpl = new ItfStanleyDai();

        address itfStanleyProxyAddress = address(
            new ERC1967Proxy(
            address(itfStanleyImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                asset,
                ivToken,
                address(strategyAave),
                address(strategyCompound)
            )
            )
        );

        ivToken.setStanley(itfStanleyProxyAddress);
        strategyAave.setStanley(itfStanleyProxyAddress);
        strategyCompound.setStanley(itfStanleyProxyAddress);

        return ItfStanley(itfStanleyProxyAddress);
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

    function getMockTestnetStrategyCompoundUsdt(address asset) public returns (MockTestnetStrategy) {
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
        return new MockCase0Stanley(asset);
    }

    function getMockCaseBaseStanley(address asset) public returns (MockCaseBaseStanley) {
        return new MockCaseBaseStanley(asset);
    }

    function _getMockCase0Stanleys(address tokenUsdt, address tokenUsdc, address tokenDai)
        internal
        returns (MockCase0Stanley, MockCase0Stanley, MockCase0Stanley)
    {
        MockCase0Stanley mockStanleyUsdt = new MockCase0Stanley(tokenUsdt);
        MockCase0Stanley mockStanleyUsdc = new MockCase0Stanley(tokenUsdc);
        MockCase0Stanley mockStanleyDai = new MockCase0Stanley(tokenDai);
        return (mockStanleyUsdt, mockStanleyUsdc, mockStanleyDai);
    }

    function getMockCase1Stanley(address asset) public returns (MockCase1Stanley) {
        return new MockCase1Stanley(asset);
    }

    function _getMockCase1Stanleys(address tokenUsdt, address tokenUsdc, address tokenDai)
        internal
        returns (MockCase1Stanley, MockCase1Stanley, MockCase1Stanley)
    {
        MockCase1Stanley mockStanleyUsdt = new MockCase1Stanley(tokenUsdt);
        MockCase1Stanley mockStanleyUsdc = new MockCase1Stanley(tokenUsdc);
        MockCase1Stanley mockStanleyDai = new MockCase1Stanley(tokenDai);
        return (mockStanleyUsdt, mockStanleyUsdc, mockStanleyDai);
    }

    function getMockCase2Stanley(address asset) public returns (MockCase2Stanley) {
        return new MockCase2Stanley(asset);
    }

    function getMockWhitePaper() public returns (MockWhitePaper) {
        return new MockWhitePaper();
    }

    function getMockComptroller(address tokenCOMP, address cUSDT, address cUSDC, address cDAI)
        public
        returns (MockComptroller)
    {
        return new MockComptroller(tokenCOMP, cUSDT, cUSDC, cDAI);
    }

    function getStrategyCompound(address asset, address shareToken, address comptroller, address tokenComp)
        public
        returns (StrategyCompound)
    {
        StrategyCompound strategyCompoundImpl = new StrategyCompound();
        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyCompoundImpl),
            abi.encodeWithSignature("initialize(address,address,address,address)", asset, shareToken, comptroller, tokenComp)
        );
        return StrategyCompound(address(strategyProxy));
    }
}
