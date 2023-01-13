import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import IporIndexList from "./IporIndexList";

const { AccountData, ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div>
            <div>
                <strong>Add IPOR Index</strong>
                <ContractForm drizzle={drizzle} contract="DrizzleIporOracle" method="updateIndex" />
            </div>
            <div>
                <strong>Add updater</strong>
                <ContractForm drizzle={drizzle} contract="DrizzleIporOracle" method="addUpdater" />
            </div>
            <div>
                <strong>Remove updater</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="DrizzleIporOracle"
                    method="removeUpdater"
                />
            </div>
        </div>
		<hr/>
        <table className="table" align="center">
            <tr>
                <th scope="col">Parameter</th>
                <th scope="col">Form</th>
                <th scope="col">Value</th>
            </tr>
            <tr>
                <td>
                    <strong>IPOR Algorithm Facade Address</strong>
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleIporOracle"
                        method="setIporAlgorithmFacade"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleIporOracle"
                        method="getIporAlgorithmFacade"
                    />
                </td>
            </tr>
        </table>
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
