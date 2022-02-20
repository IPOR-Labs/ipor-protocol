// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IporErrors} from "../IporErrors.sol";

contract IporOwnableUpgradeable is OwnableUpgradeable {
    address private _appointedOwner;

    event AppointedToTransferOwnership(address indexed appointedOwner);

    function transferOwnership(address appointedOwner)
        public
        override
        onlyOwner
    {
        require(appointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        _appointedOwner = appointedOwner;
        emit AppointedToTransferOwnership(appointedOwner);
    }

    function confirmTransferOwnership() public onlyAppointedOwner {
        // address newOwner = _appointedOwner;
        _appointedOwner = address(0);
        _transferOwnership(_msgSender());
    }

    modifier onlyAppointedOwner() {
        require(
            _appointedOwner == _msgSender(),
            IporErrors.SENDER_NOT_APPOINTED_OWNER
        );
        _;
    }
}
