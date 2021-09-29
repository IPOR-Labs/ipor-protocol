import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import IporIndexList from "./IporIndexList";

const {AccountData, ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <div class="section">
            <p>
                <strong>Add IPOR Index</strong>
                <ContractForm drizzle={drizzle} contract="Warren" method="updateIndex"/>
            </p>
            <p>
                <strong>Add updater</strong>
                <ContractForm drizzle={drizzle} contract="WarrenStorage" method="addUpdater"/>
            </p>
            <p>
                <strong>Remove updater</strong>
                <ContractForm drizzle={drizzle} contract="WarrenStorage" method="removeUpdater"/>
            </p>
            <p>
                <strong>Updaters</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="WarrenStorage"
                    method="getUpdaters"
                />
            </p>
        </div>
        <div>
            <hr/>
            <p>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="WarrenDevToolDataProvider"
                    method="getIndexes"
                    render={IporIndexList}
                />
            </p>
            <hr/>
        </div>
    </div>
);