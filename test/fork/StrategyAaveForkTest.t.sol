// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./TestForkCommons.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";

contract StrategyAaveForkTest is TestForkCommons {
    function _initStrategy(
        address asset,
        uint256 assetDecimals,
        address aToken,
        address assetManagementProxy
    ) internal returns (StrategyAave) {
        StrategyAave daiAaveStrategyImplementation = new StrategyAave(
            asset,
            assetDecimals,
            aToken,
            assetManagementProxy,
            AAVE,
            stakedAAVE,
            aaveLendingPoolAddressProvider,
            stakedAAVE,
            aaveIncentivesController
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(daiAaveStrategyImplementation),
            abi.encodeWithSignature("initialize()")
        );
        return StrategyAave(address(proxy));
    }

    function testApyCalculationForUSDC() public {
        // given
        vm.rollFork(17_469_715);
        StrategyAave strategyAave = _initStrategy(USDC, 6, aUSDC, stanleyProxyUsdc);

        // when
        uint256 apy = strategyAave.getApy();
        assertEq(apy, 24845273515971105);
    }

    function testApyCalculationForUSDT() public {
        // given
        vm.rollFork(17_469_715);
        StrategyAave strategyAave = _initStrategy(USDT, 6, aUSDT, stanleyProxyUsdt);

        // when
        uint256 apy = strategyAave.getApy();
        assertEq(apy, 23181193471815983);
    }

    function testApyCalculationForDAI() public {
        // given
        vm.rollFork(17_469_715);
        StrategyAave strategyAave = _initStrategy(DAI, 18, aDAI, stanleyProxyDai);

        // when
        uint256 apy = strategyAave.getApy();
        assertEq(apy, 24934288929687418);
    }
}
