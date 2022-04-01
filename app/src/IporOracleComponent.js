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
                    <ContractForm drizzle={drizzle} contract="ItfIporOracle" method="updateIndex" />
                </div>
                <div>
                    <strong>Add updater (ItfIporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="ItfIporOracle" method="addUpdater" />
                </div>
                <div>
                    <strong>Remove updater (ItfIporOracle)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfIporOracle"
                        method="removeUpdater"
                    />
                </div>
            </div>
        ) : (
            <div>
                <div>
                    <strong>Add IPOR Index (IporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="IporOracle" method="updateIndex" />
                </div>
                <div>
                    <strong>Add updater (IporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="IporOracle" method="addUpdater" />
                </div>
                <div>
                    <strong>Remove updater (IporOracle)</strong>
                    <ContractForm drizzle={drizzle} contract="IporOracle" method="removeUpdater" />
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
        <div className="row">
            <div className="col-md-3">
                <label>Pause</label>

                {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                    <ContractForm drizzle={drizzle} contract="ItfIporOracle" method="pause" />
                ) : (
                    <ContractForm drizzle={drizzle} contract="IporOracle" method="pause" />
                )}
            </div>
            <div className="col-md-3">
                <label>Unpause</label>

                {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                    <ContractForm drizzle={drizzle} contract="ItfIporOracle" method="unpause" />
                ) : (
                    <ContractForm drizzle={drizzle} contract="IporOracle" method="unpause" />
                )}
            </div>
            <div className="col-md-3">
                <label>Transfer Ownership</label>

                {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfIporOracle"
                        method="transferOwnership"
                    />
                ) : (
                    <ContractForm
                        drizzle={drizzle}
                        contract="IporOracle"
                        method="transferOwnership"
                    />
                )}
            </div>

            <div className="col-md-3">
                <label>Confirm Transfer Ownership</label>

                {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfIporOracle"
                        method="confirmTransferOwnership"
                    />
                ) : (
                    <ContractForm
                        drizzle={drizzle}
                        contract="IporOracle"
                        method="confirmTransferOwnership"
                    />
                )}
            </div>
        </div>
    </div>
);
