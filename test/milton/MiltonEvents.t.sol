// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import  {DataUtils} from "../utils/DataUtils.sol";
import  {MiltonUtils} from "../utils/MiltonUtils.sol";
import  {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import  {JosephUtils} from "../utils/JosephUtils.sol";
import  {StanleyUtils} from "../utils/StanleyUtils.sol";
import  {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonEventsTest is Test, TestCommons, MiltonUtils, JosephUtils, MiltonStorageUtils, IporOracleUtils, DataUtils, StanleyUtils {
	MockSpreadModel internal _miltonSpreadModel;
	address internal _admin;
	address internal _userOne;
	address internal _userTwo;
	address internal _userThree;
	address internal _liquidityProvider;

    /// @notice Emmited when trader opens new swap.
    event OpenSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction
        MiltonTypes.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapMoney money,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        MiltonTypes.IporSwapIndicator indicator
    );

    /// @notice Emmited when trader closes Swap.
    event CloseSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice underlying asset
        address asset,
        /// @notice the moment when swap was closed
        uint256 closeTimestamp,
        /// @notice account that liquidated the swap
        address liquidator,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator,
        /// @notice incomeFeeValue value transferred to treasury
        uint256 incomeFeeValue
    );

    function setUp() public {
		_miltonSpreadModel = prepareMockSpreadModel(0, 0, 0, 0);
		_admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
		_liquidityProvider = _getUserAddress(4);
    }

	function prepareUsers() public returns(address[] memory) {
		address[] memory users = new address[](5);
		users[0] = _admin;
		users[1] = _userOne;
		users[2] = _userTwo;
		users[3] = _userThree;
		users[4] = _liquidityProvider;
		return users;
	}

	function testShouldEmitEventWhenOpenPayFixedSwap18Decimals() public {
		// given
		DaiMockedToken daiMockedToken = getTokenDai();
		ItfIporOracle iporOracle = getIporOracle(_admin, _userOne, address(daiMockedToken)); 
		IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
		MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
		(ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
		(ProxyTester miltonDaiProxy, ItfMiltonDai miltonDai) = getItfMiltonDai(_admin, address(daiMockedToken), address(iporOracle), address(miltonStorageDai), address(_miltonSpreadModel), address(stanleyDai));
		(ProxyTester josephDaiProxy, ItfJosephDai josephDai) = getItfJosephDai(_admin, address(daiMockedToken), address(ipTokenDai), address(miltonDai), address(miltonStorageDai), address(stanleyDai));
		address[] memory users = prepareUsers();
		prepareApproveForUsersDai(users, daiMockedToken, address(josephDai), address(miltonDai));
		prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(josephDai), address(miltonDai));
		prepareItfMiltonDai(miltonDai, address(miltonDaiProxy), address(josephDai), address(stanleyDai));
		prepareItfJosephDai(josephDai, address(josephDaiProxy));
		prepareIpTokenDai(ipTokenDai, address(josephDai));
		// when
		_miltonSpreadModel.setCalculateQuotePayFixed(4 * 10**16);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(daiMockedToken), 3*10**16, block.timestamp); // random timestamp
		vm.prank(_liquidityProvider);
		josephDai.itfProvideLiquidity(28000*Constants.D18, block.timestamp);
		vm.prank(_userTwo);
		// vm.expectEmit(true, true, false, true);
		vm.expectEmit(true, true, false, false);
		emit OpenSwap(
			1, // swapId
			_userTwo, // buyer
			address(daiMockedToken), // asset
			MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
			AmmTypes.OpenSwapMoney({
				totalAmount: 10000 * Constants.D18, // totalAmount
				collateral: 9967009897030890732780, // collateral
				notional: 99670098970308907327800, // notional
				openingFeeLPAmount: 2990102969109267220, // openingFeeLPAmount
				openingFeeTreasuryAmount: 0, // openingFeeTreasuryAmount
				iporPublicationFee: 10 * Constants.D18, // iporPublicationFee
				liquidationDepositAmount: 20 * Constants.D18 // liquidationDepositAmount
			}), // money
			block.timestamp, // openTimestamp
			block.timestamp + 86400, // endTimestamp
			MiltonTypes.IporSwapIndicator({
				iporIndexValue: 3 * 10**16, // iporIndexValue
				ibtPrice: 1 * Constants.D18, // ibtPrice
				ibtQuantity: 99670098970308907327800, // ibtQuantity
				fixedInterestRate: 4 * 10**16 // fixedInterestRate
			}) // indicator
		);
		miltonDai.itfOpenSwapPayFixed(
			block.timestamp, // openTimestamp
			10000 * Constants.D18, // totalAmount
			6*10**16, // acceptableFixedInterestRate
			10 * Constants.D18 // leverage
		);
	}

}