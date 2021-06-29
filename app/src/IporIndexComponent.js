import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import IporIndexList from "./IporIndexList";

const {AccountData, ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <h2>Oracle IPOR Index</h2>
        <div class="section">
            <p>
                <strong>Add IPOR Index</strong>
                <ContractForm drizzle={drizzle} contract="IporOracle" method="updateIndex"/>
            </p>
            <p>
                <strong>Add updater</strong>
                <ContractForm drizzle={drizzle} contract="IporOracle" method="addUpdater"/>
            </p>
            <p>
                <strong>Remove updater</strong>
                <ContractForm drizzle={drizzle} contract="IporOracle" method="removeUpdater"/>
            </p>
            <p>
                <strong>Updaters</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporOracle"
                    method="getUpdaters"
                />
            </p>
        </div>
        <div>
            <hr/>
            <p>
                <h4>IPOR Indexes</h4>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporOracle"
                    method="getIndexes"
                    render={IporIndexList}
                />
            </p>
            <hr/>
        </div>
    </div>
);