// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "contracts/amm/AmmTreasuryDai.sol";
import "contracts/amm/AmmTreasuryUsdc.sol";
import "contracts/amm/AmmTreasuryUsdt.sol";
import "contracts/mocks/assetManagement/aave/TestERC20.sol";
import "contracts/interfaces/IAmmTreasury.sol";

contract AmmTreasuryConfiguration is Test, TestCommons {
    AmmTreasuryUsdt internal _ammTreasuryUsdt;
    AmmTreasuryUsdc internal _ammTreasuryUsdc;
    AmmTreasuryDai internal _ammTreasuryDai;

    function setUp() public {
        address fakeRiskOracle = address(this);
        _ammTreasuryUsdt = new AmmTreasuryUsdt(fakeRiskOracle);
        _ammTreasuryUsdc = new AmmTreasuryUsdc(fakeRiskOracle);
        _ammTreasuryDai = new AmmTreasuryDai(fakeRiskOracle);
    }

    function testShouldCreateAmmTreasuryUsdt() public {
        // when
        TestERC20 usdt = new TestERC20(2**255);
        usdt.setDecimals(6);
        AmmTreasuryUsdt ammTreasuryUsdtImplementation = new AmmTreasuryUsdt(address(usdt));
        ERC1967Proxy ammTreasuryUsdtProxy = new ERC1967Proxy(
            address(ammTreasuryUsdtImplementation),
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
        IAmmTreasury ammTreasuryUsdt = IAmmTreasury(address(ammTreasuryUsdtProxy));
        assertEq(ammTreasuryUsdt.getAsset(), address(usdt));
    }

    function testShouldCreateAmmTreasuryUsdc() public {
        // when
        TestERC20 usdc = new TestERC20(2**255);
        usdc.setDecimals(6);
        AmmTreasuryUsdc ammTreasuryUsdcImplementation = new AmmTreasuryUsdc(address(usdc));
        ERC1967Proxy ammTreasuryUsdcProxy = new ERC1967Proxy(
            address(ammTreasuryUsdcImplementation),
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
        IAmmTreasury ammTreasuryUsdc = IAmmTreasury(address(ammTreasuryUsdcProxy));
        assertEq(ammTreasuryUsdc.getAsset(), address(usdc));
    }

    function testShouldCreateAmmTreasuryDai() public {
        // when
        TestERC20 dai = new TestERC20(2**255);
        dai.setDecimals(18);
        AmmTreasuryDai ammTreasuryDaiImplementation = new AmmTreasuryDai(address(dai));
        ERC1967Proxy ammTreasuryDaiProxy = new ERC1967Proxy(
            address(ammTreasuryDaiImplementation),
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
        IAmmTreasury ammTreasuryDai = IAmmTreasury(address(ammTreasuryDaiProxy));
        assertEq(ammTreasuryDai.getAsset(), address(dai));
    }

    function testShouldRevertInitializerUsdtWhenMismatchAssetAndAmmTreasuryDecimals() public {
        // when
        TestERC20 usdt = new TestERC20(2**255);
        usdt.setDecimals(8);
        AmmTreasuryUsdt ammTreasuryUsdtImplementation = new AmmTreasuryUsdt(address(usdt));
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        new ERC1967Proxy(
            address(ammTreasuryUsdtImplementation),
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

    function testShouldRevertInitializeUsdcWhenMismatchAssetAndAmmTreasuryDecimals() public {
        // when
        TestERC20 usdc = new TestERC20(2**255);
        usdc.setDecimals(8);
        AmmTreasuryUsdc ammTreasuryUsdcImplementation = new AmmTreasuryUsdc(address(usdc));
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        new ERC1967Proxy(
            address(ammTreasuryUsdcImplementation),
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

    function testShouldRevertInitializerDaiWhenMismatchAssetAndAmmTreasuryDecimals() public {
        // when
        TestERC20 dai = new TestERC20(2**255);
        dai.setDecimals(8);
        AmmTreasuryDai ammTreasuryDaiImplementation = new AmmTreasuryDai(address(dai));
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        new ERC1967Proxy(
            address(ammTreasuryDaiImplementation),
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
        uint256 actualValue = _ammTreasuryDai.getMaxSwapCollateralAmount();
        // then
        assertEq(actualValue, TestConstants.USD_100_000_18DEC);
    }

    function testShouldSetupInitValueForOpeningFeePercentage() public {
        // when
        uint256 actualValue = _ammTreasuryDai.getOpeningFeeRate();
        // then
        assertEq(actualValue, 5 * TestConstants.D14);
    }

    function testShouldSetupInitValueForOpeningFeeTreasuryPercentage() public {
        // when
        uint256 actualValue = _ammTreasuryDai.getOpeningFeeTreasuryPortionRate();
        // then
        assertEq(actualValue, 5 * TestConstants.D17);
    }

    function testShouldSetupInitValueForIporPublicationFeeAmount() public {
        // when
        uint256 actualValue = _ammTreasuryDai.getIporPublicationFee();
        // then
        assertEq(actualValue, 10 * TestConstants.D18);
    }

    function testShouldSetupInitValueForLiquidationDepositAmountMethodOne() public {
        // when
        uint256 actualValue = _ammTreasuryDai.getLiquidationDepositAmount();
        // then
        assertEq(actualValue, 25);
    }

    function testShouldSetupInitValueForLiquidationDepositAmountMethodTwo() public {
        // when
        uint256 actualValue = _ammTreasuryDai.getWadLiquidationDepositAmount();
        // then
        assertEq(actualValue, 25 * TestConstants.D18);
    }

    function testShouldSetupInitValueForMinLeverageValue() public {
        // when
        uint256 actualValue = _ammTreasuryDai.getMinLeverage();
        // then
        assertEq(actualValue, 10 * TestConstants.D18);
    }

    function testShouldInitValueForOpeningFeeTreasuryPercentageLowerThanOneHundredPercent() public {
        // when
        uint256 actualValue = _ammTreasuryDai.getOpeningFeeTreasuryPortionRate();
        // then
        assertLe(actualValue, TestConstants.PERCENTAGE_100_18DEC);
    }
}
