// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonDai.sol";
import "../../contracts/amm/MiltonUsdc.sol";
import "../../contracts/amm/MiltonUsdt.sol";
import "../../contracts/mocks/stanley/aave/TestERC20.sol";
import "../../contracts/interfaces/IMiltonInternal.sol";

contract MiltonConfiguration is Test, TestCommons {
    MiltonUsdt internal _miltonUsdt;
    MiltonUsdc internal _miltonUsdc;
    MiltonDai internal _miltonDai;

    function setUp() public {
        _miltonUsdt = new MiltonUsdt(address(0));
        _miltonUsdc = new MiltonUsdc(address(0));
        _miltonDai = new MiltonDai(address(0));
    }

    function testShouldCreateMiltonUsdt() public {
        // when
        TestERC20 usdt = new TestERC20(2**255);
        usdt.setDecimals(6);
        MiltonUsdt miltonUsdtImplementation = new MiltonUsdt(address(usdt));
        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(miltonUsdtImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(usdt),
                address(usdt),
                address(usdt),
                address(usdt),
                address(usdt)
            )
        );
        IMiltonInternal miltonUsdt = IMiltonInternal(address(miltonUsdtProxy));
        assertEq(miltonUsdt.getAsset(), address(usdt));
    }

    function testShouldCreateMiltonUsdc() public {
        // when
        TestERC20 usdc = new TestERC20(2**255);
        usdc.setDecimals(6);
        MiltonUsdc miltonUsdcImplementation = new MiltonUsdc(address(usdc));
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(miltonUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(usdc),
                address(usdc),
                address(usdc),
                address(usdc),
                address(usdc)
            )
        );
        IMiltonInternal miltonUsdc = IMiltonInternal(address(miltonUsdcProxy));
        assertEq(miltonUsdc.getAsset(), address(usdc));
    }

    function testShouldCreateMiltonDai() public {
        // when
        TestERC20 dai = new TestERC20(2**255);
        dai.setDecimals(18);
        MiltonDai miltonDaiImplementation = new MiltonDai(address(dai));
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(miltonDaiImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(dai),
                address(dai),
                address(dai),
                address(dai),
                address(dai)
            )
        );
        IMiltonInternal miltonDai = IMiltonInternal(address(miltonDaiProxy));
        assertEq(miltonDai.getAsset(), address(dai));
    }

    function testShouldRevertInitializerUsdtWhenMismatchAssetAndMiltonDecimals() public {
        // when
        TestERC20 usdt = new TestERC20(2**255);
        usdt.setDecimals(8);
        MiltonUsdt miltonUsdtImplementation = new MiltonUsdt(address(usdt));
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(miltonUsdtImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(usdt),
                address(usdt),
                address(usdt),
                address(usdt),
                address(usdt)
            )
        );
    }

    function testShouldRevertInitializeUsdcWhenMismatchAssetAndMiltonDecimals() public {
        // when
        TestERC20 usdc = new TestERC20(2**255);
        usdc.setDecimals(8);
        MiltonUsdc miltonUsdcImplementation = new MiltonUsdc(address(usdc));
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(miltonUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(usdc),
                address(usdc),
                address(usdc),
                address(usdc),
                address(usdc)
            )
        );
    }

    function testShouldRevertInitializerDaiWhenMismatchAssetAndMiltonDecimals() public {
        // when
        TestERC20 dai = new TestERC20(2**255);
        dai.setDecimals(8);
        MiltonDai miltonDaiImplementation = new MiltonDai(address(dai));
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(miltonDaiImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(dai),
                address(dai),
                address(dai),
                address(dai),
                address(dai)
            )
        );
    }

    function testShouldSetupInitValueForMaxSwapTotalAmount() public {
        // when
        uint256 actualValue = _miltonDai.getMaxSwapCollateralAmount();
        // then
        assertEq(actualValue, TestConstants.USD_100_000_18DEC);
    }

    function testShouldSetupInitValueForIncomeFeePercentage() public {
        // when
        uint256 actualValue = _miltonDai.getIncomeFeeRate();
        // then
        assertEq(actualValue, 1 * TestConstants.D17);
    }

    function testShouldSetupInitValueForOpeningFeePercentage() public {
        // when
        uint256 actualValue = _miltonDai.getOpeningFeeRate();
        // then
        assertEq(actualValue, 1 * TestConstants.D16);
    }

    function testShouldSetupInitValueForOpeningFeeTreasuryPercentage() public {
        // when
        uint256 actualValue = _miltonDai.getOpeningFeeTreasuryPortionRate();
        // then
        assertEq(actualValue, TestConstants.ZERO);
    }

    function testShouldSetupInitValueForIporPublicationFeeAmount() public {
        // when
        uint256 actualValue = _miltonDai.getIporPublicationFee();
        // then
        assertEq(actualValue, 10 * TestConstants.D18);
    }

    function testShouldSetupInitValueForLiquidationDepositAmountMethodOne() public {
        // when
        uint256 actualValue = _miltonDai.getLiquidationDepositAmount();
        // then
        assertEq(actualValue, 25);
    }

    function testShouldSetupInitValueForLiquidationDepositAmountMethodTwo() public {
        // when
        uint256 actualValue = _miltonDai.getWadLiquidationDepositAmount();
        // then
        assertEq(actualValue, 25 * TestConstants.D18);
    }

    function testShouldSetupInitValueForMinLeverageValue() public {
        // when
        uint256 actualValue = _miltonDai.getMinLeverage();
        // then
        assertEq(actualValue, 10 * TestConstants.D18);
    }

    function testShouldInitValueForOpeningFeeTreasuryPercentageLowerThanOneHundredPercent() public {
        // when
        uint256 actualValue = _miltonDai.getOpeningFeeTreasuryPortionRate();
        // then
        assertLe(actualValue, TestConstants.PERCENTAGE_100_18DEC);
    }

    function testShouldInitValueForIncomeFeePercentageLowerThanHundredPercent() public {
        // when
        uint256 actualValue = _miltonDai.getIncomeFeeRate();
        // then
        assertLe(actualValue, TestConstants.PERCENTAGE_100_18DEC);
    }
}
