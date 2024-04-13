import { Component } from "react";

function App(){
    let Component
    switch (window.location.pathname){
        case "/": 
        Component=App;
        break;
        case "/Home":
            Component=Home;
            break;
        case "/Drive":
            Component=Drive;
        break;
        case "/Ride":
            Component=Ride;
            break;
        case "/Login":
            Component=Login;
            break;

    }
    return (
        <>
        <Navbar />
        <div className="container">{Component}</div>
        </>
    )

}
export default App