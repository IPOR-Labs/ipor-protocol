// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";

contract AmmSwapLensOfferedRateTest is TestCommons {
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
        _cfg.iporRiskManagementOracleUpdater = _userOne;

        _ammCfg.iporOracleUpdater = _userOne;
        _ammCfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldCalculateOfferedRateForFirstSwap28Days() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 3e16);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        // when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = _iporProtocol.ammSwapsLens.getOfferedRate(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28,
            1000 * 1e18,
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), PAY_FIXED, IporTypes.SwapTenor.DAYS_28, 280),
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), RECEIVE_FIXED, IporTypes.SwapTenor.DAYS_28, 280)
        );
        // then
        assertEq(offeredRatePayFixed, 31003188775510204);
        assertEq(offeredRateReceiveFixed, 28996811224489796);
    }

    function testShouldCalculateOfferedRateForFirstBigSwap28Days() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 3e16);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), uint256(IporTypes.SwapTenor.DAYS_28))
        );
        vm.stopPrank();

        // when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = _iporProtocol.ammSwapsLens.getOfferedRate(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28,
            1_000 * 1e18,
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), PAY_FIXED, IporTypes.SwapTenor.DAYS_28, 280),
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), RECEIVE_FIXED, IporTypes.SwapTenor.DAYS_28, 280)
        );
        // then
        assertEq(offeredRatePayFixed, 31975898302988162);
        assertEq(offeredRateReceiveFixed, 29000000000000000);
    }

    function testShouldCalculateOfferedRateForSecondSwap28Days() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 3e16);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        // when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = _iporProtocol.ammSwapsLens.getOfferedRate(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28,
            1_000_000_000 * 1e18,
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), PAY_FIXED, IporTypes.SwapTenor.DAYS_28, 280),
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), RECEIVE_FIXED, IporTypes.SwapTenor.DAYS_28, 280)
        );
        // then
        assertEq(offeredRatePayFixed, 181000000000000000);
        assertEq(offeredRateReceiveFixed, 0);
    }

    function testShouldCalculateOfferedRateForFirstSwap60Days() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 3e16);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        // when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = _iporProtocol.ammSwapsLens.getOfferedRate(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_60,
            1000 * 1e18,
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), PAY_FIXED, IporTypes.SwapTenor.DAYS_60, 600),
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), RECEIVE_FIXED, IporTypes.SwapTenor.DAYS_60, 600)
        );
        // then
        assertEq(offeredRatePayFixed, 31001488095238096);
        assertEq(offeredRateReceiveFixed, 28998511904761904);
    }

    function testShouldCalculateOfferedRateForFirstSwap90Days() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 3e16);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        // when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = _iporProtocol.ammSwapsLens.getOfferedRate(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_90,
            1000 * 1e18,
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), PAY_FIXED, IporTypes.SwapTenor.DAYS_90, 900),
            getRiskIndicatorsInputsWithTenor(address(_iporProtocol.asset), RECEIVE_FIXED, IporTypes.SwapTenor.DAYS_90, 900)
        );
        // then
        assertEq(offeredRatePayFixed, 31000992063492064);
        assertEq(offeredRateReceiveFixed, 28999007936507936);
    }

    function getRiskIndicatorsInputsWithTenor(
        address asset,
        uint direction,
        IporTypes.SwapTenor tenor,
        uint demandSpreadFactor
    ) internal returns (AmmTypes.RiskIndicatorsInputs memory) {
        console2.log("uint256(tenor)*10: ", uint256(tenor) * 10);
        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: direction == 0 ? int256(1000000000000000) : int256(-1000000000000000),
            fixedRateCapPerLeg: direction == 0 ? 20000000000000000 : 35000000000000000,
            demandSpreadFactor: demandSpreadFactor,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(asset),
            uint256(tenor),
            direction,
            _iporProtocolFactory.messageSignerPrivateKey()
        );
        return riskIndicatorsInputs;
    }

}
