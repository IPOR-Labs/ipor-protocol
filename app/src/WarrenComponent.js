import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import IporIndexList from "./IporIndexList";

const { AccountData, ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
            <div>
                <div>
                    <strong>Add IPOR Index (ItfWarren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="updateIndex"
                    />
                </div>
                <div>
                    <strong>Add updater (ItfWarren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="addUpdater"
                    />
                </div>
                <div>
                    <strong>Remove updater (ItfWarren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="removeUpdater"
                    />
                </div>
            </div>
        ) : (
            <div>
                <div>
                    <strong>Add IPOR Index (Warren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="updateIndex"
                    />
                </div>
                <div>
                    <strong>Add updater (Warren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="addUpdater"
                    />
                </div>
                <div>
                    <strong>Remove updater (Warren)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="removeUpdater"
                    />
                </div>
            </div>
        )}

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
        <div className="row">
            <div className="col-md-3">
                <label>Pause</label>

                {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="pause"
                    />
                ) : (
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="pause"
                    />
                )}
            </div>
            <div className="col-md-3">
                <label>Unpause</label>

                {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="unpause"
                    />
                ) : (
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="unpause"
                    />
                )}
            </div>
            <div className="col-md-3">
                <label>Transfer Ownership</label>

                {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="transferOwnership"
                    />
                ) : (
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="transferOwnership"
                    />
                )}
            </div>

            <div className="col-md-3">
                <label>Confirm Transfer Ownership</label>

                {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfWarren"
                        method="confirmTransferOwnership"
                    />
                ) : (
                    <ContractForm
                        drizzle={drizzle}
                        contract="Warren"
                        method="confirmTransferOwnership"
                    />
                )}
            </div>
        </div>
    </div>
);
