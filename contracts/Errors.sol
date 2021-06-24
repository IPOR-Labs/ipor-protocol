// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

library Errors {
    string public constant CALLER_NOT_IPOR_ORACLE_ADMIN = '1'; // 'The caller must be the admin'
    string public constant CALLER_NOT_IPOR_ORACLE_UPDATER = '2'; // 'The caller must be the updater'

    string public constant AMM_NOTIONAL_AMOUNT_TOO_LOW = '3'; // 'Notional Principal Amount when creating derivative position is too low'
    string public constant AMM_DEPOSIT_AMOUNT_TOO_LOW = '4'; // 'Deposit Amount when creating derivative position is too low'
    string public constant AMM_MAXIMUM_SLIPPAGE_TOO_LOW = '5'; // 'Maximum Slippage is too low'

}