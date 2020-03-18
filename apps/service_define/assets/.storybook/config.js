import { addParameters, configure } from "@storybook/react";

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
