import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        {drizzle.contracts.UsdtMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.UsdcMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DaiMockedToken.address}
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Version</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdt"
                                method="getVersion"
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephUsdt"
                                method="getVersion"
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdc"
                                method="getVersion"
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephUsdc"
                                method="getVersion"
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephDai"
                                method="getVersion"
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephDai"
                                method="getVersion"
                            />
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Rebalance</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="rebalance"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="rebalance"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="rebalance"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="rebalance"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="rebalance"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="rebalance"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Deposit to Stanley</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="depositToVault"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="depositToVault"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="depositToVault"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="depositToVault"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="depositToVault"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="depositToVault"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Withdraw from Stanley</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="withdrawFromVault"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="withdrawFromVault"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="withdrawFromVault"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="withdrawFromVault"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="withdrawFromVault"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="withdrawFromVault"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Transfer Treasury</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="transferTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="transferTreasury"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="transferTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="transferTreasury"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="transferTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="transferTreasury"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Transfer Publication Fee</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="transferPublicationFee"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="transferPublicationFee"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="transferPublicationFee"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="transferPublicationFee"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="transferPublicationFee"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="transferPublicationFee"
                                />
                            </div>
                        )}
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
