// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "contracts/amm/spread/SpreadRouter.sol";
import "./MockSpreadServices.sol";
import "contracts/interfaces/types/IporTypes.sol";

contract SpreadRouterTest is TestCommons {
    address internal _owner;
    address internal _iporProtocolRouter;
    address internal _spread28Days;
    address internal _spread60Days;
    address internal _spread90Days;
    address internal _storageLens;
    address internal _closeSwapService;
    address internal _router;
    IporTypes.SpreadInputs internal _spreadInputs;

    function setUp() external {
        _iporProtocolRouter = _getUserAddress(10);
        _owner = _getUserAddress(1);

        vm.startPrank(_owner);
        _spread28Days = address(new MockSpreadServices());
        _spread60Days = address(new MockSpreadServices());
        _spread90Days = address(new MockSpreadServices());
        _storageLens = address(new MockSpreadServices());
        _closeSwapService = address(new MockSpreadServices());
        vm.stopPrank();

        SpreadRouter.DeployedContracts memory deployedContracts = SpreadRouter.DeployedContracts(
            _iporProtocolRouter,
            _spread28Days,
            _spread60Days,
            _spread90Days,
            _storageLens,
            _closeSwapService
        );

        vm.startPrank(_owner);
        SpreadRouter routerImplementation = new SpreadRouter(deployedContracts);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(routerImplementation),
            abi.encodeWithSignature("initialize(bool)", false)
        );
        _router = address(proxy);
        SpreadAccessControl(_router).addPauseGuardian(_owner);
        vm.stopPrank();

        _spreadInputs = IporTypes.SpreadInputs(address(0x00), 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100);
    }

    function testShouldGetProperConfigurationWhenDeployd() external {
        // when
        SpreadRouter.DeployedContracts memory deployedContracts = SpreadRouter(_router).getConfiguration();

        // then
        assertEq(deployedContracts.iporProtocolRouter, _iporProtocolRouter, "iporProtocolRouter");
        assertEq(deployedContracts.spread28Days, _spread28Days, "spread28Days");
        assertEq(deployedContracts.spread60Days, _spread60Days, "spread60Days");
        assertEq(deployedContracts.spread90Days, _spread90Days, "spread90Days");
        assertEq(deployedContracts.storageLens, _storageLens, "storageLens");
        assertEq(deployedContracts.closeSwapService, _closeSwapService, "closeSwapService");
    }

    function testShouldBeAbleRun28DaysMethod() external {
        // given

        // when
        vm.startPrank(_iporProtocolRouter);
        ISpread28Days(_router).calculateAndUpdateOfferedRatePayFixed28Days(_spreadInputs);
        ISpread28Days(_router).calculateAndUpdateOfferedRateReceiveFixed28Days(_spreadInputs);
        ISpread28DaysLens(_router).calculateOfferedRatePayFixed28Days(_spreadInputs);
        ISpread28DaysLens(_router).calculateOfferedRateReceiveFixed28Days(_spreadInputs);
        ISpread28DaysLens(_router).spreadFunction28DaysConfig();
        vm.stopPrank();
    }

    function testShouldBeAbleRun60DaysMethod() external {
        // given

        // when
        vm.startPrank(_iporProtocolRouter);
        ISpread60Days(_router).calculateAndUpdateOfferedRatePayFixed60Days(_spreadInputs);
        ISpread60Days(_router).calculateAndUpdateOfferedRateReceiveFixed60Days(_spreadInputs);
        ISpread60DaysLens(_router).calculateOfferedRatePayFixed60Days(_spreadInputs);
        ISpread60DaysLens(_router).calculateOfferedRateReceiveFixed60Days(_spreadInputs);
        ISpread60DaysLens(_router).spreadFunction60DaysConfig();
        vm.stopPrank();
    }

    function testShouldBeAbleRun90DaysMethod() external {
        // given

        // when
        vm.startPrank(_iporProtocolRouter);
        ISpread90Days(_router).calculateAndUpdateOfferedRatePayFixed90Days(_spreadInputs);
        ISpread90Days(_router).calculateAndUpdateOfferedRateReceiveFixed90Days(_spreadInputs);
        ISpread90DaysLens(_router).calculateOfferedRatePayFixed90Days(_spreadInputs);
        ISpread90DaysLens(_router).calculateOfferedRateReceiveFixed90Days(_spreadInputs);
        ISpread90DaysLens(_router).spreadFunction90DaysConfig();
        vm.stopPrank();
    }

    function testShouldNotBeAbleToCallCalculateAndUpdateOfferedRate28DaysWhenNotAmmRouter() external {
        //when
        vm.expectRevert(bytes(AmmErrors.SENDER_NOT_AMM));
        ISpread28Days(_router).calculateAndUpdateOfferedRatePayFixed28Days(_spreadInputs);
        vm.expectRevert(bytes(AmmErrors.SENDER_NOT_AMM));
        ISpread28Days(_router).calculateAndUpdateOfferedRateReceiveFixed28Days(_spreadInputs);
    }

    function testShouldNotBeAbleToCallCalculateAndUpdateOfferedRate28DaysWhenPaused() external {
        //given
        vm.prank(_owner);
        SpreadAccessControl(_router).pause();

        //when
        vm.startPrank(_iporProtocolRouter);
        vm.expectRevert(bytes(IporErrors.METHOD_PAUSED));
        ISpread28Days(_router).calculateAndUpdateOfferedRatePayFixed28Days(_spreadInputs);
        vm.expectRevert(bytes(IporErrors.METHOD_PAUSED));
        ISpread28Days(_router).calculateAndUpdateOfferedRateReceiveFixed28Days(_spreadInputs);
        vm.stopPrank();
    }

    function testShouldNotBeAbleToCallCalculateAndUpdateOfferedRate60DaysWhenNotAmmRouter() external {
        //when
        vm.expectRevert(bytes(AmmErrors.SENDER_NOT_AMM));
        ISpread60Days(_router).calculateAndUpdateOfferedRatePayFixed60Days(_spreadInputs);
        vm.expectRevert(bytes(AmmErrors.SENDER_NOT_AMM));
        ISpread60Days(_router).calculateAndUpdateOfferedRateReceiveFixed60Days(_spreadInputs);
    }

    function testShouldNotBeAbleToCallCalculateAndUpdateOfferedRate60DaysWhenPaused() external {
        //given
        vm.prank(_owner);
        SpreadAccessControl(_router).pause();

        //when
        vm.startPrank(_iporProtocolRouter);
        vm.expectRevert(bytes(IporErrors.METHOD_PAUSED));
        ISpread60Days(_router).calculateAndUpdateOfferedRatePayFixed60Days(_spreadInputs);
        vm.expectRevert(bytes(IporErrors.METHOD_PAUSED));
        ISpread60Days(_router).calculateAndUpdateOfferedRateReceiveFixed60Days(_spreadInputs);
        vm.stopPrank();
    }

    function testShouldNotBeAbleToCallCalculateAndUpdateOfferedRate90DaysWhenNotAmmRouter() external {
        //when
        vm.expectRevert(bytes(AmmErrors.SENDER_NOT_AMM));
        ISpread90Days(_router).calculateAndUpdateOfferedRatePayFixed90Days(_spreadInputs);
        vm.expectRevert(bytes(AmmErrors.SENDER_NOT_AMM));
        ISpread90Days(_router).calculateAndUpdateOfferedRateReceiveFixed90Days(_spreadInputs);
    }
    function testShouldNotBeAbleToCallCalculateAndUpdateOfferedRate90DaysWhenPaused() external {
        //given
        vm.prank(_owner);
        SpreadAccessControl(_router).pause();

        //when
        vm.startPrank(_iporProtocolRouter);
        vm.expectRevert(bytes(IporErrors.METHOD_PAUSED));
        ISpread90Days(_router).calculateAndUpdateOfferedRatePayFixed90Days(_spreadInputs);
        vm.expectRevert(bytes(IporErrors.METHOD_PAUSED));
        ISpread90Days(_router).calculateAndUpdateOfferedRateReceiveFixed90Days(_spreadInputs);
        vm.stopPrank();
    }

    function testShouldNotBeAbleToAddGuardianWhenNotOwner() external {
        //given
        address user = _getUserAddress(12);
        bool isGuardianBefore = SpreadAccessControl(_router).isPauseGuardian(user);

        //when
        vm.expectRevert(bytes(IporErrors.CALLER_NOT_OWNER));
        SpreadAccessControl(_router).addPauseGuardian(user);

        //then
        bool isGuardianAfter = SpreadAccessControl(_router).isPauseGuardian(user);

        assertEq(isGuardianBefore, isGuardianAfter, "isGuardianBefore");
    }

    function testShouldNotBeAbleToRemoveGuardianWhenNotOwner() external {
        //given
        address user = _getUserAddress(12);
        vm.prank(_owner);
        SpreadAccessControl(_router).addPauseGuardian(user);
        bool isGuardianBefore = SpreadAccessControl(_router).isPauseGuardian(user);

        //when
        vm.expectRevert(bytes(IporErrors.CALLER_NOT_OWNER));
        SpreadAccessControl(_router).removePauseGuardian(user);

        //then
        bool isGuardianAfter = SpreadAccessControl(_router).isPauseGuardian(user);

        assertEq(isGuardianBefore, isGuardianAfter, "isGuardianBefore");
    }
}
