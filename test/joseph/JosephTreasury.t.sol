// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase4MiltonDai.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/interfaces/IIporRiskManagementOracle.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";

contract JosephTreasuryTest is TestCommons, DataUtils {
    MockSpreadModel _miltonSpreadModel;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenDai;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.PERCENTAGE_2_18DEC,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        _daiMockedToken = getTokenDai();
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldNotTransferPublicationFeToCharlieTreasuryWhenCallerIsNotPublicationFeeTransferer()
        public
    {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // when
        vm.expectRevert("IPOR_406");
        vm.prank(_userThree);
        mockCase0JosephDai.transferToCharlieTreasury(100);
    }

    function testShouldNotTransferPublicationFeToCharlieTreasuryWhenCharlieTreasuryAddressIsIncorrect()
        public
    {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_admin);
        mockCase0JosephDai.setCharlieTreasuryManager(_userThree);
        // when
        vm.expectRevert("IPOR_407");
        vm.prank(_userThree);
        mockCase0JosephDai.transferToCharlieTreasury(100);
    }

    function testShouldTransferPublicationFeeToCharlieTreasurySimpleCase1() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        uint256 transferredAmount = 100;
        uint256 expectedERC20BalanceCharlieTreasury = TestConstants.USER_SUPPLY_10MLN_18DEC +
            transferredAmount;
        uint256 expectedERC20BalanceMilton = TestConstants.USD_28_000_18DEC +
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC -
            transferredAmount;
        uint256 expectedPublicationFeeBalanceMilton = TestConstants.USD_10_18DEC -
            transferredAmount;
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        vm.startPrank(_admin);
        mockCase0JosephDai.setCharlieTreasuryManager(_userThree);
        mockCase0JosephDai.setCharlieTreasury(_userOne);
        vm.stopPrank();
        // when
        vm.prank(_userThree);
        mockCase0JosephDai.transferToCharlieTreasury(transferredAmount);
        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();
        uint256 actualERC20BalanceCharlieTreasury = _daiMockedToken.balanceOf(_userOne);
        uint256 actualERC20BalanceMilton = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        uint256 actualPublicationFeeBalanceMilton = balance.iporPublicationFee;
        assertEq(actualERC20BalanceCharlieTreasury, expectedERC20BalanceCharlieTreasury);
        assertEq(actualERC20BalanceMilton, expectedERC20BalanceMilton);
        assertEq(actualPublicationFeeBalanceMilton, expectedPublicationFeeBalanceMilton);
    }

    function testShouldNotTransferToTreasuryWhenCallerIsNotTreasuryTransferer() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // when
        vm.expectRevert("IPOR_404");
        vm.prank(_userThree);
        mockCase0JosephDai.transferToTreasury(100);
    }

    function testShouldNotTransferPublicationFeeToCharlieTreasuryWhenTreasuryManagerAddressIsIncorrect()
        public
    {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_admin);
        mockCase0JosephDai.setTreasuryManager(_userThree);
        // when
        vm.expectRevert("IPOR_405");
        vm.prank(_userThree);
        mockCase0JosephDai.transferToTreasury(100);
    }

    function testShouldTransferTreasuryToTreasuryTreasurerWhenSimpleCase1() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase4MiltonDai mockCase4MiltonDai = getMockCase4MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase4MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );

        uint256 transferredAmount = 100;

        uint256 expectedERC20BalanceTreasury = TestConstants.USER_SUPPLY_10MLN_18DEC +
            transferredAmount;
        uint256 expectedERC20BalanceMilton = TestConstants.USD_28_000_18DEC +
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC -
            transferredAmount;

        uint256 expectedTreasuryBalance = 114696891674244800;

        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase4MiltonDai)
        );
        prepareMilton(mockCase4MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));

        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userTwo);

        mockCase4MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_admin);
        mockCase0JosephDai.setTreasuryManager(_userThree);
        mockCase0JosephDai.setTreasury(_userOne);
        vm.stopPrank();

        // when
        vm.prank(_userThree);
        mockCase0JosephDai.transferToTreasury(transferredAmount);

        // then
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai
            .getExtendedBalance();

        uint256 actualERC20BalanceTreasury = _daiMockedToken.balanceOf(_userOne);
        uint256 actualERC20BalanceMilton = _daiMockedToken.balanceOf(address(mockCase4MiltonDai));

        assertEq(actualERC20BalanceTreasury, expectedERC20BalanceTreasury);
        assertEq(actualERC20BalanceMilton, expectedERC20BalanceMilton);
        assertEq(balance.treasury, expectedTreasuryBalance);
    }
}
