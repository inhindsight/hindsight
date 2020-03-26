import {componentForType, ModuleFunctionArgsWrapper, StringWrapper} from "./componentForType"
import {PrimitiveArgumentType} from "../../../../model/view/ModuleFunctionArgsView"
import {expect} from "chai"
import {values} from "ramda"
import {isFunction} from "lodash"

describe("componentForType()", () => {

    it("when type module returns module function args wrapper", () => {
        expect(componentForType(PrimitiveArgumentType.module)).to.equal(ModuleFunctionArgsWrapper)
    })

    it("when any other type returns string wrapper", () => {
        expect(componentForType(PrimitiveArgumentType.float)).to.equal(StringWrapper)
    })

    values(PrimitiveArgumentType).forEach(type => {
        it(`returns output for ${module}`, () => {
            expect(isFunction(componentForType(type))).to.equal(true)
        })
    })

})
