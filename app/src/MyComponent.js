import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import logo from "./logo.png";

const {AccountData, ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => {
    return (
        <div className="App">
            <div>
                <img src={logo} alt="drizzle-logo"/>
                <h1>IPOR Protocol</h1>
            </div>

            <div className="section">
                <h2>Active Account</h2>
                <AccountData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    accountIndex={0}
                    units="ether"
                    precision={3}
                />
            </div>

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

            <h2>IPOR AMM</h2>

            TODO

        </div>
    );
};
