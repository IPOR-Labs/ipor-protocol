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
                        <strong>Provide Liquidity</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephUsdt"
                                method="provideLiquidity"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephUsdt"
                                method="provideLiquidity"
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephUsdc"
                                method="provideLiquidity"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephUsdc"
                                method="provideLiquidity"
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephDai"
                                method="provideLiquidity"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephDai"
                                method="provideLiquidity"
                            />
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Redeem</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephUsdt"
                                method="redeem"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephUsdt"
                                method="redeem"
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephUsdc"
                                method="redeem"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephUsdc"
                                method="redeem"
                            />
                        )}
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <ContractForm
                                drizzle={drizzle}
                                contract="ItfJosephDai"
                                method="redeem"
                            />
                        ) : (
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephDai"
                                method="redeem"
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
                                    method="depositToStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="depositToStanley"
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
                                    method="depositToStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="depositToStanley"
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
                                    method="depositToStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="depositToStanley"
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
                                    method="withdrawFromStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="withdrawFromStanley"
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
                                    method="withdrawFromStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="withdrawFromStanley"
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
                                    method="withdrawFromStanley"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="withdrawFromStanley"
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

                <tr>
                    <td>
                        <strong>Pause</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="pause"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="pause"
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
                                    method="pause"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="pause"
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
                                    method="pause"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="pause"
                                />
                            </div>
                        )}
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Unpause</strong>
                    </td>
                    <td>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="ItfJosephUsdt"
                                    method="unpause"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdt"
                                    method="unpause"
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
                                    method="unpause"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephUsdc"
                                    method="unpause"
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
                                    method="unpause"
                                />
                            </div>
                        ) : (
                            <div>
                                <ContractForm
                                    drizzle={drizzle}
                                    contract="JosephDai"
                                    method="unpause"
                                />
                            </div>
                        )}
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
