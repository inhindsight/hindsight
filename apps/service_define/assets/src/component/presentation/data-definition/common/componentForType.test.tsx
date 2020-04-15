import {componentForType} from "./componentForType"
import {PrimitiveArgumentType, ModuleFunctionArgsView} from "../../../../model/view/ModuleFunctionArgsView"
import {expect} from "chai"
import {values} from "ramda"
import {isFunction} from "lodash"
import {renderComponent} from "../../../../util/test/container"
import React from "react"
import {moduleFunctionArgsViewDefaults} from "../../../../util/test/view-defaults"

describe("componentForType()", () => {

    it("when module type returns component that renders the module", () => {
        const Component = componentForType(PrimitiveArgumentType.module)
        const module: ModuleFunctionArgsView = {
            ...moduleFunctionArgsViewDefaults,
            struct_module_name: "foo"
        }

        const element = renderComponent(<Component value={module}/>)

        expect(element.textContent).to.contain("foo")
    })

    it("when string type returns component that renders strings", () => {
        const Component = componentForType(PrimitiveArgumentType.string)
        const element = renderComponent(<Component value={"foo"}/>)

        expect(element.textContent).to.equal("foo")
    })

    it("when list of string type returns component that renders the list", () => {
        const Component = componentForType(["list", PrimitiveArgumentType.string])
        const element = renderComponent(<Component value={["foo", "bar"]}/>)

        expect(element.textContent).to.contain("foo")
        expect(element.textContent).to.contain("bar")
    })

    it("when list of module type returns component that renders the list", () => {
        const Component = componentForType(["list", PrimitiveArgumentType.module])
        const modules: readonly ModuleFunctionArgsView[] = [
            {
                struct_module_name: "Foo",
                args: [],
            }
        ]

        const element = renderComponent(<Component value={modules}/>)

        expect(element.textContent).to.contain("Foo")
    })

    it("when map type returns component that renders the map", () => {
        const Component = componentForType(PrimitiveArgumentType.map)
        const element = renderComponent(<Component value={{ foo: "bar", cake: "pie"}}/>)

        expect(element.textContent).to.contain("foo")
        expect(element.textContent).to.contain("bar")
        expect(element.textContent).to.contain("cake")
        expect(element.textContent).to.contain("pie")
    })

    it("when a null value is given it renders as null", () => {
        const Component = componentForType(PrimitiveArgumentType.string)
        const element = renderComponent(<Component value={null}/>)

        expect(element.textContent).to.contain("null")
    })

    values(PrimitiveArgumentType).forEach(type => {
        it(`returns output for ${module}`, () => {
            expect(isFunction(componentForType(type))).to.equal(true)
        })
    })

})
