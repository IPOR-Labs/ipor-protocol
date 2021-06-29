import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import logo from "./logo.png";
import {Tabs} from "react-bootstrap";
import {Tab} from "bootstrap";
import IporIndexComponent from "./IporIndexComponent";
import IporAmmComponent from "./IporAmmComponent";


const {AccountData, ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => {
    return (
        <div className="App">

            <div>
                <img src={logo} alt="drizzle-logo"/>
                <h1>IPOR Protocol</h1>
            </div>

            <div className="section">
                <h2>Active Account</h2>
                <AccountData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    accountIndex={0}
                    units="ether"
                    precision={3}
                />
            </div>

            <Tabs defaultActiveKey="profile" id="uncontrolled-tab-example">
                <Tab eventKey="iporIndex" title="Oracle IPOR Index">
                    <IporIndexComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="iporAmm" title="IPOR AMM">
                    <IporAmmComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
            </Tabs>
        </div>
    );
}
