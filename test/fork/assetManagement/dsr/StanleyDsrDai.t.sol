// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../../contracts/vault/strategies/StrategyDsrDai.sol";
import "../../../../contracts/vault/StanleyDsrDai.sol";
import "../../../../contracts/interfaces/IStanley.sol";
import "../../../../contracts/interfaces/IJoseph.sol";
import "../../../../contracts/interfaces/IJosephInternal.sol";
import "../../../../contracts/interfaces/IStanleyInternal.sol";

contract StanleyAaveDaiTest is Test {
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant sDai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address public constant ivDai = 0x8537b194BFf354c4738E9F3C81d67E3371DaDAf8;
    address public constant miltonDai = 0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523;
    address public constant josephDai = 0x086d4daab14741b195deE65aFF050ba184B65045;
    address public constant strategyAaveDai = 0x526d0047725D48BBc6e24C7B82A3e47C1AF1f62f;
    address public constant strategyCompoundDai = 0x87CEF19aCa214d12082E201e6130432Df39fc774;
    address public constant stanleyDai = 0xA6aC8B6AF789319A1Db994E25760Eb86F796e2B0;

    address private _iporProtocolOwner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;

    address internal _admin;

    StrategyDsrDai public strategyDsr;

    function setUp() public {
        uint256 forkId = vm.createSelectFork(vm.envString("FORK_URL"), 17810000);
        _admin = vm.rememberKey(1);
        strategyDsr = _createDsrStrategy();
    }
//
//    function testShouldBeTheSameBalanceAfterUpgrade() public {
//        //given
//        IStanley stanley = IStanley(stanleyDai);
//        uint256 balanceBefore = stanley.totalBalance(0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523);
//        balanceBefore = IporMath.division(balanceBefore, 1e7);
//
//        //when
//        _upgradeStanleyDsr();
//
//        //then
//        StanleyDsrDai stanleyV2 = StanleyDsrDai(stanleyDai);
//        uint256 balanceAfter = stanleyV2.totalBalance(0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523);
//        balanceAfter = IporMath.division(balanceAfter, 1e7);
//
//        assertEq(balanceBefore, balanceAfter);
//    }
//
//    function testShouldBeTheSameAprAfterUpgrade() public {
//        //given
//        IStanleyInternal stanley = IStanleyInternal(stanleyDai);
//
//        address strategyAaveBefore = stanley.getStrategyAave();
//        address strategyCompoundBefore = stanley.getStrategyCompound();
//
//        uint256 aprAaveBefore = IStrategy(strategyAaveBefore).getApr();
//        uint256 aprCompoundBefore = IStrategy(strategyCompoundBefore).getApr();
//
//        //when
//        _upgradeStanleyDsr();
//
//        //then
//        address strategyAaveAfter = stanley.getStrategyAave();
//        address strategyCompoundAfter = stanley.getStrategyCompound();
//
//        uint256 aprAaveAfter = IStrategyDsr(strategyAaveAfter).getApr();
//        uint256 aprCompoundAfter = IStrategyDsr(strategyCompoundAfter).getApr();
//        uint256 aprDsrAfter = IStrategyDsr(strategyDsr).getApr();
//
//        assertEq(aprAaveBefore, aprAaveAfter);
//        assertEq(aprCompoundBefore, aprCompoundAfter);
//
//        console2.log("aprDsrAfter", aprDsrAfter);
//    }

    function testShouldRebalanceAfterUpgrade() public {
        //given
        IJosephInternal joseph = IJosephInternal(josephDai);
        _upgradeStanleyDsr();

        uint256 aaveApr = IStrategyDsr(strategyAaveDai).getApr();
        uint256 compoundApr = IStrategyDsr(strategyCompoundDai).getApr();
        uint256 dsrApr = IStrategyDsr(strategyDsr).getApr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();


        console2.log("aaveApr", aaveApr);
        console2.log("compoundApr", compoundApr);
        console2.log("dsrApr", dsrApr);

        console2.log("aave address=", address(strategyAaveDai));
        console2.log("compound address=", address(strategyCompoundDai));
        console2.log("dsr address=", address(strategyDsr));

        //when
        vm.prank(0xA21603c271C6f41CdC83E70a0691171eBB7db40A);
        joseph.rebalance();

        //then
        uint256 balanceDsr = IStrategyDsr(strategyDsr).balanceOf();
        uint256 balanceAave = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 balanceCompound = IStrategyDsr(strategyCompoundDai).balanceOf();

        console2.log("balanceDsr", balanceDsr);
        console2.log("balanceAave", balanceAave);
        console2.log("balanceCompound", balanceCompound);

    }

//
//    function testShouldRebalanceToDsrWhenRestIsPaused() public {
//
//    }
//    function testShouldWithdrawFromAllStrategies() public {
//
//    }
//    function testShouldProvideLiquidity() public {}
//
//    function testShouldRedeemLiquidity() public {}
//
//
//    function testShould() public {
//        //        StanleyDsrDai stanley = StanleyDsrDai(stanleyDai);
//        IStanley stanley = IStanley(stanleyDai);
//        uint256 balance = stanley.totalBalance(0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523);
//        console2.log("balance", balance);
//    }

    function _upgradeStanleyDsr() internal {
        StanleyDsrDai implementation = new StanleyDsrDai(
            dai,
            miltonDai,
            strategyAaveDai,
            strategyCompoundDai,
            address(strategyDsr),
            ivDai
        );

        vm.prank(_iporProtocolOwner);
        UUPSUpgradeable(stanleyDai).upgradeTo(address(implementation));
    }

    function _createDsrStrategy() internal returns (StrategyDsrDai) {
        StrategyDsrDai implementation = new StrategyDsrDai(dai, sDai, address(stanleyDai));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize()")
        );
        return StrategyDsrDai(address(proxy));
    }
}
