import "./theme/sass/main.scss";
import {Elm} from "./elm/Main.elm";
import initSidebar from "./js/components/LeftSidebar";
import initAreaEditors from "./js/components/AreaEditor";

(function() {
    // Init Elm application
    const initialSeed = Math.floor(Math.random()*0x0FFFFFFF);
    const windowSize = {width: window.innerWidth, height: window.innerHeight};
    const app = Elm.Main.init({flags: {initialSeed, windowSize}});

    // Init JS-powered components
    initSidebar();
    initAreaEditors(document.body);
}());

