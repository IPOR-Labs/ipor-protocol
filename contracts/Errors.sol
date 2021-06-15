// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

library Errors {
    string public constant CALLER_NOT_IPOR_ORACLE_ADMIN = '1'; // 'The caller must be the admin'
    string public constant CALLER_NOT_IPOR_ORACLE_UPDATER = '2'; // 'The caller must be the updater'

}