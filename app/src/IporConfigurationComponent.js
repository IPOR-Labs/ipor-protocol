import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <div className="col-md-2">Warren</div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getWarren"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setWarren"
                />
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">Milton Spread Model</div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonSpreadModel"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonSpreadModel"
                />
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">Publication Fee Transferer</div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonPublicationFeeTransferer"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonPublicationFeeTransferer"
                />
            </div>
        </div>
        <hr />
        <div className="row">
            <div className="col-md-2">IporConfiguration</div>
            <div className="col-md-10">
                {drizzle.contracts.IporConfiguration.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">Warren</div>
            <div className="col-md-10">{drizzle.contracts.Warren.address}</div>
        </div>
        <div className="row">
            <div className="col-md-2">ItfWarren</div>
            <div className="col-md-10">
                {drizzle.contracts.ItfWarren.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">MiltonUsdt</div>
            <div className="col-md-10">
                {drizzle.contracts.MiltonUsdt.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">ItfMiltonUsdt</div>
            <div className="col-md-10">
                {drizzle.contracts.ItfMiltonUsdt.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">MiltonStorageUsdt</div>
            <div className="col-md-10">
                {drizzle.contracts.MiltonStorageUsdt.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">JosephUsdt</div>
            <div className="col-md-10">
                {drizzle.contracts.JosephUsdt.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">ItfJosephUsdt</div>
            <div className="col-md-10">
                {drizzle.contracts.ItfJosephUsdt.address}
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">MiltonUsdc</div>
            <div className="col-md-10">
                {drizzle.contracts.MiltonUsdc.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">ItfMiltonUsdc</div>
            <div className="col-md-10">
                {drizzle.contracts.ItfMiltonUsdc.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">MiltonStorageUsdc</div>
            <div className="col-md-10">
                {drizzle.contracts.MiltonStorageUsdc.address}
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">JosephUsdc</div>
            <div className="col-md-10">
                {drizzle.contracts.JosephUsdc.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">ItfJosephUsdc</div>
            <div className="col-md-10">
                {drizzle.contracts.ItfJosephUsdc.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">MiltonDai</div>
            <div className="col-md-10">
                {drizzle.contracts.MiltonDai.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">ItfMiltonDai</div>
            <div className="col-md-10">
                {drizzle.contracts.ItfMiltonDai.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">MiltonStorageDai</div>
            <div className="col-md-10">
                {drizzle.contracts.MiltonStorageDai.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">JosephDai</div>
            <div className="col-md-10">
                {drizzle.contracts.JosephDai.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">ItfJosephDai</div>
            <div className="col-md-10">
                {drizzle.contracts.ItfJosephDai.address}
            </div>
        </div>
        <hr />
        <div className="row">
            <div className="col-md-2">Grant role to user</div>
            <div className="col-md-3"></div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="grantRole"
                />
            </div>
        </div>
        <div className="row">
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
                        <td>WARREN_ADMIN_ROLE</td>
                        <td>
                            0x1e04dc043068779cd91c1a75e0583a7db9c855bf85d461752231d1fe5a7f69ca
                        </td>
                    </tr>
                    <tr>
                        <td>WARREN_ROLE</td>
                        <td>
                            0xe2062703bb72555ff94bfdd96351e7f292b8034f5f9127a25167d8d44f91ae85
                        </td>
                    </tr>

                    <tr>
                        <td>WARREN_STORAGE_ADMIN_ROLE</td>
                        <td>
                            0xb1c511825e3a3673b7b3e9816a90ae950555bc6dbcfe9ddcd93d74ef23df3ed2
                        </td>
                    </tr>
                    <tr>
                        <td>WARREN_STORAGE_ROLE</td>
                        <td>
                            0xb527a07823dd490f4af143463d6cd886bd7f2ff7af38e50cce0a4d77dbccc92f
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_SPREAD_MODEL_ADMIN_ROLE</td>
                        <td>
                            0x869c6dda984481cbeefdaab23aeff7b5cae8e04a57bb6bc44608ea47966b45ac
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_SPREAD_MODEL_ROLE</td>
                        <td>
                            0xc769312598bcfa61b1f22ed091835eefa5a0d9a37ea7646f63bfd88a3dd04878
                        </td>
                    </tr>                    
                    <tr>
                        <td>MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE</td>
                        <td>
                            0x7509198b389a0e4178b0935b3089a6bcebb17099877530792a238050cad1a93a
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_PUBLICATION_FEE_TRANSFERER_ROLE</td>
                        <td>
                            0xcaf9c92ac95381198cb99b15cf6677f38c77ba44a82d424368980282298f9dc9
                        </td>
                    </tr>
                    <tr>
                        <td>IPOR_ASSET_CONFIGURATION_ROLE</td>
                        <td>
                            0xe8f735d503f091d7e700cae87352987ca83ec17c9b2fb176dc5a5a7ec0390360
                        </td>
                    </tr>
                    <tr>
                        <td>IPOR_ASSET_CONFIGURATION_ADMIN_ROLE</td>
                        <td>
                            0xb7659cf0d647b98a28212b8b2a17946479df7bb15e3d9c461c7d32c3536abcaf
                        </td>
                    </tr>
                    <tr>
                        <td>IPOR_ASSETS_ADMIN_ROLE</td>
                        <td>
                            0xec35db9ce8f02d82695716c134979faf9e051eb97ef9ae15ec0aaafbde76beb5
                        </td>
                    </tr>
                    <tr>
                        <td>IPOR_ASSETS_ROLE</td>
                        <td>
                            0xf2f6e1201d6fbf7ec2033ab2b3ad3dcf0ded3dd534a82806a88281c063f67656
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
