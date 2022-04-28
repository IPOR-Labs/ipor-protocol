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
                        {drizzle.contracts.MockTestnetTokenUsdt.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.MockTestnetTokenUsdc.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.MockTestnetTokenDai.address}
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Redeem Liquidity Pool Max Utilization Rate</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdt"
                                method="getRedeemLpMaxUtilizationRate"
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
                                method="getRedeemLpMaxUtilizationRate"
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
                                method="getRedeemLpMaxUtilizationRate"
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
                                method="getRedeemLpMaxUtilizationRate"
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
                                method="getRedeemLpMaxUtilizationRate"
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
                                method="getRedeemLpMaxUtilizationRate"
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
                        <strong>Milton Stanley Balance Rate</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="ItfJosephUsdt"
                                method="getMiltonStanleyBalanceRatio"
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
                                method="getMiltonStanleyBalanceRatio"
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
                                method="getMiltonStanleyBalanceRatio"
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
                                method="getMiltonStanleyBalanceRatio"
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
                                method="getMiltonStanleyBalanceRatio"
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
                                method="getMiltonStanleyBalanceRatio"
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
                                    method="getCharlieTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="setCharlieTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdt"
                                    method="getCharlieTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="setCharlieTreasury"
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
                                    method="getCharlieTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="setCharlieTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdc"
                                    method="getCharlieTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="setCharlieTreasury"
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
                                    method="getCharlieTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="setCharlieTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephDai"
                                    method="getCharlieTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="setCharlieTreasury"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasury Treasurer</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdt"
                                    method="getTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="setTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdt"
                                    method="getTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="setTreasury"
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
                                    method="getTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="setTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdc"
                                    method="getTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="setTreasury"
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
                                    method="getTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="setTreasury"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephDai"
                                    method="getTreasury"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="setTreasury"
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
                                    method="getCharlieTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="setCharlieTreasuryManager"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdt"
                                    method="getCharlieTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="setCharlieTreasuryManager"
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
                                    method="getCharlieTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="setCharlieTreasuryManager"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdc"
                                    method="getCharlieTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="setCharlieTreasuryManager"
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
                                    method="getCharlieTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="setCharlieTreasuryManager"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephDai"
                                    method="getCharlieTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="setCharlieTreasuryManager"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasury Transferer</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="ItfJosephUsdt"
                                    method="getTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="setTreasuryManager"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdt"
                                    method="getTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="setTreasuryManager"
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
                                    method="getTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdc"
                                    method="setTreasuryManager"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephUsdc"
                                    method="getTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="setTreasuryManager"
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
                                    method="getTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephDai"
                                    method="setTreasuryManager"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractData
                                    drizzle={drizzle}
                                    drizzleState={drizzleState}
                                    contract="JosephDai"
                                    method="getTreasuryManager"
                                />
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="setTreasuryManager"
                                />
                            </div>
                        )}
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
