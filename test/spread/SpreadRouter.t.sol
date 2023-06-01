// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import "../../contracts/amm/spread/SpreadRouter.sol";
import "./MockSpread28Days.sol";
import "./MockSpreadLens.sol";

contract SpreadRouterTest is TestCommons {
    MockTestnetToken internal _dai;
    MockTestnetToken internal _usdc;
    MockTestnetToken internal _usdt;

    function setUp() public {
        (_dai, _usdc, _usdt) = _getStables();
    }

//    function testShouldSetupProperDaiAddressesWhenDeployd() public {
//        // given
//        MockSpread28Days mockSpread28Days = new MockSpread28Days();
//
//        SpreadRouter.DeployedContracts memory deployedContracts = SpreadRouter.DeployedContracts(
//            address(_dai),
//            address(_usdc),
//            address(_usdt),
//            address(0x0),
//            address(0x0),
//            address(mockSpread28Days)
//        );
//
//        IporTypes.SpreadInputs memory spreadInputs = IporTypes.SpreadInputs({
//            asset: address(_dai),
//            swapNotional: 0,
//            maxLeverage: 1_000,
//            maxLpCollateralRatioPerLegRate: 0,
//            baseSpread: 1e16,
//            totalCollateralPayFixed: 10_000e18,
//            totalCollateralReceiveFixed: 10_000e18,
//            liquidityPool: 100_000e18,
//            totalNotionalPayFixed: 100_000_000e18,
//            totalNotionalReceiveFixed: 100_000_000e18,
//            indexValue: 14e16
//        });
//        // when
//
//        SpreadRouter router = new SpreadRouter(deployedContracts);
//        uint256 spreadQuotePayFixed = ISpread28Days(address(router)).calculateAndUpdateOfferedRatePayFixed28Days(spreadInputs);
//        uint256 spreadQuoteReceiveFixed = ISpread28Days(address(router)).calculateOfferedRateReceiveFixed28Days(spreadInputs);
//
//        // then
//        assertEq(spreadQuotePayFixed, 1);
//        assertEq(spreadQuoteReceiveFixed, 2);
//    }
//
//    function testShouldSetupProperUsdcAddressesWhenDeployd() public {
//        // given
//        MockSpread28Days mockSpread28Days = new MockSpread28Days();
//
//        SpreadRouter.DeployedContracts memory deployedContracts = SpreadRouter.DeployedContracts(
//            address(_dai),
//            address(_usdc),
//            address(_usdt),
//            address(0x0),
//            address(0x0),
//            address(mockSpread28Days)
//        );
//
//        IporTypes.SpreadInputs memory spreadInputs = IporTypes.SpreadInputs({
//            asset: address(_dai),
//            swapNotional: 0,
//            maxLeverage: 1_000,
//            maxLpCollateralRatioPerLegRate: 0,
//            baseSpread: 1e16,
//            totalCollateralPayFixed: 10_000e18,
//            totalCollateralReceiveFixed: 10_000e18,
//            liquidityPool: 100_000e18,
//            totalNotionalPayFixed: 100_000_000e18,
//            totalNotionalReceiveFixed: 100_000_000e18,
//            indexValue: 14e16
//        });
//        // when
//
//        SpreadRouter router = new SpreadRouter(deployedContracts);
//        uint256 spreadQuotePayFixed = ISpread28Days(address(router)).calculateAndUpdateOfferedRatePayFixed28Days(
//            spreadInputs
//        );
//        uint256 spreadQuoteReceiveFixed = ISpread28Days(address(router)).calculateOfferedRateReceiveFixed28Days(
//            spreadInputs
//        );
//
//        // then
//        assertEq(spreadQuotePayFixed, 1);
//        assertEq(spreadQuoteReceiveFixed, 2);
//    }
//
//    function testShouldSetupProperUsdtAddressesWhenDeployd() public {
//        // given
//        MockSpread28Days mockSpread28Days = new MockSpread28Days();
//
//        SpreadRouter.DeployedContracts memory deployedContracts = SpreadRouter.DeployedContracts(
//            address(_dai),
//            address(_usdc),
//            address(_usdt),
//            address(0x0),
//            address(0x0),
//            address(mockSpread28Days)
//        );
//
//        IporTypes.SpreadInputs memory spreadInputs = IporTypes.SpreadInputs({
//            asset: address(_dai),
//            swapNotional: 0,
//            maxLeverage: 1_000,
//            maxLpCollateralRatioPerLegRate: 0,
//            baseSpread: 1e16,
//            totalCollateralPayFixed: 10_000e18,
//            totalCollateralReceiveFixed: 10_000e18,
//            liquidityPool: 100_000e18,
//            totalNotionalPayFixed: 100_000_000e18,
//            totalNotionalReceiveFixed: 100_000_000e18,
//            indexValue: 14e16
//        });
//        // when
//
//        SpreadRouter router = new SpreadRouter(deployedContracts);
//        uint256 spreadQuotePayFixed = ISpread28Days(address(router)).calculateAndUpdateOfferedRatePayFixed28Days(
//            spreadInputs
//        );
//        uint256 spreadQuoteReceiveFixed = ISpread28Days(address(router)).calculateOfferedRateReceiveFixed28Days(
//            spreadInputs
//        );
//
//        // then
//        assertEq(spreadQuotePayFixed, 1);
//        assertEq(spreadQuoteReceiveFixed, 2);
//    }
}
