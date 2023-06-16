PROJECT = "PWM-Controler"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

_G.sys = require("sys")

if wdt then
    wdt.init(9000)
    sys.timerLoopStart(wdt.feed, 3000)
end

local PWM_ID = 12
gpio.debounce(6, 100)
gpio.debounce(7, 100)

pwm.open(PWM_ID, 20000, 1)

local h, t, r = sensor.dht1x(13, true)

function test1()
    log.info("dht11", h/100,t/100,r)
end

    local speed = 0

    local function increaseSpeed()
        speed = speed + 5
        if speed > 50 then
            speed = 50
        end
        log.info("pwm", "speed now", speed, "%")
        pwm.open(PWM_ID, 1000, speed)
    end
    
    local function decreaseSpeed()
        speed = speed - 5
        if speed < 0 then
            speed = 0
        end
        log.info("pwm", "speed now", speed, "%")
        pwm.open(PWM_ID, 1000, speed)
    end
    
    sys.taskInit(function()

        local increaseButtonPin = 6
        local decreaseButtonPin = 7
        local increaseButtonState = 0
        local decreaseButtonState = 0
    
        gpio.setup(increaseButtonPin, function(level)
            increaseButtonState = level
            if increaseButtonState == 1 then
                increaseSpeed()
            end
        end, gpio.PULLUP,gpio.BOTH)
        gpio.setup(decreaseButtonPin, function(level)
            decreaseButtonState = level
            if decreaseButtonState == 1 then
                decreaseSpeed()
            end
        end, gpio.PULLUP,gpio.BOTH)
    end)
    sys.timerLoopStart(test1, 5000)


sys.run()
