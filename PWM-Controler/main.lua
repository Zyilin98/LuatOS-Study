PROJECT = "PWM-Controler"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

_G.sys = require("sys")

if wdt then
    wdt.init(5000)
    sys.timerLoopStart(wdt.feed, 2000)
end


local PWM_ID = 3
gpio.debounce(6, 100)
gpio.debounce(7, 100)

pwm.open(PWM_ID, 200, 1)

local h, t, r = sensor.dht1x(13, true)

function test1()
    log.info("dht11", h/100,t/100,r)
end
gpio.debounce(1, 100)
gpio.debounce(4, 100)


local ec11 = require("ec11")


local GPIO_A = 1
local GPIO_B = 4
ec11.init(GPIO_A,GPIO_B)
local speed = 0
local function ec11_callBack(direction)
    if direction == "left" then
        -- 往左选,逆时针
        speed = speed - 1
    else
        -- 往右旋,顺时针
        speed = speed + 1
    end
    if speed > 100 then
        speed = 5

    end
    if speed < 0 then
        speed = 0
    end
    pwm.open(PWM_ID, 200, speed)
    log.info("pwm", "speed now", speed, "%")
end

sys.subscribe("ec11",ec11_callBack)

sys.run()
