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
                        <strong>Redeem Liquidity Pool Max Utilization Percentage</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdt"
                                method="getRedeemLpMaxUtilizationPercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephUsdt"
                                method="getRedeemLpMaxUtilizationPercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdc"
                                method="getRedeemLpMaxUtilizationPercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephUsdc"
                                method="getRedeemLpMaxUtilizationPercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephDai"
                                method="getRedeemLpMaxUtilizationPercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephDai"
                                method="getRedeemLpMaxUtilizationPercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Milton Stanley Balance Percentage</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdt"
                                method="getMiltonStanleyBalancePercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephUsdt"
                                method="getMiltonStanleyBalancePercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdc"
                                method="getMiltonStanleyBalancePercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephUsdc"
                                method="getMiltonStanleyBalancePercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephDai"
                                method="getMiltonStanleyBalancePercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        ) : (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="JosephDai"
                                method="getMiltonStanleyBalancePercentage"
                                render={(value) => (
                                    <div>
                                        {value / 1000000000000000000}
                                        <br />
                                        <small>{value}</small>
                                    </div>
                                )}
                            />
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Charlie Treasurer</strong>
                        <small></small>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdt"
                                    method="getCharlieTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="setCharlieTreasurer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdt"
                                    method="getCharlieTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="setCharlieTreasurer"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdc"
                                    method="getCharlieTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="setCharlieTreasurer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdc"
                                    method="getCharlieTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="setCharlieTreasurer"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephDai"
                                    method="getCharlieTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="setCharlieTreasurer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephDai"
                                    method="getCharlieTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="setCharlieTreasurer"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasure Treasurer</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdt"
                                    method="getTreasureTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="setTreasureTreasurer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdt"
                                    method="getTreasureTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="setTreasureTreasurer"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdc"
                                    method="getTreasureTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="setTreasureTreasurer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdc"
                                    method="getTreasureTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="setTreasureTreasurer"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephDai"
                                    method="getTreasureTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="setTreasureTreasurer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephDai"
                                    method="getTreasureTreasurer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="setTreasureTreasurer"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Publication Fee Transferer</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdt"
                                    method="getPublicationFeeTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="setPublicationFeeTransferer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdt"
                                    method="getPublicationFeeTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="setPublicationFeeTransferer"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdc"
                                    method="getPublicationFeeTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="setPublicationFeeTransferer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdc"
                                    method="getPublicationFeeTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="setPublicationFeeTransferer"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephDai"
                                    method="getPublicationFeeTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="setPublicationFeeTransferer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephDai"
                                    method="getPublicationFeeTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="setPublicationFeeTransferer"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasure Transferer</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdt"
                                    method="getTreasureTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="setTreasureTransferer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdt"
                                    method="getTreasureTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="setTreasureTransferer"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdc"
                                    method="getTreasureTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="setTreasureTransferer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdc"
                                    method="getTreasureTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="setTreasureTransferer"
                                />
                            </div>
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephDai"
                                    method="getTreasureTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="setTreasureTransferer"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephDai"
                                    method="getTreasureTransferer"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="setTreasureTransferer"
                                />
                            </div>
                        )}
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
