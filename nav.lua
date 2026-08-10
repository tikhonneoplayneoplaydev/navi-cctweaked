--Advanced GPS Navigator for CC:Tweaked (Color Pocket Computer)
--Supports English interface and graphical arrows

local targetX, targetZ

-- Function to draw text center-aligned
local function printCentered(y, text, textColor, bgColor)
    local w, h = term.getSize()
    term.setCursorPos(math.floor((w - #text) / 2) + 1, y)
    if textColor then term.setTextColor(textColor) end
    if bgColor then term.setBackgroundColor(bgColor) end
    term.write(text)
end

-- Clear screen with background color
local function clearScreen(bgColor)
    term.setBackgroundColor(bgColor or colors.black)
    term.clear()
end

-- Beautiful Input Dialog
local function getTarget()
    clearScreen(colors.gray)
    
    -- Top Bar
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

-- Request targets
targetX, targetZ = getTarget()
if not targetX then return end

-- 8-Way detailed arrow textures for small pocket screens
local arrowText = {
    N  = " ^ ",
    NE = " / ",
    E  = " > ",
    SE = " \\ ",
    S  = " v ",
    SW = " / ",
    W  = " < ",
    NW = " \\ "
}

-- Main execution loop
while true do
    -- Draw clean dark background
    clearScreen(colors.black)
    
    -- Header
    term.setBackgroundColor(colors.blue)
    term.setCursorPos(1, 1)
    term.clearLine()
    printCentered(1, "GPS NAVIGATOR", colors.white, colors.blue)
    
    -- Get current GPS Location (timeout 2 seconds)
    local x, y, z = gps.locate(2)
    
    if not x then
        -- GPS Signal Lost UI
        term.setBackgroundColor(colors.black)
        printCentered(4, " NO SIGNAL! ", colors.white, colors.red)
        printCentered(6, "Check your", colors.lightGray, colors.black)
        printCentered(7, "GPS Hosts or", colors.lightGray, colors.black)
        printCentered(8, "wireless modem.", colors.lightGray, colors.black)
    else
        -- Math calculations
        local dx = targetX - x
        local dz = targetZ - z
        local distance = math.floor(math.sqrt(dx^2 + dz^2))
        
        local angle = math.atan2(dz, dx) * 180 / math.pi
        angle = (angle + 90) % 360
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
        
        -- Render coordinates block
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.gray)
        term.setCursorPos(2, 3)  term.write("My Pos: " .. math.floor(x) .. ", " .. math.floor(z))
        term.setCursorPos(2, 4)  term.write("Target: " .. targetX .. ", " .. targetZ)
        
        -- Render Navigation Info
        if distance <= 2 then
            printCentered(7, " ARRIVED! ", colors.white, colors.green)
            printCentered(8, "You are at target", colors.lightGray, colors.black)
        else
            -- Print distance and direction text
            term.setTextColor(colors.white)
            term.setCursorPos(2, 6)
            term.write("Dist: " .. distance .. " blocks")
            term.setCursorPos(2, 7)
            term.write("Turn: " .. direction)
            
            -- Graphical Arrow Display
            printCentered(9, arrow, colors.black, colors.yellow)
        end
    end
    
    -- Footer reminder
    printCentered(12, "Hold Ctrl+T to exit", colors.lightGray, colors.black)
    
    os.sleep(0.5) -- Fast responsive updates (twice per second)
end
