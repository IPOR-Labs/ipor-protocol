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
                    method="setWarren"/>
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
    </div>
);