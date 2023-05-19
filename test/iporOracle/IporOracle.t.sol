// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IporTypes} from "contracts/interfaces/types/IporTypes.sol";
import "../../contracts/oracles/IporOracle.sol";

contract IporOracleTest is Test {
    using stdStorage for StdStorage;

    function testShouldPauseSCSpecificMethods() public {
        // given
        IporOracle implementation = new IporOracle(address(0), 0, address(0), 0, address(0), 0);

        address[] memory assets = new address[](1);
        assets[0] = address(implementation);

        uint32[] memory updateTimestamps = new uint32[](1);
        updateTimestamps[0] = uint32(block.timestamp);

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize(address[],uint32[])", assets, updateTimestamps)
        );

        IporOracle(address(proxy)).addUpdater(address(this));

        vm.warp(block.timestamp + 1200);

        uint256 x11 = gasleft();

        IporOracle(address(proxy)).updateIndex(address(implementation), 3 * 1e16);

        uint256 x12 = gasleft();

        console2.logUint(x11 - x12);

        for (uint256 i = 0; i < 365; i++) {
            vm.warp(block.timestamp + 86400);
            IporOracle(address(proxy)).updateIndex(address(implementation), 3 * 1e16);
        }

        uint256 x21 = gasleft();

        IporTypes.AccruedIpor memory accruedIpor = IporOracle(address(proxy)).getAccruedIndex(
            block.timestamp,
            address(implementation)
        );

        uint256 x22 = gasleft();

        console2.logUint(x21 - x22);
        console2.logUint(accruedIpor.ibtPrice);

        uint256 mainnetQuasiIbtPrice = 32333654772389550420777130;
        uint256 mainnetIbtPrice = 1025293466907329732;

        uint256 ipm = IporMath.division(
            mainnetQuasiIbtPrice - Constants.WAD_YEAR_IN_SECONDS,
            Constants.YEAR_IN_SECONDS
        );
        uint256 ibt = InterestRates.addContinuousCompoundInterestUsingRatePeriodMultiplication(1e18, ipm);
        console2.logUint(mainnetIbtPrice);
        console2.logUint(ibt);
    }
}
