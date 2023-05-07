// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/IMiltonStorage.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonStorageUtils is Test {
    struct MiltonStorages {
        MiltonStorage miltonStorageUsdt;
        MiltonStorage miltonStorageUsdc;
        MiltonStorage miltonStorageDai;
    }

    function getMiltonStorage() public returns (MiltonStorage) {
        MiltonStorage miltonStorageImplementation = new MiltonStorage();
        ERC1967Proxy miltonStorageProxy =
            new ERC1967Proxy(address(miltonStorageImplementation), abi.encodeWithSignature( "initialize()", ""));
        return MiltonStorage(address(miltonStorageProxy));
    }


    function prepareSwapPayFixedStruct18DecSimpleCase1(address buyer) public view returns (AmmTypes.NewSwap memory) {
        AmmTypes.NewSwap memory newSwap;
        newSwap.buyer = buyer;
        newSwap.openTimestamp = block.timestamp;
        newSwap.collateral = TestConstants.USD_1_000_18DEC;
        newSwap.notional = TestConstants.USD_5_000_18DEC;
        newSwap.ibtQuantity = 123;
        newSwap.fixedInterestRate = 234;
        newSwap.liquidationDepositAmount = 20;
        newSwap.openingFeeLPAmount = TestConstants.USD_1_500_18DEC;
        newSwap.openingFeeTreasuryAmount = TestConstants.USD_1_500_18DEC;
        return newSwap;
    }
}
