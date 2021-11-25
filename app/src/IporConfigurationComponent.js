import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <div className="row">
            <div className="col-md-2">
                Warren
            </div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getWarren"/>
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
            <div className="col-md-2">
                Warren Storage
            </div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getWarrenStorage"/>
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setWarrenStorage"/>
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">
                Milton
            </div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMilton"/>
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMilton"/>
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">
                Milton Storage
            </div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonStorage"/>
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonStorage"/>
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">
                Joseph
            </div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getJoseph"/>
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setJoseph"/>
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
                    method="getMiltonLPUtilizationStrategy"/>
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonLPUtilizationStrategy"/>
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">
                Milton Spread Strategy
            </div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonSpreadStrategy"/>
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonSpreadStrategy"/>
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">
                Publication Fee Transferer
            </div>
            <div className="col-md-3">
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporConfiguration"
                    method="getMiltonPublicationFeeTransferer"/>
            </div>
            <div className="col-md-7">
                <ContractForm
                    drizzle={drizzle}
                    contract="IporConfiguration"
                    method="setMiltonPublicationFeeTransferer"/>
            </div>
        </div>

        <div className="row">
            <div className="col-md-2">
                Grant role to user
            </div>
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
                    method="grantRole"/>
            </div>
        </div>
        <div className="row">
            <table>
                <thead>
                    <tr>
                    <th>Name</th><th>Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr><td>ADMIN_ROLE</td><td>0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775</td></tr>
                    <tr><td>IPOR_ASSETS_ROLE</td><td>0xf2f6e1201d6fbf7ec2033ab2b3ad3dcf0ded3dd534a82806a88281c063f67656</td></tr>
                    <tr><td>MILTON_ROLE</td><td>0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1</td></tr>
                    <tr><td>MILTON_STORAGE_ROLE</td><td>0xb8f71ab818f476672f61fd76955446cd0045ed8ddb51f595d9e262b68d1157f6</td></tr>
                    <tr><td>MILTON_LP_UTILIZATION_STRATEGY_ROLE</td><td>0xef6ebe4a0a1a6329b3e5cd4d5c8731f6077174efd4f525f70490c35144b6ed72</td></tr>
                    <tr><td>MILTON_SPREAD_STRATEGY_ROLE</td><td>0xdf80c0078aae521b601e4fddc35fbb2871ffaa4e22d30b53745545184b3cff3e</td></tr>
                    <tr><td>IPOR_ASSET_CONFIGURATION_ROLE</td><td>0xe8f735d503f091d7e700cae87352987ca83ec17c9b2fb176dc5a5a7ec0390360</td></tr>
                    <tr><td>WARREN_ROLE</td><td>0xe2062703bb72555ff94bfdd96351e7f292b8034f5f9127a25167d8d44f91ae85</td></tr>
                    <tr><td>JOSEPH_ROLE</td><td>0x2c03e103fc464998235bd7f80967993a1e6052d41cc085d3317ca8e301f51125</td></tr>
                    <tr><td>MILTON_PUBLICATION_FEE_TRANSFERER_ROLE</td><td>0xcaf9c92ac95381198cb99b15cf6677f38c77ba44a82d424368980282298f9dc9</td></tr>
                </tbody>
            </table>
        </div>
    </div>
);