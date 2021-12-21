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
            <div className="col-md-2">Warren Storage</div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getWarrenStorage"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setWarrenStorage"
                />
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">Milton</div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMilton"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMilton"
                />
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">Milton Storage</div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonStorage"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonStorage"
                />
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">Joseph</div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getJoseph"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setJoseph"
                />
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">
                Milton Liquidity Pool Utilization Strategy
            </div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonLPUtilizationStrategy"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonLPUtilizationStrategy"
                />
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">Milton Spread Strategy</div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonSpreadStrategy"
                />
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonSpreadStrategy"
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
        <hr/>
        <div className="row">
            <div className="col-md-2">Warren</div>
            <div className="col-md-10">
                {drizzle.contracts.Warren.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">Test Warren</div>
            <div className="col-md-10">
                {drizzle.contracts.TestWarren.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">Milton</div>
            <div className="col-md-10">
                {drizzle.contracts.Milton.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">Test Milton</div>
            <div className="col-md-10">
                {drizzle.contracts.TestMilton.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">Joseph</div>
            <div className="col-md-10">
                {drizzle.contracts.Joseph.address}
            </div>
        </div>
        <div className="row">
            <div className="col-md-2">Test Joseph</div>
            <div className="col-md-10">
                {drizzle.contracts.TestJoseph.address}
            </div>
        </div>
        <hr/>
        <div className="row">
            <div className="col-md-2">Grant role to user</div>
            <div className="col-md-3">
                {/* <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonPublicationFeeTransferer"/> */}
            </div>
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
                        <td>ROLES_INFO_ROLE</td>
                        <td>
                            0xc878cde3567a457053651a2406e31db6dbb9207b6d5eedb081ef807beaaf5444
                        </td>
                    </tr>
                    <tr>
                        <td>ROLES_INFO_ADMIN_ROLE</td>
                        <td>
                            0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c
                        </td>
                    </tr>
                    <tr>
                        <td>IPOR_ASSETS_ROLE</td>
                        <td>
                            0xf2f6e1201d6fbf7ec2033ab2b3ad3dcf0ded3dd534a82806a88281c063f67656
                        </td>
                    </tr>
                    <tr>
                        <td>IPOR_ASSETS_ADMIN_ROLE</td>
                        <td>
                            0xec35db9ce8f02d82695716c134979faf9e051eb97ef9ae15ec0aaafbde76beb5
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_ROLE</td>
                        <td>
                            0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_ADMIN_ROLE</td>
                        <td>
                            0x1b16f266cfe5113986bbdf79323bd64ba74c9e2631c82de1297c13405226a952
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_STORAGE_ROLE</td>
                        <td>
                            0xb8f71ab818f476672f61fd76955446cd0045ed8ddb51f595d9e262b68d1157f6
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_STORAGE_ADMIN_ROLE</td>
                        <td>
                            0x61e410eb94acd095b84b0de4a9befc42adb8e88aad1e0c387e8f14c5c05f4cd5
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_LP_UTILIZATION_STRATEGY_ROLE</td>
                        <td>
                            0xef6ebe4a0a1a6329b3e5cd4d5c8731f6077174efd4f525f70490c35144b6ed72
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE</td>
                        <td>
                            0x007166265d5885631bd5886b0a89309e34f70b77bb831ac337b128950760bda7
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_SPREAD_STRATEGY_ROLE</td>
                        <td>
                            0xdf80c0078aae521b601e4fddc35fbb2871ffaa4e22d30b53745545184b3cff3e
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_SPREAD_STRATEGY_ADMIN_ROLE</td>
                        <td>
                            0x4a48b7c468d48efb15988e82311c6880af84ff7b6fe0e097f58073c7e794cf45
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
                        <td>WARREN_ROLE</td>
                        <td>
                            0xe2062703bb72555ff94bfdd96351e7f292b8034f5f9127a25167d8d44f91ae85
                        </td>
                    </tr>
                    <tr>
                        <td>WARREN_ADMIN_ROLE</td>
                        <td>
                            0x1e04dc043068779cd91c1a75e0583a7db9c855bf85d461752231d1fe5a7f69ca
                        </td>
                    </tr>
                    <tr>
                        <td>JOSEPH_ROLE</td>
                        <td>
                            0x2c03e103fc464998235bd7f80967993a1e6052d41cc085d3317ca8e301f51125
                        </td>
                    </tr>
                    <tr>
                        <td>JOSEPH_ADMIN_ROLE</td>
                        <td>
                            0x811ff4f923fc903f4390f8acf72873b5d1b288ec77b442fe124d0f95d6a53731
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_PUBLICATION_FEE_TRANSFERER_ROLE</td>
                        <td>
                            0xcaf9c92ac95381198cb99b15cf6677f38c77ba44a82d424368980282298f9dc9
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE</td>
                        <td>
                            0x7509198b389a0e4178b0935b3089a6bcebb17099877530792a238050cad1a93a
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
);
