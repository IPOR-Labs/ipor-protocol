
import React from 'react';
import {DrizzleContext} from "@drizzle/react-plugin";
import {Drizzle} from "@drizzle/store";
import drizzleOptions from "./drizzleOptions";
import MainComponent from "./MainComponent";
import "./App.css";
const drizzle = new Drizzle(drizzleOptions);

const App = () => {


    // const [accounts, setAccounts] = useState(undefined);
    //
    // useEffect(() => {
    //     window.ethereum.on('accountsChanged', accounts => {
    //         setAccounts(accounts);
    //     });
    // }, []);
    return (
        <DrizzleContext.Provider drizzle={drizzle}>
            <DrizzleContext.Consumer>
                {drizzleContext => {
                    const {drizzle, drizzleState, initialized} = drizzleContext;

                    if (!initialized) {
                        return "Loading..."
                    }

                    return (
                        <MainComponent drizzle={drizzle} drizzleState={drizzleState}/>
                    )
                }}
            </DrizzleContext.Consumer>
        </DrizzleContext.Provider>
    );
}

export default App;
