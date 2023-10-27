// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../contracts/interfaces/IAmmGovernanceLens.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";

contract AmmGovernanceServiceTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
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
        _cfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldSetupMaxAllowanceInAmmTreasury() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        //when
        _iporProtocol.ammTreasury.grantMaxAllowanceForSpender(address(_userOne));

        //then
        uint256 allowance = _iporProtocol.asset.allowance(address(_iporProtocol.ammTreasury), address(_userOne));

        assertEq(allowance, type(uint256).max);
    }

    function testShouldSetupZeroAllowanceInAmmTreasury() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.ammTreasury.grantMaxAllowanceForSpender(address(_userOne));

        //when
        _iporProtocol.ammTreasury.revokeAllowanceForSpender(address(_userOne));

        //then
        uint256 allowance = _iporProtocol.asset.allowance(address(_iporProtocol.ammTreasury), address(_userOne));

        assertEq(allowance, 0);
    }

    function testShouldReturnDefaultAmmTreasuryAssetManagementBalanceRatio() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        IAmmGovernanceLens.AmmPoolsParamsConfiguration memory ammParams = _iporProtocol
            .ammGovernanceLens
            .getAmmPoolsParams(address(_iporProtocol.asset));

        // then
        assertEq(ammParams.ammTreasuryAndAssetManagementRatio, 8500);
    }

    function testShouldChangeAmmTreasuryAssetManagementBalanceRatio() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.startPrank(_admin);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(address(_iporProtocol.asset), 1000000000, 50, 5000);
        vm.stopPrank();

        // then
        IAmmGovernanceLens.AmmPoolsParamsConfiguration memory ammParams = _iporProtocol
            .ammGovernanceLens
            .getAmmPoolsParams(address(_iporProtocol.asset));
        assertEq(ammParams.ammTreasuryAndAssetManagementRatio, 5000);
    }

    function testShouldChangeAmmTreasuryAssetManagementBalanceRatioWhenNewRatioIsZero() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(address(_iporProtocol.asset), 1000000000, 50, 0);

        // then
        IAmmGovernanceLens.AmmPoolsParamsConfiguration memory ammParams = _iporProtocol
            .ammGovernanceLens
            .getAmmPoolsParams(address(_iporProtocol.asset));
        assertEq(ammParams.ammTreasuryAndAssetManagementRatio, 0);
    }

    function testShouldNotChangeAmmTreasuryAssetManagementBalanceRatioWhenNewRatioIsGreaterThanOne() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        vm.expectRevert("IPOR_408");
        _iporProtocol.ammGovernanceService.setAmmPoolsParams(address(_iporProtocol.asset), 1000000000, 50, 10000);
    }

    function testShouldNotTransferPublicationFeToCharlieTreasuryWhenCallerIsNotPublicationFeeTransferer() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_406");
        vm.prank(_userThree);
        _iporProtocol.ammGovernanceService.transferToCharlieTreasury(address(_iporProtocol.asset), 100);
    }

    function testShouldTransferPublicationFeeToCharlieTreasurySimpleCase1() public {
        // given
        _cfg.ammCharlieTreasuryManager = _userThree;
        _cfg.ammCharlieTreasury = _userOne;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 transferredAmount = 100;
        uint256 expectedERC20BalanceCharlieTreasury = TestConstants.USER_SUPPLY_10MLN_18DEC + transferredAmount;
        uint256 expectedERC20BalanceAmmTreasury = TestConstants.USD_28_000_18DEC +
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC -
            transferredAmount;

        uint256 expectedPublicationFeeBalanceAmmTreasury = TestConstants.USD_10_18DEC - transferredAmount;
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

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
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        // when
        vm.prank(_userThree);
        _iporProtocol.ammGovernanceService.transferToCharlieTreasury(address(_iporProtocol.asset), transferredAmount);

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        uint256 actualERC20BalanceCharlieTreasury = _iporProtocol.asset.balanceOf(_userOne);
        uint256 actualERC20BalanceAmmTreasury = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        uint256 actualPublicationFeeBalanceAmmTreasury = balance.iporPublicationFee;

        assertEq(actualERC20BalanceCharlieTreasury, expectedERC20BalanceCharlieTreasury);
        assertEq(actualERC20BalanceAmmTreasury, expectedERC20BalanceAmmTreasury);
        assertEq(actualPublicationFeeBalanceAmmTreasury, expectedPublicationFeeBalanceAmmTreasury);
    }

    function testShouldNotTransferToTreasuryWhenCallerIsNotTreasuryTransferer() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        // when
        vm.expectRevert("IPOR_404");
        vm.prank(_userThree);
        _iporProtocol.ammGovernanceService.transferToTreasury(address(_iporProtocol.asset), 100);
    }

    function testShouldTransferTreasuryToTreasuryTreasurerWhenSimpleCase1() public {
        // given
        _cfg.ammPoolsTreasuryManager = _userThree;
        _cfg.ammPoolsTreasury = _userOne;
        _cfg.openSwapServiceTestCase = BuilderUtils.AmmOpenSwapServiceTestCase.CASE2;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 transferredAmount = 100;
        uint256 expectedERC20BalanceTreasury = TestConstants.USER_SUPPLY_10MLN_18DEC + transferredAmount;
        uint256 expectedERC20BalanceAmmTreasury = TestConstants.USD_28_000_18DEC +
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC -
            transferredAmount;
        uint256 expectedTreasuryBalance = 114696891674244800;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

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
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        // when
        vm.prank(_userThree);
        _iporProtocol.ammGovernanceService.transferToTreasury(address(_iporProtocol.asset), transferredAmount);

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        uint256 actualERC20BalanceTreasury = _iporProtocol.asset.balanceOf(_userOne);
        uint256 actualERC20BalanceAmmTreasury = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));

        assertEq(actualERC20BalanceTreasury, expectedERC20BalanceTreasury);
        assertEq(actualERC20BalanceAmmTreasury, expectedERC20BalanceAmmTreasury);
        assertEq(balance.treasury, expectedTreasuryBalance);
    }
}
