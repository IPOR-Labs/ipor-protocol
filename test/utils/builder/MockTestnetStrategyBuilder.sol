// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../mocks/tokens/MockTestnetToken.sol";
import "../../mocks/assetManagement/MockTestnetStrategy.sol";
import "forge-std/Test.sol";

contract MockTestnetStrategyBuilder is Test {
    struct BuilderData {
        address asset;
        uint256 assetDecimals;
        address shareToken;
        address assetManagementProxy;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAsset(address asset) public returns (MockTestnetStrategyBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withAssetDecimals(uint256 assetDecimals) public returns (MockTestnetStrategyBuilder) {
        builderData.assetDecimals = assetDecimals;
        return this;
    }

    function withShareToken(address shareToken) public returns (MockTestnetStrategyBuilder) {
        builderData.shareToken = shareToken;
        return this;
    }

    function withAssetManagementProxy(address assetManagementProxy) public returns (MockTestnetStrategyBuilder) {
        builderData.assetManagementProxy = assetManagementProxy;
        return this;
    }

    function withShareTokenDai() public returns (MockTestnetStrategyBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share aDAI", "aDAI", 0, 18);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function withShareTokenUsdt() public returns (MockTestnetStrategyBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share aUSDT", "aUSDT", 0, 6);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function withShareTokenUsdc() public returns (MockTestnetStrategyBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share aUSDC", "aUSDC", 0, 6);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function build() public returns (MockTestnetStrategy) {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.shareToken != address(0), "ShareToken address is not set");

        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(
            address(
                new MockTestnetStrategy(
                    builderData.asset,
                    builderData.assetDecimals,
                    builderData.shareToken,
                    builderData.assetManagementProxy
                )
            )
        );
        MockTestnetStrategy strategy = MockTestnetStrategy(address(proxy));
        vm.stopPrank();
        return strategy;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize()"));
    }
}
