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
        <div class="row">
            {process.env.REACT_APP_ITF_ENABLED ===
            "true" ? (
                <div className="col-md-12">
                    <strong>Open Swap Pay Fixed USDT (ItfMiltonUsdt)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonUsdt"
                        method="openSwapPayFixed"
                    />
                    <br />
                    <strong>
                        Open Swap Receive Fixed USDT (ItfMiltonUsdt)
                    </strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonUsdt"
                        method="openSwapReceiveFixed"
                    />
                    <br />
                    <strong>Open Swap Pay Fixed USDC (ItfMiltonUsdc)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonUsdc"
                        method="openSwapPayFixed"
                    />
                    <br />
                    <strong>
                        Open Swap Receive Fixed USDC (ItfMiltonUsdc)
                    </strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonUsdc"
                        method="openSwapReceiveFixed"
                    />
                    <br />
                    <strong>Open Swap Pay Fixed DAI (ItfMiltonDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonDai"
                        method="openSwapPayFixed"
                    />
                    <br />
                    <strong>Open Swap Receive Fixed DAI (ItfMiltonDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonDai"
                        method="openSwapReceiveFixed"
                    />
                    <br />
                </div>
            ) : (
                <div className="col-md-12">
                    <strong>Open Swap Pay Fixed USDT (MiltonUsdt)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonUsdt"
                        method="openSwapPayFixed"
                    />
                    <br />
                    <strong>Open Swap Receive Fixed USDT (MiltonUsdt)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonUsdt"
                        method="openSwapReceiveFixed"
                    />
                    <br />
                    <strong>Open Swap Pay Fixed USDC (MiltonUsdc)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonUsdc"
                        method="openSwapPayFixed"
                    />
                    <br />
                    <strong>Open Swap Receive Fixed USDC (MiltonUsdc)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonUsdc"
                        method="openSwapReceiveFixed"
                    />
                    <br />
                    <strong>Open Swap Pay Fixed DAI (MiltonDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonDai"
                        method="openSwapPayFixed"
                    />
                    <br />
                    <strong>Open Swap Receive Fixed DAI (MiltonDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonDai"
                        method="openSwapReceiveFixed"
                    />
                    <br />
                </div>
            )}
        </div>
        <hr />
        <div class="row">
            {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                <div className="col-md-4">
                    <strong>Provide Liquidity USDT (ItfJosephUsdt)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfJosephUsdt"
                        method="provideLiquidity"
                    />
                    <br />
                    <strong>Provide Liquidity USDC (ItfJosephUsdc)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfJosephUsdc"
                        method="provideLiquidity"
                    />
                    <br />
                    <strong>Provide Liquidity DAI (ItfJosephDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfJosephDai"
                        method="provideLiquidity"
                    />
                    <br />
                </div>
            ) : (
                <div className="col-md-4">
                    <strong>Provide Liquidity USDT (JosephUsdt)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="JosephUsdt"
                        method="provideLiquidity"
                    />
                    <br />
                    <strong>Provide Liquidity USDC (JosephUsdc)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="JosephUsdc"
                        method="provideLiquidity"
                    />
                    <br />
                    <strong>Provide Liquidity DAI (JosephDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="JosephDai"
                        method="provideLiquidity"
                    />
                    <br />
                </div>
            )}
            {process.env.REACT_APP_ITF_ENABLED ===
            "true" ? (
                <div className="col-md-4">
                    <strong>Redeem USDT (ItfJosephUsdt)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfJosephUsdt"
                        method="redeem"
                    />
                    <br />
                    <strong>Redeem USDC (ItfJosephUsdc)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfJosephUsdc"
                        method="redeem"
                    />
                    <br />
                    <strong>Redeem DAI (ItfJosephDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfJosephDai"
                        method="redeem"
                    />
                    <br />
                </div>
            ) : (
                <div className="col-md-4">
                    <strong>Redeem USDT(JosephUsdt)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="JosephUsdt"
                        method="redeem"
                    />
                    <br />
                    <strong>Redeem USDC (JosephUsdc)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="JosephUsdc"
                        method="redeem"
                    />
                    <br />
                    <strong>Redeem DAI (JosephDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="JosephDai"
                        method="redeem"
                    />
                    <br />
                </div>
            )}
            {process.env.REACT_APP_ITF_ENABLED ===
            "true" ? (
                <div className="col-md-4">
                    <strong>Close Pay Fixed Swap - USDT (ItfMiltonUsdt)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonUsdt"
                        method="closeSwapPayFixed"
                    />
                    <br />
                    <strong>
                        Close Receive Fixed Swap - USDT (ItfMiltonUsdt)
                    </strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonUsdt"
                        method="closeSwapReceiveFixed"
                    />
                    <br />
                    <strong>Close Pay Fixed Swap - USDC (ItfMiltonUsdc)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonUsdc"
                        method="closeSwapPayFixed"
                    />
                    <br />
                    <strong>
                        Close Receive Fixed Swap - USDC (ItfMiltonUsdc)
                    </strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonUsdc"
                        method="closeSwapReceiveFixed"
                    />
                    <br />
                    <strong>Close Pay Fixed Swap - DAI (ItfMiltonDai)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonDai"
                        method="closeSwapPayFixed"
                    />
                    <br />
                    <strong>
                        Close Receive Fixed Swap - DAI (ItfMiltonDai)
                    </strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="ItfMiltonDai"
                        method="closeSwapReceiveFixed"
                    />
                </div>
            ) : (
                <div className="col-md-4">
                    <strong>Close Position Form (MiltonUsdt) - USDT</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonUsdt"
                        method="closePosition"
                    />
                    <br />
                    <strong>Close Position Form (MiltonUsdc) - USDC</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonUsdc"
                        method="closePosition"
                    />
                    <br />
                    <strong>Close Position Form (MiltonDai) - DAI</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonDai"
                        method="closePosition"
                    />
                    <br />
                </div>
            )}
        </div>
    </div>
);
