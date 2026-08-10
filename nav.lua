-- Ultimate 100% Fixed GPS Navigator for CC:Tweaked
-- Matches internal 'gps locate' logic directly

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
    term.setBackgroundColor(colors.lightGray)
    term.clearLine()
    printCentered(1, " GPS TARGET SETUP ", colors.black, colors.lightGray)
    
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
        os.sleep(2)
        return nil, nil
    end
    return tx, tz
end

targetX, targetZ = getTarget()
if not targetX then return end

-- Detailed 8-Way arrows
local arrowText = {
    N  = " ^ ", NE = " / ", E  = " > ", SE = " \\ ",
    S  = " v ", SW = " / ", W  = " < ", NW = " \\ "
}

while true do
    clearScreen(colors.black)
    
    term.setBackgroundColor(colors.blue)
    term.setCursorPos(1, 1)
    term.clearLine()
    printCentered(1, "GPS NAVIGATOR", colors.white, colors.blue)
    
    -- Прямой запрос к API без промежуточных переменных
    local pos = { gps.locate(2) }
    
    if #pos == 0 or not pos[1] then
        term.setBackgroundColor(colors.black)
        printCentered(4, " NO SIGNAL! ", colors.white, colors.red)
        printCentered(6, "Check your", colors.lightGray, colors.black)
        printCentered(7, "GPS Hosts or", colors.lightGray, colors.black)
        printCentered(8, "wireless modem.", colors.lightGray, colors.black)
    else
        -- Строгая привязка индексов к осям (1 - X, 3 - Z)
        local curX = math.floor(pos[1])
        local curZ = math.floor(pos[3])
        
        -- Расчёт вектора
        local dx = targetX - curX
        local dz = targetZ - curZ
        local distance = math.floor(math.sqrt(dx^2 + dz^2))
        
        -- Вычисление точного угла
        local angle = math.atan2(dx, -dz) * 180 / math.pi
        if angle < 0 then angle = angle + 360 end

        local direction = ""
        local arrow = "?"
        
        if angle >= 337.5 or angle < 22.5 then direction = "NORTH (-Z)"; arrow = arrowText.N
        elseif angle >= 22.5 and angle < 67.5 then direction = "N-EAST"; arrow = arrowText.NE
        elseif angle >= 67.5 and angle < 112.5 then direction = "EAST (+X)"; arrow = arrowText.E
        elseif angle >= 112.5 and angle < 157.5 then direction = "S-EAST"; arrow = arrowText.SE
        elseif angle >= 157.5 and angle < 202.5 then direction = "SOUTH (+Z)"; arrow = arrowText.S
        elseif angle >= 202.5 and angle < 247.5 then direction = "S-WEST"; arrow = arrowText.SW
        elseif angle >= 247.5 and angle < 292.5 then direction = "WEST (-X)"; arrow = arrowText.W
        elseif angle >= 292.5 and angle < 337.5 then direction = "N-WEST"; arrow = arrowText.NW
        end
        
        -- Отрисовка интерфейса
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.gray)
        term.setCursorPos(2, 3)  term.write("My Pos: " .. curX .. ", " .. curZ)
        term.setCursorPos(2, 4)  term.write("Target: " .. targetX .. ", " .. targetZ)
        
        if distance <= 2 then
            printCentered(7, " ARRIVED! ", colors.white, colors.green)
            printCentered(8, "You are at target", colors.lightGray, colors.black)
        else
            term.setTextColor(colors.white)
            term.setCursorPos(2, 6)
            term.write("Dist: " .. distance .. " blocks")
            term.setCursorPos(2, 7)
            term.write("Turn: " .. direction)
            
            printCentered(9, arrow, colors.black, colors.yellow)
        end
    end
    
    printCentered(12, "Hold Ctrl+T to exit", colors.lightGray, colors.black)
end
