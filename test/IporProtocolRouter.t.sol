// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./TestCommons.sol";
import "contracts/libraries/errors/IporErrors.sol";

contract IporProtocolRouterTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;

        _ammCfg.iporOracleUpdater = _userOne;
    }

    function testSwitchImplementation() public {
        // given
        IporProtocolRouterBuilder builder = new IporProtocolRouterBuilder(address(this));
        IporProtocolRouter router = builder.buildEmptyProxy();

        address newImplementation = address(new EmptyRouterImplementation());
        address oldImplementation = router.getImplementation();
        // when
        router.upgradeTo(newImplementation);

        // then
        assertTrue(
            router.getImplementation() == newImplementation,
            "Implementation should be equal to newImplementation"
        );
        assertTrue(router.getImplementation() != oldImplementation, "Implementation should be changed");
    }

    function testNotAllowExecuteMethodsWhichAreOnlyForOwner() public {
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.startPrank(_userOne);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _userOne);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammGovernanceService.removeSwapLiquidator(address(_iporProtocol.asset), _userOne);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), _userOne);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammGovernanceService.removeAppointedToRebalanceInAmm(address(_iporProtocol.asset), _userOne);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammGovernanceService.depositToAssetManagement(address(_iporProtocol.asset), 1e18);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammGovernanceService.withdrawFromAssetManagement(address(_iporProtocol.asset), 1e18);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammGovernanceService.withdrawAllFromAssetManagement(address(_iporProtocol.asset));

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(address(_iporProtocol.asset), 1, 1, 1);

        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = 1;

        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInputs = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );
        vm.expectRevert("IPOR_014");
        _iporProtocol.ammCloseSwapServiceUsdt.emergencyCloseSwapsUsdt(swapIds, swapIds, riskIndicatorsInputs);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammCloseSwapServiceUsdc.emergencyCloseSwapsUsdc(swapIds, swapIds, riskIndicatorsInputs);

        vm.expectRevert("IPOR_014");
        _iporProtocol.ammCloseSwapServiceDai.emergencyCloseSwapsDai(swapIds, swapIds, riskIndicatorsInputs);

        vm.stopPrank();
    }

    function testAllowExecuteMethodsWhichAreOnlyForOwner() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        _iporProtocolFactory.setupUsers(_cfg, amm.usdt);
        _iporProtocolFactory.setupUsers(_cfg, amm.usdc);
        _iporProtocolFactory.setupUsers(_cfg, amm.dai);
        _iporProtocolFactory.setupUsers(_cfg, amm.stEth);

        amm.dai.ammPoolsService.provideLiquidityDai(_admin, 1000e18);

        vm.startPrank(_admin);

        amm.dai.ammGovernanceService.addSwapLiquidator(address(amm.dai.asset), _userOne);
        amm.dai.ammGovernanceService.removeSwapLiquidator(address(amm.dai.asset), _userOne);
        amm.dai.ammGovernanceService.addAppointedToRebalanceInAmm(address(amm.dai.asset), _userOne);
        amm.dai.ammGovernanceService.removeAppointedToRebalanceInAmm(address(amm.dai.asset), _userOne);
        amm.dai.ammGovernanceService.depositToAssetManagement(address(amm.dai.asset), 100e18);
        amm.dai.ammGovernanceService.withdrawFromAssetManagement(address(amm.dai.asset), 1e18);
        amm.dai.ammGovernanceService.withdrawAllFromAssetManagement(address(amm.dai.asset));
        amm.dai.ammGovernanceService.setAmmPoolsParams(address(amm.dai.asset), 100_000, 100_000, 1);

        amm.dai.ammPoolsService.provideLiquidityDai(_userOne, 10000e18);
        amm.usdt.ammPoolsService.provideLiquidityUsdt(_userOne, 10000e6);
        amm.usdc.ammPoolsService.provideLiquidityUsdc(_userOne, 10000e6);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(amm.usdt.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        amm.usdt.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userOne,
            TestConstants.USD_1_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(amm.usdc.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        amm.usdc.ammOpenSwapService.openSwapPayFixed28daysUsdc(
            _userOne,
            TestConstants.USD_1_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(amm.dai.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        amm.dai.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userOne,
            TestConstants.USD_1_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(amm.usdt.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        amm.usdt.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userOne,
            TestConstants.USD_1_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(amm.usdc.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        amm.usdc.ammOpenSwapService.openSwapReceiveFixed28daysUsdc(
            _userOne,
            TestConstants.USD_1_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        amm.dai.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userOne,
            TestConstants.USD_1_000_18DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(amm.dai.asset), 1)
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 2;
        amm.usdt.ammCloseSwapServiceUsdt.emergencyCloseSwapsUsdt(
            swapPfIds,
            swapRfIds,
            getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28)
        );
        amm.usdc.ammCloseSwapServiceUsdc.emergencyCloseSwapsUsdc(
            swapPfIds,
            swapRfIds,
            getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28)
        );
        amm.dai.ammCloseSwapServiceDai.emergencyCloseSwapsDai(
            swapPfIds,
            swapRfIds,
            getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28)
        );

        vm.stopPrank();
    }

    function testCheckAddressesInConstructor() public {
        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: address(0),
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: address(0),
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );
        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: address(0),
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: address(0),
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: address(0),
                ammOpenSwapServiceStEth: address(0),
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: address(0),
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: address(0),
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: address(0),
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: address(0),
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: address(0),
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: address(0),
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: address(0),
                flowService: _userOne,
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: address(0),
                stakeService: _userOne,
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );

        vm.expectRevert("IPOR_000");
        new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _userOne,
                ammPoolsLens: _userOne,
                ammPoolsLensStEth: _userOne,
                assetManagementLens: _userOne,
                ammOpenSwapService: _userOne,
                ammOpenSwapServiceStEth: _userOne,
                ammCloseSwapServiceUsdt: _userOne,
                ammCloseSwapServiceUsdc: _userOne,
                ammCloseSwapServiceDai: _userOne,
                ammCloseSwapLens: _userOne,
                ammCloseSwapServiceStEth: _userOne,
                ammPoolsService: _userOne,
                ammPoolsServiceStEth: _userOne,
                ammGovernanceService: _userOne,
                liquidityMiningLens: _userOne,
                powerTokenLens: _userOne,
                flowService: _userOne,
                stakeService: address(0),
                ammPoolsServiceWeEth: _userOne,
                ammPoolsLensWeEth: _userOne,
                ammPoolsServiceUsdm: _userOne,
                ammPoolsLensUsdm: _userOne
            })
        );
    }

    function testReentranceInBatchSimpleCase() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        bytes memory calldataProvideLiquidity = abi.encodeWithSignature(
            "provideLiquidityDai(address,uint256)",
            _userOne,
            TestConstants.USD_28_000_18DEC
        );

        bytes[] memory reentrancyCalls = new bytes[](1);
        reentrancyCalls[0] = calldataProvideLiquidity;

        bytes memory calldataOpenSwap = abi.encodeWithSignature("batchExecutor(bytes[])", reentrancyCalls);

        bytes[] memory requestData = new bytes[](2);
        requestData[0] = calldataProvideLiquidity;
        requestData[1] = calldataOpenSwap;

        vm.prank(_userOne);
        //then
        vm.expectRevert("IPOR_012");
        // when
        _iporProtocol.router.batchExecutor(requestData);
    }
}
