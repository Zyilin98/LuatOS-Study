PROJECT = "PWM-Controler"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

_G.sys = require("sys")
-- 丢狗，10S后饿狗，每3S喂狗
if wdt then
    wdt.init(10000)
    sys.timerLoopStart(wdt.feed, 3000)
end

-- UI带屏的项目一般不需要低功耗了吧, Air101/Air103设置到最高性能
if mcu and (rtos.bsp() == "AIR101" or rtos.bsp() == "AIR103" or rtos.bsp() == "AIR601" ) then
    mcu.setClk(240)
end
-- 声明GPIO
local PWM_ID = 3
-- 打开PWM口
pwm.open(PWM_ID, 440, 1)
-- 防抖设置200ms
gpio.debounce(2, 200)
gpio.debounce(3, 200)
gpio.debounce(17, 50)
-- 初始化显示屏
local rtos_bsp = rtos.bsp()

-- hw_i2c_id,sw_i2c_scl,sw_i2c_sda,spi_id,spi_res,spi_dc,spi_cs
function u8g2_pin()     
    if rtos_bsp == "AIR101" then
        return 0,pin.PA01,pin.PA04,0,pin.PB03,pin.PB01,pin.PB04
    elseif rtos_bsp == "AIR103" then
        return 0,pin.PA01,pin.PA04,0,pin.PB03,pin.PB01,pin.PB04
    elseif rtos_bsp == "AIR105" then
        return 0,pin.PE06,pin.PE07,5,pin.PC12,pin.PE08,pin.PC14
    elseif rtos_bsp == "ESP32C3" then
        return 0,5,4,2,10,9,7,11
    elseif rtos_bsp == "ESP32S3" then
        return 0,12,11,2,16,15,14,13
    elseif rtos_bsp == "EC618" then
        return 0,10,11,0,1,10,8,18
    else
        log.info("main", "bsp not support")
        return
    end
end

local hw_i2c_id,sw_i2c_scl,sw_i2c_sda,spi_id,spi_res,spi_dc,spi_cs = u8g2_pin() 

-- 日志TAG, 非必须
local TAG = "main"

-- 初始化显示屏
log.info(TAG, "init ssd1306")

-- 初始化硬件i2c的ssd1306
u8g2.begin({ic = "ssd1306",direction = 0,mode="i2c_hw",i2c_id=hw_i2c_id,i2c_speed = i2c.FAST}) -- direction 可选0 90 180 270
-- 初始化软件i2c的ssd1306
-- u8g2.begin({ic = "ssd1306",direction = 0,mode="i2c_sw", i2c_scl=sw_i2c_scl, i2c_sda=sw_i2c_sda})
-- 初始化硬件spi的ssd1306
-- u8g2.begin({ic = "ssd1306",direction = 0,mode="spi_hw_4pin",spi_id=spi_id,spi_res=spi_res,spi_dc=spi_dc,spi_cs=spi_cs})

u8g2.SetFontMode(1)
u8g2.ClearBuffer()
u8g2.SetFont(u8g2.font_opposansm10_chinese)
u8g2.DrawUTF8("LuatOS风扇测试器", 8, 22)
u8g2.DrawUTF8("基于PWM调速原理", 8, 42)
u8g2.SendBuffer()

--导入ec11库
local ec11 = require("ec11")
-- 声明ec11两个io脚位
local GPIO_A = 2
local GPIO_B = 3
-- 向ec11库传递gpio脚位数据
ec11.init(GPIO_A,GPIO_B)
-- 正式程序
local speed = 0
local function ec11_callBack(direction)
    if direction == "left" then
        -- 左旋,逆时针
        speed = speed - 5
    else
        -- 右旋,顺时针
        speed = speed + 5
    end
        -- 控制上限
    if speed > 100 then
        speed = 100
    end
        --控制下限
    if speed < 0 then
        speed = 0
    end
    u8g2.ClearBuffer()
    u8g2.SetFont(u8g2.font_opposansm10_chinese)
    u8g2.DrawUTF8("当前速度: ",10, 15)
    u8g2.DrawUTF8(speed,65,15)
    u8g2.DrawUTF8("%",90,15)
    u8g2.SendBuffer()
    pwm.open(PWM_ID, 440, speed)    
    log.info("pwm", "speed now", speed, "%")
end
--测试计算频率
-- 设置GPIO口为输入模式，并启用内部上拉

-- 定义变量用于存储脉冲计数和时间戳
sys.taskInit(function()

        local freqpin = 17
        local pulseState = 1
        local pulse_count = 0
        local hz = mcu.hz()

        gpio.setup(freqpin, function(level)
            if level == 0 then
                pulse_count = pulse_count + 1                
            end
            if pulse_count == 0 then
                local last_time = mcu.ticks
            end
            if pulse_count == 2 then
                -- 获取当前时间戳（单位为毫秒）
                local current_time = mcu.ticks
                -- 计算时间差和频率
                local time_diff = current_time - last_time
                local freq = hz / time_diff
                local pulse_count = 0
                -- 输出频率
                log.info("freq", freq)
            end
        end, gpio.PULLUP,gpio.RISING)
    end)

sys.subscribe("ec11",ec11_callBack)

sys.run()
