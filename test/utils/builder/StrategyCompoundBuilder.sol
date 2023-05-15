// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/mocks/stanley/MockTestnetStrategy.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";

contract StrategyCompoundBuilder is Test {
    struct BuilderData {
        address asset;
        address shareToken;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
    }

    function withAsset(address asset) public returns (StrategyCompoundBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withShareToken(address shareToken) public returns (StrategyCompoundBuilder) {
        builderData.shareToken = shareToken;
        return this;
    }

    function withShareTokenDai() public returns (StrategyCompoundBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share cDAI", "cDAI", 0, 18);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function withShareTokenUsdt() public returns (StrategyCompoundBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share cUSDT", "cUSDT", 0, 6);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function withShareTokenUsdc() public returns (StrategyCompoundBuilder) {
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share cUSDC", "cUSDC", 0, 6);
        builderData.shareToken = address(shareToken);

        return this;
    }

    function build() public returns (MockTestnetStrategy) {
        require(builderData.asset != address(0), "Asset address is not set");
        require(builderData.shareToken != address(0), "ShareToken address is not set");
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MockTestnetStrategy()));
        MockTestnetStrategy strategy = MockTestnetStrategy(address(proxy));
        vm.stopPrank();
        return strategy;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature("initialize(address,address)", builderData.asset, builderData.shareToken)
        );
    }
}
