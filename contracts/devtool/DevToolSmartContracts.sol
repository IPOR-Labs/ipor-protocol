// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../configuration/IporAssetConfiguration.sol";
import "../amm/Milton.sol";
import "../amm/MiltonStorage.sol";
import "../tokenization/Joseph.sol";
import "../itf/ItfMilton.sol";
import "../itf/ItfJoseph.sol";

contract IporAssetConfigurationUsdt is IporAssetConfiguration {
    constructor(address asset, address ipToken)
        IporAssetConfiguration(asset, ipToken)
    {}
}

contract IporAssetConfigurationUsdc is IporAssetConfiguration {
    constructor(address asset, address ipToken)
        IporAssetConfiguration(asset, ipToken)
    {}
}

contract IporAssetConfigurationDai is IporAssetConfiguration {
    constructor(address asset, address ipToken)
        IporAssetConfiguration(asset, ipToken)
    {}
}

contract MiltonUsdt is Milton {
    constructor(address asset, address initialIporConfiguration)
        Milton(asset, initialIporConfiguration)
    {}
}

contract MiltonUsdc is Milton {
    constructor(address asset, address initialIporConfiguration)
        Milton(asset, initialIporConfiguration)
    {}
}

contract MiltonDai is Milton {
    constructor(address asset, address initialIporConfiguration)
        Milton(asset, initialIporConfiguration)
    {}
}

contract ItfMiltonUsdt is ItfMilton {
    constructor(address asset, address initialIporConfiguration)
        ItfMilton(asset, initialIporConfiguration)
    {}
}

contract ItfMiltonUsdc is ItfMilton {
    constructor(address asset, address initialIporConfiguration)
        ItfMilton(asset, initialIporConfiguration)
    {}
}

contract ItfMiltonDai is ItfMilton {
    constructor(address asset, address initialIporConfiguration)
        ItfMilton(asset, initialIporConfiguration)
    {}
}

contract MiltonStorageUsdt is MiltonStorage {
    constructor(address asset, address initialIporConfiguration)
	MiltonStorage(asset, initialIporConfiguration)
    {}
}

contract MiltonStorageUsdc is MiltonStorage {
    constructor(address asset, address initialIporConfiguration)
	MiltonStorage(asset, initialIporConfiguration)
    {}
}

contract MiltonStorageDai is MiltonStorage {
    constructor(address asset, address initialIporConfiguration)
	MiltonStorage(asset, initialIporConfiguration)
    {}
}

contract JosephUsdt is Joseph {
    constructor(address asset, address initialIporConfiguration)
	Joseph(asset, initialIporConfiguration)
    {}
}

contract JosephUsdc is Joseph {
    constructor(address asset, address initialIporConfiguration)
	Joseph(asset, initialIporConfiguration)
    {}
}

contract JosephDai is Joseph {
    constructor(address asset, address initialIporConfiguration)
	Joseph(asset, initialIporConfiguration)
    {}
}

contract ItfJosephUsdt is ItfJoseph {
    constructor(address asset, address initialIporConfiguration)
	ItfJoseph(asset, initialIporConfiguration)
    {}
}

contract ItfJosephUsdc is ItfJoseph {
    constructor(address asset, address initialIporConfiguration)
	ItfJoseph(asset, initialIporConfiguration)
    {}
}

contract ItfJosephDai is ItfJoseph {
    constructor(address asset, address initialIporConfiguration)
	ItfJoseph(asset, initialIporConfiguration)
    {}
}