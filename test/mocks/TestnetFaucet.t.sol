// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "test/TestCommons.sol";
import "test/mocks/tokens/MockTestnetToken.sol";
import "contracts/tokens/IporToken.sol";
import "test/mocks/TestnetFaucet.sol";
import "contracts/interfaces/ITestnetFaucet.sol";
import "./MockOldTestnetFaucet.sol";
import "./IMockProxy.sol";

contract TestnetFaucetTest is Test, TestCommons {
    struct BalanceUserAndFaucet {
        uint256 daiUser;
        uint256 usdcUser;
        uint256 usdtUser;
        uint256 iporUser;
        uint256 daiFaucet;
        uint256 usdcFaucet;
        uint256 usdtFaucet;
        uint256 iporFaucet;
    }

    event TransferFailed(
        /// @notice address to which stable were transfer
        address to,
        /// @notice underlying asset
        address asset,
        /// @notice amount of stable
        uint256 amount
    );

    MockTestnetToken private _daiTestnetToken;
    MockTestnetToken private _usdcTestnetToken;
    MockTestnetToken private _usdtTestnetToken;
    IporToken private _iporToken;
    ERC1967Proxy private _testnetFaucetProxy;
    uint256 private _blockTimestamp;

    function setUp() public {
        _daiTestnetToken = new MockTestnetToken("Mocked DAI", "DAI", 100_000_000 * 1e18, uint8(18));
        _usdcTestnetToken = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
        _usdtTestnetToken = new MockTestnetToken("Mocked USDT", "USDT", 100_000_000 * 1e6, uint8(6));
        _iporToken = new IporToken("Mocked IPOR", "IPOR", address(this));
        TestnetFaucet testnetFaucetImplementation = new TestnetFaucet();
        _testnetFaucetProxy = new ERC1967Proxy(
            address(testnetFaucetImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiTestnetToken),
                address(_usdcTestnetToken),
                address(_usdtTestnetToken),
                address(_iporToken)
            )
        );

        _daiTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e18);
        _usdcTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e6);
        _usdtTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e6);
        _iporToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e18);
        _userOne = _getUserAddress(1);
        _blockTimestamp = 2 * 24 * 60 * 60;
        vm.warp(_blockTimestamp);
    }

    function _getBalances(address user, address testnetFaucet) internal view returns (BalanceUserAndFaucet memory) {
        return
            BalanceUserAndFaucet({
                daiUser: _daiTestnetToken.balanceOf(user),
                usdcUser: _usdcTestnetToken.balanceOf(user),
                usdtUser: _usdtTestnetToken.balanceOf(user),
                iporUser: _iporToken.balanceOf(user),
                daiFaucet: _daiTestnetToken.balanceOf(testnetFaucet),
                usdcFaucet: _usdcTestnetToken.balanceOf(testnetFaucet),
                usdtFaucet: _usdtTestnetToken.balanceOf(testnetFaucet),
                iporFaucet: _iporToken.balanceOf(testnetFaucet)
            });
    }

    function testShouldNotBeAbleToClaimTwice() public {
        // given
        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        vm.startPrank(_userOne);
        BalanceUserAndFaucet memory balanceUserAndFaucetBefore = _getBalances(_userOne, address(_testnetFaucetProxy));
        testnetFaucet.claim();

        // when
        vm.expectRevert(abi.encodePacked("IPOR_600: 86400"));
        testnetFaucet.claim();

        // then
        BalanceUserAndFaucet memory balanceUserAndFaucetAfter = _getBalances(_userOne, address(_testnetFaucetProxy));

        assertEq(balanceUserAndFaucetBefore.daiUser + 10_000 * 1e18, balanceUserAndFaucetAfter.daiUser);
        assertEq(balanceUserAndFaucetBefore.usdcUser + 10_000 * 1e6, balanceUserAndFaucetAfter.usdcUser);
        assertEq(balanceUserAndFaucetBefore.usdtUser + 10_000 * 1e6, balanceUserAndFaucetAfter.usdtUser);
        assertEq(balanceUserAndFaucetBefore.iporUser + 1_000 * 1e18, balanceUserAndFaucetAfter.iporUser);
        assertEq(balanceUserAndFaucetBefore.iporFaucet - 1_000 * 1e18, balanceUserAndFaucetAfter.iporFaucet);
        assertEq(balanceUserAndFaucetBefore.daiFaucet - 10_000 * 1e18, balanceUserAndFaucetAfter.daiFaucet);
        assertEq(balanceUserAndFaucetBefore.usdcFaucet - 10_000 * 1e6, balanceUserAndFaucetAfter.usdcFaucet);
        assertEq(balanceUserAndFaucetBefore.usdtFaucet - 10_000 * 1e6, balanceUserAndFaucetAfter.usdtFaucet);
    }

    function testShouldClaimTwice() public {
        // given
        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        vm.startPrank(_userOne);
        BalanceUserAndFaucet memory balanceUserAndFaucetBefore = _getBalances(_userOne, address(_testnetFaucetProxy));
        testnetFaucet.claim();
        _blockTimestamp += 24 * 60 * 60;
        vm.warp(_blockTimestamp);

        // when
        testnetFaucet.claim();

        // then
        BalanceUserAndFaucet memory balanceUserAndFaucetAfter = _getBalances(_userOne, address(_testnetFaucetProxy));

        assertEq(balanceUserAndFaucetBefore.daiUser + 20_000 * 1e18, balanceUserAndFaucetAfter.daiUser);
        assertEq(balanceUserAndFaucetBefore.usdcUser + 20_000 * 1e6, balanceUserAndFaucetAfter.usdcUser);
        assertEq(balanceUserAndFaucetBefore.usdtUser + 20_000 * 1e6, balanceUserAndFaucetAfter.usdtUser);
        assertEq(balanceUserAndFaucetBefore.iporUser + 2_000 * 1e18, balanceUserAndFaucetAfter.iporUser);
        assertEq(balanceUserAndFaucetBefore.iporFaucet - 2_000 * 1e18, balanceUserAndFaucetAfter.iporFaucet);
        assertEq(balanceUserAndFaucetBefore.daiFaucet - 20_000 * 1e18, balanceUserAndFaucetAfter.daiFaucet);
        assertEq(balanceUserAndFaucetBefore.usdcFaucet - 20_000 * 1e6, balanceUserAndFaucetAfter.usdcFaucet);
        assertEq(balanceUserAndFaucetBefore.usdtFaucet - 20_000 * 1e6, balanceUserAndFaucetAfter.usdtFaucet);
    }

    function testShouldNotBeAbleToTransferWithTransferWhenNotOwner() public {
        // given
        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        vm.startPrank(_userOne);
        uint256 daiUserBalanceBefore = _daiTestnetToken.balanceOf(_userOne);
        uint256 daiFaucetBalanceBefore = _daiTestnetToken.balanceOf(address(_testnetFaucetProxy));

        // when
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        testnetFaucet.transfer(address(_daiTestnetToken), 1e18);

        // then
        uint256 daiUserBalanceAfter = _daiTestnetToken.balanceOf(_userOne);
        uint256 daiFaucetBalanceAfter = _daiTestnetToken.balanceOf(address(_testnetFaucetProxy));

        assertEq(daiUserBalanceBefore, daiUserBalanceAfter);
        assertEq(daiFaucetBalanceBefore, daiFaucetBalanceAfter);
    }

    function testShouldNotBeAbleToTransferWithTransferWhenAmount0() public {
        // given
        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        uint256 daiUserBalanceBefore = _daiTestnetToken.balanceOf(_userOne);
        uint256 daiFaucetBalanceBefore = _daiTestnetToken.balanceOf(address(_testnetFaucetProxy));

        // when
        vm.expectRevert(abi.encodePacked(IporErrors.VALUE_NOT_GREATER_THAN_ZERO));
        testnetFaucet.transfer(address(_daiTestnetToken), 0);

        // then
        uint256 daiUserBalanceAfter = _daiTestnetToken.balanceOf(_userOne);
        uint256 daiFaucetBalanceAfter = _daiTestnetToken.balanceOf(address(_testnetFaucetProxy));

        assertEq(daiUserBalanceBefore, daiUserBalanceAfter);
        assertEq(daiFaucetBalanceBefore, daiFaucetBalanceAfter);
    }

    function testShouldNotBeAbleToTransferWhenPassAeroAddressForAsset() public {
        // given
        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));

        // when
        vm.expectRevert(abi.encodePacked(IporErrors.WRONG_ADDRESS));
        testnetFaucet.transfer(address(0), 1e18);
    }

    function testShouldBeAbleToTransferAssetWhenSenderIsOwner() public {
        // given
        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        uint256 daiUserBalanceBefore = _daiTestnetToken.balanceOf(address(this));
        uint256 daiFaucetBalanceBefore = _daiTestnetToken.balanceOf(address(_testnetFaucetProxy));

        // when
        testnetFaucet.transfer(address(_daiTestnetToken), 1e18);

        // then
        uint256 daiBalanceAfter = _daiTestnetToken.balanceOf(address(this));
        uint256 daiFaucetBalanceAfter = _daiTestnetToken.balanceOf(address(_testnetFaucetProxy));

        assertEq(daiUserBalanceBefore + 1e18, daiBalanceAfter);
        assertEq(daiFaucetBalanceBefore - 1e18, daiFaucetBalanceAfter);
    }

    function testShouldAbleToClaimWhenOneAssetRunOut() public {
        // given
        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        _daiTestnetToken.transfer(address(_testnetFaucetProxy), 1e18);
        _usdcTestnetToken.transfer(address(_testnetFaucetProxy), 1e6);
        _usdtTestnetToken.transfer(address(_testnetFaucetProxy), 1e6);
        _iporToken.transfer(address(_testnetFaucetProxy), 1e18);
        testnetFaucet.transfer(address(_iporToken), 5_000_000 * 1e18);

        // when
        vm.startPrank(_userOne);
        vm.expectEmit(true, true, true, true);
        emit TransferFailed(_userOne, address(_iporToken), 1_000 * 1e18);
        testnetFaucet.claim();

        // then
        uint256 daiUserBalanceAfter = _daiTestnetToken.balanceOf(_userOne);
        uint256 usdcUserBalanceAfter = _usdcTestnetToken.balanceOf(_userOne);
        uint256 usdtUserBalanceAfter = _usdtTestnetToken.balanceOf(_userOne);
        uint256 iporUserBalanceAfter = _iporToken.balanceOf(_userOne);

        assertEq(daiUserBalanceAfter, 10_000 * 1e18);
        assertEq(usdcUserBalanceAfter, 10_000 * 1e6);
        assertEq(usdtUserBalanceAfter, 10_000 * 1e6);
        assertEq(iporUserBalanceAfter, 0);
    }

    function testShouldBeAbleToUpdateImplementation() public {
        // given
        _daiTestnetToken = new MockTestnetToken("Mocked DAI", "DAI", 100_000_000 * 1e18, uint8(18));
        _usdcTestnetToken = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
        _usdtTestnetToken = new MockTestnetToken("Mocked USDT", "USDT", 100_000_000 * 1e6, uint8(6));
        _iporToken = new IporToken("Mocked IPOR", "IPOR", address(this));
        TestnetFaucet newTestnetFaucetImplementation = new TestnetFaucet();
        MockOldTestnetFaucet testnetFaucetImplementation = new MockOldTestnetFaucet();
        _testnetFaucetProxy = new ERC1967Proxy(
            address(testnetFaucetImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                address(_daiTestnetToken),
                address(_usdcTestnetToken),
                address(_usdtTestnetToken)
            )
        );

        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        uint256 versionBefore = testnetFaucet.getVersion();

        // when
        IMockProxy(address(_testnetFaucetProxy)).upgradeTo(address(newTestnetFaucetImplementation));

        // then
        uint256 versionAfter = testnetFaucet.getVersion();
        assertEq(versionBefore, 1);
        assertEq(versionAfter, 2000);
    }

    function testShouldNotBeAbleToClaimAfterUpdateImplementationWhenDontWait24h() public {
        // given
        _daiTestnetToken = new MockTestnetToken("Mocked DAI", "DAI", 100_000_000 * 1e18, uint8(18));
        _usdcTestnetToken = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
        _usdtTestnetToken = new MockTestnetToken("Mocked USDT", "USDT", 100_000_000 * 1e6, uint8(6));
        _iporToken = new IporToken("Mocked IPOR", "IPOR", address(this));
        TestnetFaucet newTestnetFaucetImplementation = new TestnetFaucet();
        MockOldTestnetFaucet testnetFaucetImplementation = new MockOldTestnetFaucet();
        _testnetFaucetProxy = new ERC1967Proxy(
            address(testnetFaucetImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                address(_daiTestnetToken),
                address(_usdcTestnetToken),
                address(_usdtTestnetToken)
            )
        );

        _daiTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e18);
        _usdcTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e6);
        _usdtTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e6);
        _iporToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e18);

        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        BalanceUserAndFaucet memory balanceUserAndFaucetBefore = _getBalances(_userOne, address(_testnetFaucetProxy));

        vm.prank(_userOne);
        testnetFaucet.claim();
        IMockProxy(address(_testnetFaucetProxy)).upgradeTo(address(newTestnetFaucetImplementation));

        // when
        vm.expectRevert(abi.encodePacked("IPOR_600: 86400"));
        vm.prank(_userOne);
        testnetFaucet.claim();

        // then
        BalanceUserAndFaucet memory balanceUserAndFaucetAfter = _getBalances(_userOne, address(_testnetFaucetProxy));

        assertEq(balanceUserAndFaucetBefore.daiUser + 10_000 * 1e18, balanceUserAndFaucetAfter.daiUser);
        assertEq(balanceUserAndFaucetBefore.usdcUser + 10_000 * 1e6, balanceUserAndFaucetAfter.usdcUser);
        assertEq(balanceUserAndFaucetBefore.usdtUser + 10_000 * 1e6, balanceUserAndFaucetAfter.usdtUser);
        assertEq(balanceUserAndFaucetBefore.iporUser, balanceUserAndFaucetAfter.iporUser);
        assertEq(balanceUserAndFaucetBefore.iporFaucet, balanceUserAndFaucetAfter.iporFaucet);
        assertEq(balanceUserAndFaucetBefore.daiFaucet - 10_000 * 1e18, balanceUserAndFaucetAfter.daiFaucet);
        assertEq(balanceUserAndFaucetBefore.usdcFaucet - 10_000 * 1e6, balanceUserAndFaucetAfter.usdcFaucet);
        assertEq(balanceUserAndFaucetBefore.usdtFaucet - 10_000 * 1e6, balanceUserAndFaucetAfter.usdtFaucet);
    }

    function testShouldBeAbleToClaimTwiceAfterUpdateImplementation() public {
        // given
        _daiTestnetToken = new MockTestnetToken("Mocked DAI", "DAI", 100_000_000 * 1e18, uint8(18));
        _usdcTestnetToken = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
        _usdtTestnetToken = new MockTestnetToken("Mocked USDT", "USDT", 100_000_000 * 1e6, uint8(6));
        _iporToken = new IporToken("Mocked IPOR", "IPOR", address(this));
        TestnetFaucet newTestnetFaucetImplementation = new TestnetFaucet();
        MockOldTestnetFaucet testnetFaucetImplementation = new MockOldTestnetFaucet();
        _testnetFaucetProxy = new ERC1967Proxy(
            address(testnetFaucetImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                address(_daiTestnetToken),
                address(_usdcTestnetToken),
                address(_usdtTestnetToken)
            )
        );

        _daiTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e18);
        _usdcTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e6);
        _usdtTestnetToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e6);
        _iporToken.transfer(address(_testnetFaucetProxy), 5_000_000 * 1e18);

        ITestnetFaucet testnetFaucet = ITestnetFaucet(address(_testnetFaucetProxy));
        BalanceUserAndFaucet memory balanceUserAndFaucetBefore = _getBalances(_userOne, address(_testnetFaucetProxy));

        vm.prank(_userOne);
        testnetFaucet.claim();
        IMockProxy(address(_testnetFaucetProxy)).upgradeTo(address(newTestnetFaucetImplementation));
        _blockTimestamp += 24 * 60 * 60;
        vm.warp(_blockTimestamp);

        testnetFaucet.addAsset(address(_daiTestnetToken), 10_000 * 1e18);
        testnetFaucet.addAsset(address(_usdcTestnetToken), 10_000 * 1e6);
        testnetFaucet.addAsset(address(_usdtTestnetToken), 10_000 * 1e6);
        testnetFaucet.addAsset(address(_iporToken), 1_000 * 1e18);

        // when
        vm.prank(_userOne);
        testnetFaucet.claim();

        // then
        BalanceUserAndFaucet memory balanceUserAndFaucetAfter = _getBalances(_userOne, address(_testnetFaucetProxy));

        assertEq(balanceUserAndFaucetBefore.daiUser + 20_000 * 1e18, balanceUserAndFaucetAfter.daiUser);
        assertEq(balanceUserAndFaucetBefore.usdcUser + 20_000 * 1e6, balanceUserAndFaucetAfter.usdcUser);
        assertEq(balanceUserAndFaucetBefore.usdtUser + 20_000 * 1e6, balanceUserAndFaucetAfter.usdtUser);
        assertEq(balanceUserAndFaucetBefore.iporUser + 1_000 * 1e18, balanceUserAndFaucetAfter.iporUser);
        assertEq(balanceUserAndFaucetBefore.iporFaucet - 1_000 * 1e18, balanceUserAndFaucetAfter.iporFaucet);
        assertEq(balanceUserAndFaucetBefore.daiFaucet - 20_000 * 1e18, balanceUserAndFaucetAfter.daiFaucet);
        assertEq(balanceUserAndFaucetBefore.usdcFaucet - 20_000 * 1e6, balanceUserAndFaucetAfter.usdcFaucet);
        assertEq(balanceUserAndFaucetBefore.usdtFaucet - 20_000 * 1e6, balanceUserAndFaucetAfter.usdtFaucet);
    }
}
