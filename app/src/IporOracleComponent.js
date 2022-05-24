import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import IporIndexList from "./IporIndexList";

const { AccountData, ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
            <div>
                <div>
                    <strong>Add IPOR Index (ItfIporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="IporOracleLocal" method="updateIndex" />
                </div>
                <div>
                    <strong>Add updater (ItfIporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="IporOracleLocal" method="addUpdater" />
                </div>
                <div>
                    <strong>Remove updater (ItfIporOracle)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IporOracleLocal"
                        method="removeUpdater"
                    />
                </div>
            </div>
        ) : (
            <div>
                <div>
                    <strong>Add IPOR Index (IporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="IporOracleLocal" method="updateIndex" />
                </div>
                <div>
                    <strong>Add updater (IporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="IporOracleLocal" method="addUpdater" />
                </div>
                <div>
                    <strong>Remove updater (IporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="IporOracleLocal" method="removeUpdater" />
                </div>
            </div>
        )}

        <div>
            <hr />
            <p>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="CockpitDataProvider"
                    method="getIndexes"
                    render={IporIndexList}
                />
            </p>
            <hr />
        </div>        
    </div>
);
