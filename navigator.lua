-- CC:Tweaked GPS Navigator: navigator.lua
-- Нужен wireless modem на любой стороне компьютера.

local MODEM_SIDE = "back"
local CHANNEL = 45821
local PROTOCOL = "gps_navigator_v1"
local TIMEOUT = 3

if not peripheral.isPresent(MODEM_SIDE) or peripheral.getType(MODEM_SIDE) ~= "modem" then
  error("Модем не найден на стороне " .. MODEM_SIDE .. ". Измени MODEM_SIDE в navigator.lua")
end
local modem = peripheral.wrap(MODEM_SIDE)
modem.open(CHANNEL)

local function request(action, extra)
  local id = tostring(os.epoch("utc")) .. tostring(math.random(1000, 9999))
  local msg = { protocol = PROTOCOL, action = action, requestId = id, sender = os.getComputerID() }
  if extra then for k, v in pairs(extra) do msg[k] = v end end
  modem.transmit(CHANNEL, CHANNEL, msg)
  local timer = os.startTimer(TIMEOUT)
  while true do
    local e, p1, _, _, data = os.pullEvent()
    if e == "modem_message" and type(data) == "table" and data.protocol == PROTOCOL and data.requestId == id then return data end
    if e == "timer" and p1 == timer then return nil, "Сервер не отвечает" end
  end
end

local function locate()
  local x, y, z = gps.locate(5)
  if not x then return nil, "GPS не найден: проверь GPS-маяки" end
  return { x = x, y = y, z = z }
end

local function distance(a, b)
  return math.floor(math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2) + 0.5)
end

local function direction(a, b)
  local dx, dz = b.x-a.x, b.z-a.z
  if math.abs(dx) > math.abs(dz) then return dx > 0 and "восток (+X)" or "запад (-X)" end
  return dz > 0 and "юг (+Z)" or "север (-Z)"
end

local function showPoints()
  local r, err = request("list")
  if not r then printError(err); return end
  print("Точки:")
  local count = 0
  for name, p in pairs(r.points or {}) do
    print("- " .. name .. ": " .. p.x .. ", " .. p.y .. ", " .. p.z)
    count = count + 1
  end
  if count == 0 then print("(пусто)") end
end

local function addPoint()
  local p, err = locate()
  if not p then printError(err); return end
  write("Название точки: "); local name = read()
  local r, e = request("set", { name = name, point = p })
  if r and r.ok then print("Сохранено: " .. name .. " (" .. p.x .. ", " .. p.y .. ", " .. p.z .. ")") else printError((r and r.error) or e) end
end

local function goTo()
  write("Название точки: "); local name = read()
  local r, err = request("get", { name = name })
  if not r or not r.ok then printError((r and r.error) or err); return end
  while true do
    local p, e = locate()
    if not p then printError(e); return end
    local target = r.point
    print("До " .. name .. ": " .. distance(p, target) .. " блоков, направление: " .. direction(p, target))
    print("Текущие координаты: " .. p.x .. ", " .. p.y .. ", " .. p.z)
    print("Нажми любую клавишу для обновления, Q для выхода")
    local _, key = os.pullEvent("key")
    if key == keys.q then return end
    term.clear(); term.setCursorPos(1, 1)
  end
end

while true do
  print("\n=== GPS NAVIGATOR ===")
  print("1 — показать точки")
  print("2 — сохранить текущую точку")
  print("3 — навигация к точке")
  print("4 — удалить точку")
  print("5 — мои координаты")
  print("Q — выход")
  write("> "); local c = read():lower()
  if c == "1" then showPoints()
  elseif c == "2" then addPoint()
  elseif c == "3" then goTo()
  elseif c == "4" then
    write("Название: "); local n = read(); local r, e = request("delete", {name=n}); print((r and r.ok and "Удалено" or ((r and r.error) or e)))
  elseif c == "5" then local p,e=locate(); if p then print(p.x..", "..p.y..", "..p.z) else printError(e) end
  elseif c == "q" then break end
end
