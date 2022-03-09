// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../tokenization/IpToken.sol";
import "../amm/Milton.sol";
import "../amm/MiltonStorage.sol";
import "../tokenization/Joseph.sol";
import "../itf/ItfMilton.sol";
import "../itf/ItfJoseph.sol";
import "../vault/Stanley.sol";
import "../vault/tokenization/IvToken.sol";
import {AaveStrategy} from "../vault/strategy/AaveStrategy.sol";
import {CompoundStrategy} from "../vault/strategy/CompoundStartegy.sol";
import {MockCToken} from "../vault/mocks/compound/MockCToken.sol";
import {MockComptroller} from "../vault/mocks/compound/MockComptroller.sol";

contract IpTokenUsdt is IpToken {
    constructor(
        address asset,
        string memory name,
        string memory symbol
    ) IpToken(asset, name, symbol) {}
}

contract IpTokenUsdc is IpToken {
    constructor(
        address asset,
        string memory name,
        string memory symbol
    ) IpToken(asset, name, symbol) {}
}

contract IpTokenDai is IpToken {
    constructor(
        address asset,
        string memory name,
        string memory symbol
    ) IpToken(asset, name, symbol) {}
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

contract MiltonUsdt is Milton {}

contract MiltonUsdc is Milton {}

contract MiltonDai is Milton {}

contract ItfMiltonUsdt is ItfMilton {}

contract ItfMiltonUsdc is ItfMilton {}

contract ItfMiltonDai is ItfMilton {}

contract MiltonStorageUsdt is MiltonStorage {}

contract MiltonStorageUsdc is MiltonStorage {}

contract MiltonStorageDai is MiltonStorage {}

contract JosephUsdt is Joseph {}

contract JosephUsdc is Joseph {}

contract JosephDai is Joseph {}

contract ItfJosephUsdt is ItfJoseph {}

contract ItfJosephUsdc is ItfJoseph {}

contract ItfJosephDai is ItfJoseph {}

contract StanleyUsdt is Stanley {}

contract StanleyUsdc is Stanley {}

contract StanleyDai is Stanley {}

contract StrategyAaveUsdt is AaveStrategy {}

contract StrategyAaveUsdc is AaveStrategy {}

contract StrategyAaveDai is AaveStrategy {}

contract StrategyCompoundUsdt is CompoundStrategy {}

contract StrategyCompoundUsdc is CompoundStrategy {}

contract StrategyCompoundDai is CompoundStrategy {}

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
