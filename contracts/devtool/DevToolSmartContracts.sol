// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../configuration/IporAssetConfiguration.sol";
import "../tokenization/IpToken.sol";
import "../amm/Milton.sol";
import "../amm/MiltonStorage.sol";
import "../tokenization/Joseph.sol";
import "../itf/ItfMilton.sol";
import "../itf/ItfJoseph.sol";
import "../assetManagment/stanley/Stanley.sol";

contract IporAssetConfigurationUsdt is IporAssetConfiguration {}

contract IporAssetConfigurationUsdc is IporAssetConfiguration {}

contract IporAssetConfigurationDai is IporAssetConfiguration {}

contract IpTokenUsdt is IpToken {
    constructor(
        address underlyingAsset,
        string memory aTokenName,
        string memory aTokenSymbol
    ) IpToken(underlyingAsset, aTokenName, aTokenSymbol) {}
}

contract IpTokenUsdc is IpToken {
    constructor(
        address underlyingAsset,
        string memory aTokenName,
        string memory aTokenSymbol
    ) IpToken(underlyingAsset, aTokenName, aTokenSymbol) {}
}

contract IpTokenDai is IpToken {
    constructor(
        address underlyingAsset,
        string memory aTokenName,
        string memory aTokenSymbol
    ) IpToken(underlyingAsset, aTokenName, aTokenSymbol) {}
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
