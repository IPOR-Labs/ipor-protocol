//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../tokens/IpToken.sol";
import "../../tokens/IvToken.sol";
import "../../amm/Milton.sol";
import "../../amm/MiltonStorage.sol";
import "../../amm/pool/Joseph.sol";
import "../../vault/Stanley.sol";
import "../../vault/strategy/StrategyAave.sol";
import "../../vault/strategy/StartegyCompound.sol";
import "../../itf/ItfMilton.sol";
import "../../itf/ItfJoseph.sol";
import "../../mocks/stanley/compound/MockCToken.sol";
import "../../mocks/stanley/compound/MockComptroller.sol";

contract IpTokenUsdt is IpToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IpToken(name, symbol, asset) {}
}

contract IpTokenUsdc is IpToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IpToken(name, symbol, asset) {}
}

contract IpTokenDai is IpToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IpToken(name, symbol, asset) {}
}

contract IvTokenUsdt is IvToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IvToken(name, symbol, asset) {}
}

contract IvTokenUsdc is IvToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IvToken(name, symbol, asset) {}
}

contract IvTokenDai is IvToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IvToken(name, symbol, asset) {}
}

contract MiltonStorageUsdt is MiltonStorage {}

contract MiltonStorageUsdc is MiltonStorage {}

contract MiltonStorageDai is MiltonStorage {}

contract StrategyAaveUsdt is StrategyAave {}

contract StrategyAaveUsdc is StrategyAave {}

contract StrategyAaveDai is StrategyAave {}

contract StrategyCompoundUsdt is StrategyCompound {}

contract StrategyCompoundUsdc is StrategyCompound {}

contract StrategyCompoundDai is StrategyCompound {}

contract MockCDai is MockCToken {
    constructor(address asset, address interestRateModel)
        MockCToken(asset, interestRateModel, 18, "cDAI", "cDAI")
    {}
}

contract MockCUSDT is MockCToken {
    constructor(address asset, address interestRateModel)
        MockCToken(asset, interestRateModel, 6, "cUSDT", "cUSDT")
    {}
}

contract MockCUSDC is MockCToken {
    constructor(address asset, address interestRateModel)
        MockCToken(asset, interestRateModel, 6, "cUSDC", "cUSDC")
    {}
}

contract MockComptrollerUSDT is MockComptroller {
    constructor(address compToken, address cToken) MockComptroller(compToken, cToken) {}
}

contract MockComptrollerUSDC is MockComptroller {
    constructor(address compToken, address cToken) MockComptroller(compToken, cToken) {}
}

contract MockComptrollerDAI is MockComptroller {
    constructor(address compToken, address cToken) MockComptroller(compToken, cToken) {}
}
