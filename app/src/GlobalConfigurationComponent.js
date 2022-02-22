import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
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
        <table className="table" align="center">
            <tr>
                <td>
                    <strong>Warren</strong>
                </td>
                <td>{drizzle.contracts.Warren.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>ItfWarren</strong>
                </td>
                <td>{drizzle.contracts.ItfWarren.address}</td>
            </tr>
        </table>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>
                    <strong>Ipor Asset Configuration</strong>
                </td>
                <td>{drizzle.contracts.IporAssetConfigurationUsdt.address}</td>
                <td>{drizzle.contracts.IporAssetConfigurationUsdc.address}</td>
                <td>{drizzle.contracts.IporAssetConfigurationDai.address}</td>
            </tr>

            <tr>
                <td>
                    <strong>Milton</strong>
                </td>
                <td>{drizzle.contracts.MiltonUsdt.address}</td>
                <td>{drizzle.contracts.MiltonUsdc.address}</td>
                <td>{drizzle.contracts.MiltonDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>ItfMilton</strong>
                </td>
                <td>{drizzle.contracts.ItfMiltonUsdt.address}</td>
                <td>{drizzle.contracts.ItfMiltonUsdc.address}</td>
                <td>{drizzle.contracts.ItfMiltonDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Milton Storage</strong>
                </td>
                <td>{drizzle.contracts.MiltonStorageUsdt.address}</td>
                <td>{drizzle.contracts.MiltonStorageUsdc.address}</td>
                <td>{drizzle.contracts.MiltonStorageDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Joseph</strong>
                </td>
                <td>{drizzle.contracts.JosephUsdt.address}</td>
                <td>{drizzle.contracts.JosephUsdc.address}</td>
                <td>{drizzle.contracts.JosephDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>ItfJoseph</strong>
                </td>
                <td>{drizzle.contracts.ItfJosephUsdt.address}</td>
                <td>{drizzle.contracts.ItfJosephUsdc.address}</td>
                <td>{drizzle.contracts.ItfJosephDai.address}</td>
            </tr>
        </table>
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
