import React from "react";
import {newContextComponents} from "@drizzle/react-components";
const {AccountData, ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <h2>IPOR Index</h2>
        <div className="section">
            <p>
                <strong>Index values: </strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporOracle"
                    method="getIndexes"
                />
            </p>
            <ContractForm drizzle={drizzle} contract="IporOracle" method="updateIndex"/>

            <p>
                <strong>Add updater</strong>
                <ContractForm drizzle={drizzle} contract="IporOracle" method="addUpdater"/>
            </p>

            <p>
                <strong>Remove updater</strong>
                <ContractForm drizzle={drizzle} contract="IporOracle" method="removeUpdater"/>
            </p>

            <p>
                <strong>List updater</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporOracle"
                    method="getUpdaters"
                />
            </p>
        </div>
    </div>
);