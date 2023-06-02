// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "contracts/amm/AmmStorage.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./TestCommons.sol";

contract SimpleTest is TestCommons {
    AmmStorage internal _ammStorage;
    address internal _router;
    address internal _owner;
    address internal _buyer;
    address internal _ammTreasury;

    function setUp() public {
        _owner = _getUserAddress(1);
        _buyer = _getUserAddress(2);
        _router = _getUserAddress(10);
        _ammTreasury = _getUserAddress(11);
        vm.startPrank(_owner);
        AmmStorage ammStorageImplementation = new AmmStorage(_router, _ammTreasury);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(ammStorageImplementation),
            abi.encodeWithSignature("initialize()", "")
        );
        _ammStorage = AmmStorage(address(proxy));
        vm.stopPrank();
    }

    function AmmStorageLastOpenSwapTest() public {
        assertTrue(true);
    }

    function testShouldOpen28DdaysSwapPayFixed() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        // when
        vm.prank(_router);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        assertTrue(lastOpenSwapBefore.swapId == 0, "lastOpenSwapBefore.swapId == 0");

        assertTrue(lastOpenSwapAfter.swapId == 1, "lastOpenSwapAfter.swapId == 1");
        assertTrue(lastOpenSwapAfter.previousSwapId == 0, "lastOpenSwapAfter.previousSwapId == 0");
        assertTrue(lastOpenSwapAfter.nextSwapId == 0, "lastOpenSwapAfter.nextSwapId == 0");
    }

    function testShouldOpen28DdaysSwapPayFixedTwice() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        assertTrue(lastOpenSwapBefore.swapId == 0, "lastOpenSwapBefore.swapId == 0");
        assertTrue(lastOpenSwapAfter.swapId == 2, "lastOpenSwapAfter.swapId == 2");
        assertTrue(lastOpenSwapAfter.previousSwapId == 1, "lastOpenSwapAfter.previousSwapId == 1");
        assertTrue(lastOpenSwapAfter.nextSwapId == 0, "lastOpenSwapAfter.nextSwapId == 0");
    }

    function testShouldOpen28DdaysSwapReciveFixed() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        // when
        vm.prank(_router);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        assertTrue(lastOpenSwapBefore.swapId == 0, "lastOpenSwapBefore.swapId == 0");
        assertTrue(lastOpenSwapAfter.swapId == 1, "lastOpenSwapAfter.swapId == 1");
        assertTrue(lastOpenSwapAfter.previousSwapId == 0, "lastOpenSwapAfter.previousSwapId == 0");
        assertTrue(lastOpenSwapAfter.nextSwapId == 0, "lastOpenSwapAfter.nextSwapId == 0");
    }

    function testShouldOpen28DdaysSwapReceiveFixedTwice() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        assertTrue(lastOpenSwapBefore.swapId == 0, "lastOpenSwapBefore.swapId == 0");
        assertTrue(lastOpenSwapAfter.swapId == 2, "lastOpenSwapAfter.swapId == 2");
        assertTrue(lastOpenSwapAfter.previousSwapId == 1, "lastOpenSwapAfter.previousSwapId == 1");
        assertTrue(lastOpenSwapAfter.nextSwapId == 0, "lastOpenSwapAfter.nextSwapId == 0");
    }

    function testShouldOpen28DaysAnd60SaysSwapReceiveFixed() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap28Days = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        AmmTypes.NewSwap memory newSwap60Days = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_60
        );
        uint256 cfgIporPublicationFee = 1e18;

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore28 = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );
        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore60 = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_60,
            1
        );

        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap28Days, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap60Days, cfgIporPublicationFee);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter28 = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );
        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter60 = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_60,
            1
        );

        assertTrue(lastOpenSwapBefore28.swapId == 0, "lastOpenSwapBefore28.swapId == 0");
        assertTrue(lastOpenSwapAfter28.swapId == 1, "lastOpenSwapAfter28.swapId == 1");
        assertTrue(lastOpenSwapBefore60.swapId == 0, "lastOpenSwapBefore60.swapId == 0");
        assertTrue(lastOpenSwapAfter60.swapId == 2, "lastOpenSwapAfter60.swapId == 2");
    }

    function testShouldOpen3SwapsAndCloseFirst() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        vm.stopPrank();

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        AmmTypes.Swap memory swap = AmmTypes.Swap(
            1,
            _buyer,
            newSwap.openTimestamp,
            newSwap.tenor,
            1,
            newSwap.collateral,
            newSwap.notional,
            newSwap.ibtQuantity,
            newSwap.fixedInterestRate,
            newSwap.liquidationDepositAmount,
            IporTypes.SwapState.ACTIVE
        );
        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenCloseSwapPayFixed(swap, 0, 1028 days);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        assertTrue(lastOpenSwapBefore.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapBefore.previousSwapId == 2, "lastOpenSwapBefore.previousSwapId == 2");
        assertTrue(lastOpenSwapAfter.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapAfter.previousSwapId == 2, "lastOpenSwapBefore.previousSwapId == 2");
    }

    function testShouldOpen3SwapsAndCloseSecond() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        vm.stopPrank();

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        AmmTypes.Swap memory swap = AmmTypes.Swap(
            2,
            _buyer,
            newSwap.openTimestamp,
            newSwap.tenor,
            2,
            newSwap.collateral,
            newSwap.notional,
            newSwap.ibtQuantity,
            newSwap.fixedInterestRate,
            newSwap.liquidationDepositAmount,
            IporTypes.SwapState.ACTIVE
        );
        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenCloseSwapPayFixed(swap, 0, 1028 days);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        assertTrue(lastOpenSwapBefore.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapBefore.previousSwapId == 2, "lastOpenSwapBefore.previousSwapId == 2");
        assertTrue(lastOpenSwapAfter.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapAfter.previousSwapId == 1, "lastOpenSwapBefore.previousSwapId == 1");
    }

    function testShouldOpen3SwapsAndCloseThird() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);
        vm.stopPrank();

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        AmmTypes.Swap memory swap = AmmTypes.Swap(
            3,
            _buyer,
            newSwap.openTimestamp,
            newSwap.tenor,
            3,
            newSwap.collateral,
            newSwap.notional,
            newSwap.ibtQuantity,
            newSwap.fixedInterestRate,
            newSwap.liquidationDepositAmount,
            IporTypes.SwapState.ACTIVE
        );
        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenCloseSwapPayFixed(swap, 0, 1028 days);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            0
        );

        assertTrue(lastOpenSwapBefore.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapBefore.previousSwapId == 2, "lastOpenSwapBefore.previousSwapId == 2");
        assertTrue(lastOpenSwapAfter.swapId == 2, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapAfter.previousSwapId == 1, "lastOpenSwapBefore.previousSwapId == 1");
    }

    function testShouldOpen3SwapsReceiveFixedAndCloseFirst() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        vm.stopPrank();

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        AmmTypes.Swap memory swap = AmmTypes.Swap(
            1,
            _buyer,
            newSwap.openTimestamp,
            newSwap.tenor,
            1,
            newSwap.collateral,
            newSwap.notional,
            newSwap.ibtQuantity,
            newSwap.fixedInterestRate,
            newSwap.liquidationDepositAmount,
            IporTypes.SwapState.ACTIVE
        );
        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenCloseSwapReceiveFixed(swap, 0, 1028 days);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        assertTrue(lastOpenSwapBefore.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapBefore.previousSwapId == 2, "lastOpenSwapBefore.previousSwapId == 2");
        assertTrue(lastOpenSwapAfter.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapAfter.previousSwapId == 2, "lastOpenSwapBefore.previousSwapId == 2");
    }

    function testShouldOpen3SwapsReceiveFixedAndCloseSecond() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        vm.stopPrank();

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        AmmTypes.Swap memory swap = AmmTypes.Swap(
            2,
            _buyer,
            newSwap.openTimestamp,
            newSwap.tenor,
            2,
            newSwap.collateral,
            newSwap.notional,
            newSwap.ibtQuantity,
            newSwap.fixedInterestRate,
            newSwap.liquidationDepositAmount,
            IporTypes.SwapState.ACTIVE
        );
        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenCloseSwapReceiveFixed(swap, 0, 1028 days);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        assertTrue(lastOpenSwapBefore.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapBefore.previousSwapId == 2, "lastOpenSwapBefore.previousSwapId == 2");
        assertTrue(lastOpenSwapAfter.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapAfter.previousSwapId == 1, "lastOpenSwapBefore.previousSwapId == 1");
    }

    function testShouldOpen3SwapsReceiveFixedAndCloseThird() external {
        // given
        vm.warp(1000 days);

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _buyer,
            block.timestamp,
            1_000e18,
            100_000e18,
            10e18,
            1e18,
            25, //liquidationDepositAmount
            1e18,
            1e18,
            IporTypes.SwapTenor.DAYS_28
        );
        uint256 cfgIporPublicationFee = 1e18;
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        _ammStorage.updateStorageWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        vm.stopPrank();

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapBefore = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        AmmTypes.Swap memory swap = AmmTypes.Swap(
            3,
            _buyer,
            newSwap.openTimestamp,
            newSwap.tenor,
            3,
            newSwap.collateral,
            newSwap.notional,
            newSwap.ibtQuantity,
            newSwap.fixedInterestRate,
            newSwap.liquidationDepositAmount,
            IporTypes.SwapState.ACTIVE
        );
        // when
        vm.startPrank(_router);
        _ammStorage.updateStorageWhenCloseSwapReceiveFixed(swap, 0, 1028 days);
        vm.stopPrank();

        // then

        AmmInternalTypes.OpenSwapItem memory lastOpenSwapAfter = _ammStorage.getLastOpenedSwap(
            IporTypes.SwapTenor.DAYS_28,
            1
        );

        assertTrue(lastOpenSwapBefore.swapId == 3, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapBefore.previousSwapId == 2, "lastOpenSwapBefore.previousSwapId == 2");
        assertTrue(lastOpenSwapAfter.swapId == 2, "lastOpenSwapBefore.swapId == 3");
        assertTrue(lastOpenSwapAfter.previousSwapId == 1, "lastOpenSwapBefore.previousSwapId == 1");
    }
}
