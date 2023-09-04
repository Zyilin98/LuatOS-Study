local ec11 = {}
local sys = require "sys"

local A = false
local B = false

function ec11.init(GPIO_A,GPIO_B)
    gpio.debounce(GPIO_A, 10)
    gpio.debounce(GPIO_B, 10)

    gpio.setup(GPIO_A, function()
        if B then
            sys.publish("ec11","left")
            A = false
            B = false
        else
            A = true
        end
    end,gpio.PULLUP,gpio.FALLING)

    gpio.setup(GPIO_B, function()
        if A then
            sys.publish("ec11","right")
            A = false
            B = false
        else
            B = true
        end
    end,gpio.PULLUP,gpio.FALLING)
end

return ec11

