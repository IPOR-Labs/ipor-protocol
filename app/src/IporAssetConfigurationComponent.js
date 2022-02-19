import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        {drizzle.contracts.UsdtMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.UsdcMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DaiMockedToken.address}
                        <br />
                        <br />
                    </th>
                </tr>
                <tr>
                    <td>
                        <br />
                        <strong>Ipor Asset Configuration Address</strong>
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationUsdt.address}
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationUsdc.address}
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationDai.address}
                        <br />
                        <br />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>IP Token Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getIpToken"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getIpToken"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getIpToken"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Milton</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getMilton"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMilton"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMilton"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Milton Storage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMiltonStorage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Joseph</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getJoseph"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getJoseph"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getJoseph"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Charlie Treasuers</strong>
                        <br />
                        <small>Manage IPOR publication fee token balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setCharlieTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setCharlieTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setCharlieTreasurer"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasure Manager</strong>
                        <br />
                        <small>Manage opening fee balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setTreasureTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setTreasureTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setTreasureTreasurer"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Asset Management Vault</strong>
                        <br />
                        <small>
                            Manage LP balance in external portals like AAVE &
                            Compound
                        </small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setAssetManagementVault"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setAssetManagementVault"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setAssetManagementVault"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Grant role to user</strong>
                        <br />
                        <small>
                            In field role use byte32 representation. Available
                            roles listed below.
                        </small>
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="grantRole"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="grantRole"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="grantRole"
                        />
                    </td>
                </tr>
            </table>
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>ADMIN_ROLE</td>
                        <td>
                            0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
                        </td>
                    </tr>
                    <tr>
                        <td>CHARLIE_TREASURER_ADMIN_ROLE</td>
                        <td>
                            0x0a8c46bed2194419383260fcc83e7085079a16a3dce173fb3d66eb1f81c71f6e
                        </td>
                    </tr>
                    <tr>
                        <td>CHARLIE_TREASURER_ROLE</td>
                        <td>
                            0x21b203ce7b3398e0ad35c938bc2c62a805ef17dc57de85e9d29052eac6d9d6f7
                        </td>
                    </tr>
                    <tr>
                        <td>TREASURE_TREASURER_ADMIN_ROLE</td>
                        <td>
                            0x1ba824e22ad2e0dc1d7a152742f3b5890d88c5a849ed8e57f4c9d84203d3ea9c
                        </td>
                    </tr>
                    <tr>
                        <td>TREASURE_TREASURER_ROLE</td>
                        <td>
                            0x9cdee4e06275597b667c73a5eb52ed89fe6acbbd36bd9fa38146b1316abfbbc4
                        </td>
                    </tr>
                    <tr>
                        <td>ASSET_MANAGEMENT_VAULT_ADMIN_ROLE</td>
                        <td>
                            0x1d3c5c61c32255cb922b09e735c0e9d76d2aacc424c3f7d9b9b85c478946fa26
                        </td>
                    </tr>
                    <tr>
                        <td>ASSET_MANAGEMENT_VAULT_ROLE</td>
                        <td>
                            0x2a7b2b7d358f8b11f783d1505af660b492b725a034776176adc7c268915d5bd8
                        </td>
                    </tr>
                    <tr>
                        <td>ROLES_INFO_ADMIN_ROLE</td>
                        <td>
                            0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c
                        </td>
                    </tr>
                    <tr>
                        <td>ROLES_INFO_ROLE</td>
                        <td>
                            0xc878cde3567a457053651a2406e31db6dbb9207b6d5eedb081ef807beaaf5444
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
);
