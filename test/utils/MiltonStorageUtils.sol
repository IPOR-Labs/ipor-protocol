// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/amm/MiltonStorage.sol";

contract MiltonStorageUtils is Test {
    function getMiltonStorage() public returns (MiltonStorage) {
        MiltonStorage miltonStorageImpl = new MiltonStorage();
        ERC1967Proxy miltonStorageProxy = new ERC1967Proxy(
            address(miltonStorageImpl),
            abi.encodeWithSignature("initialize()", "")
        );
        return MiltonStorage(address(miltonStorageProxy));
    }

    function prepareMiltonStorage(
        MiltonStorage miltonStorage,
        address joseph,
        address milton
    ) public {
        miltonStorage.setJoseph(joseph);
        miltonStorage.setMilton(milton);
    }
}
