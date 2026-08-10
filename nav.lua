-- Smart Cyberpunk GPS Navigator v2.4
-- Ultra-fast GPS polling with change-detection (renders only on movement)

local targetX, targetZ

local function printCentered(y, text, textColor, bgColor)
    local w, h = term.getSize()
    term.setCursorPos(math.floor((w - #text) / 2) + 1, y)
    if textColor then term.setTextColor(textColor) end
    if bgColor then term.setBackgroundColor(bgColor) end
    term.write(text)
end

local function clearScreen(bgColor)
    term.setBackgroundColor(bgColor or colors.black)
    term.clear()
end

local function getTarget()
    clearScreen(colors.gray)
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.cyan)
    term.clearLine()
    printCentered(1, " [ TARGET COORDS ] ", colors.black, colors.cyan)
    
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    
    term.setCursorPos(2, 3)
    term.write("Enter Target X:")
    term.setCursorPos(2, 4)
    term.setBackgroundColor(colors.black)
    term.write("               ")
    term.setCursorPos(2, 4)
    local tx = tonumber(io.read())
    
    term.setBackgroundColor(colors.gray)
    term.setCursorPos(2, 6)
    term.write("Enter Target Z:")
    term.setCursorPos(2, 7)
    term.setBackgroundColor(colors.black)
    term.write("               ")
    term.setCursorPos(2, 7)
    local tz = tonumber(io.read())
    
    if not tx or not tz then
        clearScreen(colors.red)
        printCentered(4, "ERROR:", colors.white, colors.red)
        printCentered(5, "Invalid numbers!", colors.white, colors.red)
        os.sleep(1)
        return nil, nil
    end
    return tx, tz
end

targetX, targetZ = getTarget()
if not targetX then return end

-- Radar frames for 8 directions
local radars = {
    N  = { " | ", " o ", "   " },
    NE = { "  /", " o ", "   " },
    E  = { "   ", " o-", "   " },
    SE = { "   ", " o ", "  \\" },
    S  = { "   ", " o ", " | " },
    SW = { "   ", " o ", "/  " },
    W  = { "   ", "-o ", "   " },
    NW = { "\\  ", " o ", "   " }
}

-- Переменные для хранения предыдущей позиции (память рендера)
local lastX, lastZ = nil, nil
local firstRender = true

while true do
    -- Быстрый опрос GPS каждые 0.05 сек (1 тик)
    os.sleep(0.05)
    
    local gpsX, gpsY, gpsZ = gps.locate(2)
    
    if not gpsX then
        -- Если сигнал потерян, выводим ошибку один раз, чтобы не спамить экран
        if lastX ~= "LOST" then
            clearScreen(colors.black)
            term.setBackgroundColor(colors.lightBlue)
            term.setCursorPos(1, 1)
            term.clearLine()
            printCentered(1, ">> GPS RADAR ACTIVE <<", colors.black, colors.lightBlue)
            
            term.setBackgroundColor(colors.black)
            printCentered(5, " [ SIGNAL LOST ] ", colors.white, colors.red)
            printCentered(7, "RECONNECTING TO HOSTS...", colors.gray, colors.black)
            printCentered(13, "[ Hold Ctrl+T to exit ]", colors.gray, colors.black)
            lastX = "LOST"
        end
    else
        local curX = math.floor(gpsX)
        local curZ = math.floor(gpsZ)
        
        -- УМНАЯ ПРОВЕРКА: Рисуем только если это первый запуск ИЛИ координаты изменились
        if firstRender or curX ~= lastX or curZ ~= lastZ then
            firstRender = false
            lastX = curX
            lastZ = curZ
            
            clearScreen(colors.black)
            
            -- Neon top header
            term.setBackgroundColor(colors.lightBlue)
            term.setCursorPos(1, 1)
            term.clearLine()
            printCentered(1, ">> GPS RADAR ACTIVE <<", colors.black, colors.lightBlue)
            
            -- Расчеты вектора и расстояния
            local dx = targetX - curX
            local dz = targetZ - curZ
            local distance = math.floor(math.sqrt(dx^2 + dz^2))
            
            -- Вычисление угла азимута Minecraft
            local angle = math.atan2(dx, -dz) * 180 / math.pi
            if angle < 0 then angle = angle + 360 end

            local direction = ""
            local radIdx = "N"
            
            if angle >= 337.5 or angle < 22.5 then direction = "NORTH"; radIdx = "N"
            elseif angle >= 22.5 and angle < 67.5 then direction = "N-EAST"; radIdx = "NE"
            elseif angle >= 67.5 and angle < 112.5 then direction = "EAST"; radIdx = "E"
            elseif angle >= 112.5 and angle < 157.5 then direction = "S-EAST"; radIdx = "SE"
            elseif angle >= 157.5 and angle < 202.5 then direction = "SOUTH"; radIdx = "S"
            elseif angle >= 202.5 and angle < 247.5 then direction = "S-WEST"; radIdx = "SW"
            elseif angle >= 247.5 and angle < 292.5 then direction = "WEST"; radIdx = "W"
            elseif angle >= 292.5 and angle < 337.5 then direction = "N-WEST"; radIdx = "NW"
            end
            
            -- Отрисовка текстового блока
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.lime)
            term.setCursorPos(2, 3)  term.write("X: " .. curX)
            term.setCursorPos(2, 4)  term.write("Z: " .. curZ)
            
            term.setTextColor(colors.gray)
            term.setCursorPos(2, 5)  term.write("Trgt X: " .. targetX)
            term.setCursorPos(2, 6)  term.write("Trgt Z: " .. targetZ)
            
            term.setCursorPos(1, 7)
            term.setTextColor(colors.lightGray)
            term.write("-----------------")
            
            if distance <= 2 then
                term.setBackgroundColor(colors.green)
                printCentered(9, " TARGET REACHED ", colors.white, colors.green)
                term.setBackgroundColor(colors.black)
                printCentered(10, "You are at destination", colors.lime, colors.black)
            else
                term.setTextColor(colors.white)
                term.setCursorPos(2, 8)
                term.write("DIST: ")
                term.setTextColor(colors.yellow)
                term.write(distance .. " blk")
                
                term.setTextColor(colors.white)
                term.setCursorPos(2, 9)
                term.write("HEADING: ")
                term.setTextColor(colors.cyan)
                term.write(direction)
                
                -- Отрисовка радара с жесткими индексами строк
                local w, h = term.getSize()
                local radarFrame = radars[radIdx]
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.red)
                
                term.setCursorPos(w - 3, h - 3) term.write(radarFrame[1])
                term.setCursorPos(w - 3, h - 2) term.write(radarFrame[2])
                term.setCursorPos(w - 3, h - 1) term.write(radarFrame[3])
            end
            
            printCentered(13, "[ Hold Ctrl+T to exit ]", colors.gray, colors.black)
        end
    end
end
