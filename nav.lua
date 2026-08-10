-- Очистка экрана и настройка
term.clear()
term.setCursorPos(1,1)

-- Функция для запроса координат цели
local function getTarget()
    print("=== GPS НАВИГАТОР ===")
    io.write("Введите X цели: ")
    local tx = tonumber(io.read())
    io.write("Введите Z цели: ")
    local tz = tonumber(io.read())
    if not tx or not tz then
        print("Ошибка: вводите только числа!")
        os.sleep(2)
        return nil, nil
    end
    return tx, tz
end

local targetX, targetZ = getTarget()
if not targetX then return end

-- Таблица символов-стрелок для 8 направлений
local arrows = {
    N  = "^",  -- Север (-Z)
    NE = "/",  -- Северо-Восток
    E  = ">",  -- Восток (+X)
    SE = "\\", -- Юго-Восток
    S  = "v",  -- Юг (+Z)
    SW = "/",  -- Юго-Запад
    W  = "<",  -- Запад (-X)
    NW = "\\"  -- Северо-Запад
}

-- Главный цикл обновления данных
while true do
    term.clear()
    term.setCursorPos(1,1)
    
    -- Получаем текущие координаты через GPS-хосты
    local x, y, z = gps.locate(2)
    
    if not x then
        term.setTextColor(colors.red)
        print("Ошибка: Нет сигнала GPS!")
        print("Проверьте модем или хосты.")
        term.setTextColor(colors.white)
    else
        -- Считаем разницу координат и расстояние
        local dx = targetX - x
        local dz = targetZ - z
        local distance = math.floor(math.sqrt(dx^2 + dz^2))
        
        -- Считаем угол в радианах и переводим в градусы
        local angle = math.atan2(dz, dx) * 180 / math.pi
        -- Корректируем угол, чтобы 0 градусов был строго на Севере (-Z в Minecraft)
        angle = (angle + 90) % 360
        if angle < 0 then angle = angle + 360 end

        -- Определяем сторону света и стрелку
        local direction = ""
        local arrow = "?"
        
        if angle >= 337.5 or angle < 22.5 then direction = "Север (-Z)"; arrow = arrows.N
        elseif angle >= 22.5 and angle < 67.5 then direction = "Сев-Восток"; arrow = arrows.NE
        elseif angle >= 67.5 and angle < 112.5 then direction = "Восток (+X)"; arrow = arrows.E
        elseif angle >= 112.5 and angle < 157.5 then direction = "Юго-Восток"; arrow = arrows.SE
        elseif angle >= 157.5 and angle < 202.5 then direction = "Юг (+Z)"; arrow = arrows.S
        elseif angle >= 202.5 and angle < 247.5 then direction = "Юго-Запад"; arrow = arrows.SW
        elseif angle >= 247.5 and angle < 292.5 then direction = "Запад (-X)"; arrow = arrows.W
        elseif angle >= 292.5 and angle < 337.5 then direction = "Сев-Запад"; arrow = arrows.NW
        end

        -- Вывод интерфейса на экран планшета
        print("=== НАВИГАЦИЯ ===")
        print("Вы тут: " .. math.floor(x) .. ", " .. math.floor(z))
        print("Цель  : " .. targetX .. ", " .. targetZ)
        print("-----------------")
        
        if distance <= 2 then
            term.setTextColor(colors.green)
            print(" Вы на месте! ")
            term.setTextColor(colors.white)
        else
            print("Дистанция: " .. distance .. " бл.")
            print("Идти на  : " .. direction)
            print("")
            -- Рисуем большую стрелку по центру
            local w, h = term.getSize()
            term.setCursorPos(math.floor(w/2), h - 1)
            term.setTextColor(colors.yellow)
            print(arrow)
            term.setTextColor(colors.white)
        end
    end
    
    print("\n[Для выхода зажмите Ctrl+T]")
    os.sleep(1) -- Обновление каждую секунду
end
