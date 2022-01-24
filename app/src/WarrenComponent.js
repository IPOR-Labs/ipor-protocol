import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import IporIndexList from "./IporIndexList";

const { AccountData, ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div align="left">
            <div class="row">
                <div class="col-md-6">
                    <strong>Add IPOR Index (Warren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="updateIndex"
                    />
                </div>
                <div class="col-md-6">
                    <strong>Add IPOR Index (ItfWarren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="updateIndex"
                    />
                </div>
            </div>
            <div class="row">
                <div class="col-md-6">
                    <strong>Add updater (Warren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="addUpdater"
                    />
                </div>
                <div class="col-md-6">
                    <strong>Add updater (ItfWarren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="addUpdater"
                    />
                </div>
            </div>
            <div class="row">
                <div class="col-md-6">
                    <strong>Remove updater (Warren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="removeUpdater"
                    />
                </div>
                <div class="col-md-6">
                    <strong>Remove updater (ItfWarren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="removeUpdater"
                    />
                </div>
            </div>
            <div class="row">
                <div class="col-md-6">
                    <strong>Updaters (Warren)</strong>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="Warren"
                        method="getUpdaters"
                    />
                </div>
                <div class="col-md-6">
                    <strong>Updaters (ItfWarren)</strong>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfWarren"
                        method="getUpdaters"
                    />
                </div>
            </div>
        </div>
        <div>
            <hr />
            <p>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="WarrenDevToolDataProvider"
                    method="getIndexes"
                    render={IporIndexList}
                />
            </p>
            <hr />
        </div>
    </div>
);
