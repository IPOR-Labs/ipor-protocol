import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div class="row">
            <div class="col-md-2">
                JosephUsdt {drizzle.contracts.JosephUsdt.address}
            </div>
            <div class="col-md-10">
                <p>
                    Decimals:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephUsdt"
                        method="decimals"
                    />
                </p>
				<p>
                    Asset:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephUsdt"
                        method="asset"
                    />
                </p>
				<p>
                    IporConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephUsdt"
                        method="getIporConfiguration"
                    />
                </p>
				<p>
                    IporAssetConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephUsdt"
                        method="getIporAssetConfiguration"
                    />
                </p>
            </div>
        </div>
		<div class="row">
            <div class="col-md-2">
                JosephUsdc {drizzle.contracts.JosephUsdc.address}
            </div>
            <div class="col-md-10">
                <p>
                    Decimals:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephUsdc"
                        method="decimals"
                    />
                </p>
				<p>
                    Asset:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephUsdc"
                        method="asset"
                    />
                </p>
				<p>
                    IporConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephUsdc"
                        method="getIporConfiguration"
                    />
                </p>
				<p>
                    IporAssetConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephUsdc"
                        method="getIporAssetConfiguration"
                    />
                </p>
            </div>
        </div>
		<div class="row">
            <div class="col-md-2">
                JosephDai {drizzle.contracts.JosephDai.address}
            </div>
            <div class="col-md-10">
                <p>
                    Decimals:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephDai"
                        method="decimals"
                    />
                </p>
				<p>
                    Asset:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephDai"
                        method="asset"
                    />
                </p>
				<p>
                    IporConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephDai"
                        method="getIporConfiguration"
                    />
                </p>
				<p>
                    IporAssetConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="JosephDai"
                        method="getIporAssetConfiguration"
                    />
                </p>
            </div>
        </div>
		<div class="row">
            <div class="col-md-2">
                ItfJosephUsdt {drizzle.contracts.ItfJosephUsdt.address}
            </div>
            <div class="col-md-10">
                <p>
                    Decimals:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephUsdt"
                        method="decimals"
                    />
                </p>
				<p>
                    Asset:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephUsdt"
                        method="asset"
                    />
                </p>
				<p>
                    IporConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephUsdt"
                        method="getIporConfiguration"
                    />
                </p>
				<p>
                    IporAssetConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephUsdt"
                        method="getIporAssetConfiguration"
                    />
                </p>
            </div>
        </div>
		<div class="row">
            <div class="col-md-2">
                ItfJosephUsdc {drizzle.contracts.ItfJosephUsdc.address}
            </div>
            <div class="col-md-10">
                <p>
                    Decimals:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephUsdc"
                        method="decimals"
                    />
                </p>
				<p>
                    Asset:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephUsdc"
                        method="asset"
                    />
                </p>
				<p>
                    IporConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephUsdc"
                        method="getIporConfiguration"
                    />
                </p>
				<p>
                    IporAssetConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephUsdc"
                        method="getIporAssetConfiguration"
                    />
                </p>
            </div>
        </div>
		<div class="row">
            <div class="col-md-2">
                ItfJosephDai {drizzle.contracts.ItfJosephDai.address}
            </div>
            <div class="col-md-10">
                <p>
                    Decimals:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephDai"
                        method="decimals"
                    />
                </p>
				<p>
                    Asset:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephDai"
                        method="asset"
                    />
                </p>
				<p>
                    IporConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephDai"
                        method="getIporConfiguration"
                    />
                </p>
				<p>
                    IporAssetConfiguration:&nbsp;
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="ItfJosephDai"
                        method="getIporAssetConfiguration"
                    />
                </p>
            </div>
        </div>
		
    </div>
);
