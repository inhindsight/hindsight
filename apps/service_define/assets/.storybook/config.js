import { addParameters, configure } from "@storybook/react";
import "bootstrap/dist/css/bootstrap.css"

addParameters({
    options: {
        showPanel: false,
    },
})

function loadStories() {
        function requireAll(r) { r.keys().forEach(r); }
        requireAll(require.context("../src/component", true, /\.stories\.tsx$/));
}

configure(loadStories, module);
