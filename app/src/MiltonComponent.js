import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import DerivativeList from "./DerivativeList";
import AmmBalanceComponent from "./AmmBalanceComponent";
import AmmTotalBalanceComponent from "./AmmTotalBalanceComponent";
import LiquidityPoolComponent from "./LiquidityPoolComponent";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div>
            <br />
            <AmmTotalBalanceComponent
                drizzle={drizzle}
                drizzleState={drizzleState}
            />
            <AmmBalanceComponent
                drizzle={drizzle}
                drizzleState={drizzleState}
            />
            <LiquidityPoolComponent
                drizzle={drizzle}
                drizzleState={drizzleState}
            />
        </div>
        <hr />
        <table className="table" align="center">
            <tr>
                <th scope="col">Action</th>
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
                <td>Open Pay Fixed Swap</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdt"
                            method="openSwapPayFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdt"
                            method="openSwapPayFixed"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdc"
                            method="openSwapPayFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdc"
                            method="openSwapPayFixed"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonDai"
                            method="openSwapPayFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonDai"
                            method="openSwapPayFixed"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>Open Receive Fixed Swap</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdt"
                            method="openSwapReceiveFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdt"
                            method="openSwapReceiveFixed"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdc"
                            method="openSwapReceiveFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdc"
                            method="openSwapReceiveFixed"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonDai"
                            method="openSwapReceiveFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonDai"
                            method="openSwapReceiveFixed"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>Close Pay Fixed Swap</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdt"
                            method="closeSwapPayFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdt"
                            method="closeSwapPayFixed"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdc"
                            method="closeSwapPayFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdc"
                            method="closeSwapPayFixed"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonDai"
                            method="closeSwapPayFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonDai"
                            method="closeSwapPayFixed"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>Close Receive Fixed Swap</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdt"
                            method="closeSwapReceiveFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdt"
                            method="closeSwapReceiveFixed"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdc"
                            method="closeSwapReceiveFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdc"
                            method="closeSwapReceiveFixed"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonDai"
                            method="closeSwapReceiveFixed"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonDai"
                            method="closeSwapReceiveFixed"
                        />
                    )}
                </td>
            </tr>

            <tr>
                <td>Pause</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdt"
                            method="pause"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdt"
                            method="pause"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdc"
                            method="pause"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdc"
                            method="pause"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonDai"
                            method="pause"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonDai"
                            method="pause"
                        />
                    )}
                </td>
            </tr>

            <tr>
                <td>Unpause</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdt"
                            method="unpause"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdt"
                            method="unpause"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdc"
                            method="unpause"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdc"
                            method="unpause"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonDai"
                            method="unpause"
                        />
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonDai"
                            method="unpause"
                        />
                    )}
                </td>
            </tr>
        </table>
    </div>
);
