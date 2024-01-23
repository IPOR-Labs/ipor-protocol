// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract ForkAmmGovernanceServiceTest is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 18562032);
    }

    function testShouldDepositToAssetManagementUsdt() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyUsdt).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(USDT, 100 * 1e18);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyUsdt).totalBalance();

        assertGt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldDepositToAssetManagementUsdc() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyUsdc).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(USDC, 100 * 1e18);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyUsdc).totalBalance();

        assertGt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldDepositToAssetManagementDai() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyDai).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, 100 * 1e18);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyDai).totalBalance();

        assertGt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldNotDepositToAssetManagementStEth() public {
        //given
        _init();

        // when
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                stETH
            )
        );
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(stETH, 100 * 1e18);
    }

    function testShouldWithdrawFromAssetManagementUsdt() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyUsdt).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(USDT, 100 * 1e18);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyUsdt).totalBalance();

        assertLt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldWithdrawFromAssetManagementUsdc() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyUsdc).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(USDC, 100 * 1e18);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyUsdc).totalBalance();

        assertLt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldWithdrawFromAssetManagementDai() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyDai).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(DAI, 100 * 1e18);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyDai).totalBalance();

        assertLt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldNotWithdrawFromAssetManagementStEth() public {
        //given
        _init();

        // when
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                stETH
            )
        );
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(stETH, 100 * 1e18);
    }

    function testShouldWithdrawAllFromAssetManagementUsdt() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyUsdt).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(USDT);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyUsdt).totalBalance();

        assertLt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldWithdrawAllFromAssetManagementUsdc() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyUsdc).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(USDC);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyUsdc).totalBalance();

        assertLt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldWithdrawAllFromAssetManagementDai() public {
        //given
        _init();

        uint256 assetManagementBalanceBefore = IAssetManagement(stanleyProxyDai).totalBalance();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);

        //then
        uint256 assetManagementBalanceAfter = IAssetManagement(stanleyProxyDai).totalBalance();

        assertLt(assetManagementBalanceAfter, assetManagementBalanceBefore);
    }

    function testShouldNotWithdrawAllFromAssetManagementStEth() public {
        //given
        _init();

        // when
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                stETH
            )
        );
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(stETH);
    }
}
