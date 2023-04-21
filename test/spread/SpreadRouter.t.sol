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

    function testShouldSetupProperDaiAddressesWhenDeployd() public {
        // given
        MockSpread28Days mockSpread28Days = new MockSpread28Days();

        SpreadRouter.DeployedContracts memory deployedContracts = SpreadRouter.DeployedContracts(
            address(_dai),
            address(_usdc),
            address(_usdt),
            address(0x0),
            address(0x0),
            address(mockSpread28Days)
        );

        IporTypes.AccruedIpor memory accruedIpor;
        IporTypes.MiltonBalancesMemory memory accruedBalance;
        // when

        SpreadRouter router = new SpreadRouter(deployedContracts);
        uint256 spreadQuotePayFixed = ISpread28Days(address(router)).calculateQuotePayFixed28Days(address(_dai), accruedIpor, accruedBalance);
        uint256 spreadQuoteReceiveFixed = ISpread28Days(address(router)).calculateQuoteReceiveFixed28Days(address(_dai), accruedIpor, accruedBalance);

        // then
        assertEq(spreadQuotePayFixed, 1);
        assertEq(spreadQuoteReceiveFixed, 2);
    }

    function testShouldSetupProperUsdcAddressesWhenDeployd() public {
        // given
        MockSpread28Days mockSpread28Days = new MockSpread28Days();

        SpreadRouter.DeployedContracts memory deployedContracts = SpreadRouter.DeployedContracts(
            address(_dai),
            address(_usdc),
            address(_usdt),
            address(0x0),
            address(0x0),
            address(mockSpread28Days)
        );

        IporTypes.AccruedIpor memory accruedIpor;
        IporTypes.MiltonBalancesMemory memory accruedBalance;
        // when

        SpreadRouter router = new SpreadRouter(deployedContracts);
        uint256 spreadQuotePayFixed = ISpread28Days(address(router)).calculateQuotePayFixed28Days(address(_usdc), accruedIpor, accruedBalance);
        uint256 spreadQuoteReceiveFixed = ISpread28Days(address(router)).calculateQuoteReceiveFixed28Days(address(_usdc), accruedIpor, accruedBalance);

        // then
        assertEq(spreadQuotePayFixed, 1);
        assertEq(spreadQuoteReceiveFixed, 2);
    }

    function testShouldSetupProperUsdtAddressesWhenDeployd() public {
        // given
        MockSpread28Days mockSpread28Days = new MockSpread28Days();

        SpreadRouter.DeployedContracts memory deployedContracts = SpreadRouter.DeployedContracts(
            address(_dai),
            address(_usdc),
            address(_usdt),
            address(0x0),
            address(0x0),
            address(mockSpread28Days)
        );

        IporTypes.AccruedIpor memory accruedIpor;
        IporTypes.MiltonBalancesMemory memory accruedBalance;
        // when

        SpreadRouter router = new SpreadRouter(deployedContracts);
        uint256 spreadQuotePayFixed = ISpread28Days(address(router)).calculateQuotePayFixed28Days(address(_usdt), accruedIpor, accruedBalance);
        uint256 spreadQuoteReceiveFixed = ISpread28Days(address(router)).calculateQuoteReceiveFixed28Days(address(_usdt), accruedIpor, accruedBalance);

        // then
        assertEq(spreadQuotePayFixed, 1);
        assertEq(spreadQuoteReceiveFixed, 2);
    }
}