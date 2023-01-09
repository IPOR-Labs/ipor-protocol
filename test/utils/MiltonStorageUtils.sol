// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonStorageUtils is Test {
    /// ------------------- MILTONSTORAGE -------------------
    struct MiltonStorages {
        ERC1967Proxy miltonStorageUsdtProxy;
        MiltonStorage miltonStorageUsdt;
        ERC1967Proxy miltonStorageUsdcProxy;
        MiltonStorage miltonStorageUsdc;
        ERC1967Proxy miltonStorageDaiProxy;
        MiltonStorage miltonStorageDai;
    }

    /// ------------------- MILTONSTORAGE -------------------

    function prepareMiltonStorage(
        MiltonStorage miltonStorage,
        ERC1967Proxy miltonStorageProxy,
        address joseph,
        address milton
    ) public returns (MiltonStorage) {
        vm.prank(address(miltonStorageProxy));
        miltonStorage.setJoseph(joseph);
        vm.prank(address(miltonStorageProxy));
        miltonStorage.setMilton(milton);
        return miltonStorage;
    }

    function getMiltonStorage() public returns (ERC1967Proxy, MiltonStorage) {
        MiltonStorage miltonStorageImpl = new MiltonStorage();
        ERC1967Proxy miltonStorageProxy = new ERC1967Proxy(
            address(miltonStorageImpl),
            abi.encodeWithSignature("initialize()", "")
        );
        MiltonStorage miltonStorage = MiltonStorage(address(miltonStorageProxy));
        return (miltonStorageProxy, miltonStorage);
    }

    function getMiltonStorages() public returns (MiltonStorages memory) {
        MiltonStorages memory miltonStorages;
        (
            miltonStorages.miltonStorageUsdtProxy,
            miltonStorages.miltonStorageUsdt
        ) = getMiltonStorage();
        (
            miltonStorages.miltonStorageUsdcProxy,
            miltonStorages.miltonStorageUsdc
        ) = getMiltonStorage();
        (
            miltonStorages.miltonStorageDaiProxy,
            miltonStorages.miltonStorageDai
        ) = getMiltonStorage();
        return miltonStorages;
    }

    function getMiltonStorageAddresses(
        address miltonStorageUsdt,
        address miltonStorageUsdc,
        address miltonStorageDai
    ) public pure returns (address[] memory) {
        address[] memory miltonStorageAddresses = new address[](3);
        miltonStorageAddresses[0] = miltonStorageUsdt;
        miltonStorageAddresses[1] = miltonStorageUsdc;
        miltonStorageAddresses[2] = miltonStorageDai;
        return miltonStorageAddresses;
    }

    function prepareSwapPayFixedStruct18DecSimpleCase1(address buyer)
        public
        view
        returns (AmmTypes.NewSwap memory)
    {
        AmmTypes.NewSwap memory newSwap;
        newSwap.buyer = buyer;
        newSwap.openTimestamp = block.timestamp;
        newSwap.collateral = 1000 * Constants.D18;
        newSwap.notional = 50000 * Constants.D18;
        newSwap.ibtQuantity = 123;
        newSwap.fixedInterestRate = 234;
        newSwap.liquidationDepositAmount = 20;
        newSwap.openingFeeLPAmount = 1500 * Constants.D18;
        newSwap.openingFeeTreasuryAmount = 1500 * Constants.D18;
        return newSwap;
    }
}
