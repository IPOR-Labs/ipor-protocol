// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./TestForkCommons.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/interfaces/IAmmGovernanceService.sol";
import "contracts/interfaces/IIpToken.sol";
import "./IAsset.sol";
import "../../contracts/vault/interfaces/aave/AaveLendingPoolV2.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";

contract FirstForkTest is TestForkCommons {
    function testDAI() public {
        // given
        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        DataTypesContract.ReserveData memory reserveData = lendingPool.getReserveData(
            0x6B175474E89094C44Da98b954EedeAC495271d0F
        );

        uint256 apr = IporMath.division(reserveData.currentLiquidityRate, 1e9);
        console2.log("APR", apr);
        uint256 gasStart = gasleft();
        console2.log(gasleft());
        uint256 apy = aprToApy(apr);
        console2.log(gasStart - gasleft());

        console2.log("APY", apy);
    }

    function aprToApy(uint256 apr) internal pure returns (uint256) {
        uint256 rate = IporMath.division(apr, 31536000) + 1e18;

        uint256 rate2 = IporMath.division(rate * rate, 1e18);
        uint256 rate8 = IporMath.division(rate2 * rate2 * rate2 * rate2, 1e54);
        uint256 rate32 = IporMath.division(rate8 * rate8 * rate8 * rate8, 1e54);
        uint256 rate128 = IporMath.division(rate32 * rate32 * rate32 * rate32, 1e54);
        uint256 rate512 = IporMath.division(rate128 * rate128 * rate128 * rate128, 1e54);
        uint256 rate1024 = IporMath.division(rate512 * rate512, 1e18);
        uint256 rate4096 = IporMath.division(rate1024 * rate1024 * rate1024 * rate1024, 1e54);
        uint256 rate8192 = IporMath.division(rate4096 * rate4096, 1e18);
        uint256 rate32768 = IporMath.division(rate8192 * rate8192 * rate8192 * rate8192, 1e54);
        uint256 rate65536 = IporMath.division(rate32768 * rate32768, 1e18);
        uint256 rate262144 = IporMath.division(rate65536 * rate65536 * rate65536 * rate65536, 1e54);
        uint256 rate524288 = IporMath.division(rate262144 * rate262144, 1e18);
        uint256 rate2097152 = IporMath.division(rate524288 * rate524288 * rate524288 * rate524288, 1e54);
        uint256 rate4194304 = IporMath.division(rate2097152 * rate2097152, 1e18);
        uint256 rate16777216 = IporMath.division(rate4194304 * rate4194304 * rate4194304 * rate4194304, 1e54);

        uint256 rate896 = IporMath.division(rate512 * rate128 * rate128 * rate128, 1e54);
        uint256 rate2174976 = IporMath.division(rate2097152 * rate65536 * rate8192 * rate4096, 1e54);
        uint256 rate29360128 = IporMath.division(rate16777216 * rate4194304 * rate4194304 * rate4194304, 1e54);

        return IporMath.division(rate29360128 * rate2174976 * rate896, 1e36) - 1e18;
    }
}
