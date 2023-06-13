// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./TestForkCommons.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";

contract StrategyAaveForkTest is TestForkCommons {

    function _initStrategy(address asset, address aToken) internal returns (StrategyAave) {
        StrategyAave daiAaveStrategyImplementation = new StrategyAave();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(daiAaveStrategyImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address,address)",
                asset,
                aToken,
                aaveLendingPoolAddressProvider,
                stakedAAVE,
                aaveIncentivesController,
                AAVE
            )
        );
        return StrategyAave(address(proxy));
    }

    function testApyCalculationForUSDC() public {
        // given
        vm.rollFork(17_469_715);
        StrategyAave strategyAave = _initStrategy(USDC, aUSDC);

        // when
        uint256 apy = strategyAave.getApy();
        assertEq(apy, 24845273515971105);
    }

    function testApyCalculationForUSDT() public {
        // given
        vm.rollFork(17_469_715);
        StrategyAave strategyAave = _initStrategy(USDT, aUSDT);

        // when
        uint256 apy = strategyAave.getApy();
        assertEq(apy, 23181193471815983);
    }

    function testApyCalculationForDAI() public {
        // given
        vm.rollFork(17_469_715);
        StrategyAave strategyAave = _initStrategy(DAI, aDAI);

        // when
        uint256 apy = strategyAave.getApy();
        assertEq(apy, 24934288929687418);
    }
}
