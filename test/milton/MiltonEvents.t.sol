// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonSpreadCoreTest is Test, TestCommons {
    MockSpreadModel internal _miltonSpreadModel;
	ProxyTester internal _iporOracleProxy;
	ItfIporOracle internal _iporOracle;
	ProxyTester internal _miltonDaiProxy;
	ItfMiltonDai miltonDai = new ItfMiltonDai();
	ProxyTester internal _josephDaiProxy;
	ItfJosephDai josephDai = new ItfJosephDai();
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
        _miltonSpreadModel = new MockSpreadModel(0, 0, 0, 0);
		_iporOracleProxy = new ProxyTester();
		_iporOracle = new ItfIporOracle();
		_admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
		_liquidityProvider = _getUserAddress(4);
		// set proxy type
		_iporOracleProxy.setType("uups");
		_miltonDaiProxy.setType("uups");
		_josephDaiProxy.setType("uups");
    }

	function getIporOracle(DaiMockedToken daiMockedToken) public returns (ItfIporOracle) {
		// ------------ Start initialize oracle ------------
		address[] memory assets = new address[](1);
		assets[0] = address(daiMockedToken);
		uint32[] memory updateTimestamps = new uint32[](1);
		updateTimestamps[0] = uint32(block.timestamp);
		uint64[] memory exponentialMovingAverages = new uint64[](1);
		exponentialMovingAverages[0] = 0;
		uint64[] memory exponentialWeightedMovingVariances = new uint64[](1);
		exponentialWeightedMovingVariances[0] = 0;
		// ------------ End initialize oracle ------------
		// ------------ Start oracle proxy setup ------------
		address iporOracleProxyAddress = _iporOracleProxy.deploy(address(_iporOracle), _admin, abi.encodeWithSignature("initialize(address[],uint32[],uint64[],uint64[])", assets, updateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances));
		ItfIporOracle iporOracle = ItfIporOracle(iporOracleProxyAddress);
		return iporOracle;
		// ------------ End oracle proxy setup ------------
	}

	function testShouldEmitEventWhenOpenPayFixedSwap18Decimals() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(4 * 10**16);
		DaiMockedToken daiMockedToken = new DaiMockedToken(1*10**18, 18);
		// ItfMiltonDai miltonDai = new ItfMiltonDai();
		// ItfJosephDai josephDai = new ItfJosephDai();
		uint256 openTimestamp = 1671558470;
		uint256 endTimestamp = 1671840070;
		address[] memory users = new address[](5);
		users[0] = _admin;
		users[1] = _userOne;
		users[2] = _userTwo;
		users[3] = _userThree;
		users[4] = _liquidityProvider;
		// when
		for (uint256 i=0; i < users.length; ++i) {
			vm.prank(users[i]);
			daiMockedToken.approve(address(josephDai), 1*10**16 * 10**18);	
			daiMockedToken.approve(address(miltonDai), 1*10**16 * 10**18);
			daiMockedToken.setupInitialAmount(users[i], 1*10**17 * 10**18);
		}
		ItfIporOracle iporOracle = getIporOracle(daiMockedToken); 
		vm.prank(address(_iporOracleProxy));
		iporOracle.addUpdater(_userOne);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(daiMockedToken), 3*10**16, openTimestamp); // random timestamp
		vm.prank(_liquidityProvider);
		josephDai.itfProvideLiquidity(28000 * 10**18, openTimestamp);
		vm.prank(_userTwo);
		vm.expectEmit(true, true, false, true);
		emit OpenSwap(
			1, // swapId
			_userTwo, // buyer
			address(daiMockedToken), // asset
			MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
			AmmTypes.OpenSwapMoney({
				totalAmount: 10000 * 10**18, // totalAmount
				collateral: 9967009897030890732780, // collateral
				notional: 99670098970308907327800, // notional
				openingFeeLPAmount: 2990102969109267220, // openingFeeLPAmount
				openingFeeTreasuryAmount: 0, // openingFeeTreasuryAmount
				iporPublicationFee: 10, // iporPublicationFee
				liquidationDepositAmount: 20 // liquidationDepositAmount
			}), // money
			openTimestamp, // openTimestamp
			endTimestamp, // endTimestamp
			MiltonTypes.IporSwapIndicator({
				iporIndexValue: 3 * 10**16, // iporIndexValue
				ibtPrice: 1 * 10**18, // ibtPrice
				ibtQuantity: 99670098970308907327800, // ibtQuantity
				fixedInterestRate: 4 * 10**16 // fixedInterestRate
			}) // indicator
		);
		miltonDai.itfOpenSwapPayFixed(
			openTimestamp, // openTimestamp
			10000 * 10**18, // totalAmount
			1*10**16, // acceptableFixedInterestRate
			10 * 10**18 // leverage
		);
		// when
		// then
		// assertEq(iporOracleProxyAddress, _iporOracleProxy.proxyAddress());
		// assertEq(iporOracleProxyAddress, address(_iporOracleProxy.uups()));
	}

}