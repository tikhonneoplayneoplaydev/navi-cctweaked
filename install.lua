-- CC:Tweaked Navigator installer
-- Помести этот файл в GitHub как install.lua
-- Запуск в CC:Tweaked: install

local BASE = "https://raw.githubusercontent.com/tikhonneoplayneoplaydev/navigator-cc/refs/heads/main/"
local files = {
  { url = "nav.lua",      name = "nav.lua",      required = true },
  { url = "server.lua",   name = "server.lua",   required = false },
  { url = "config.lua",   name = "config.lua",   required = false },
}

if not http then
  error("HTTP API отключён. Включи HTTP в настройках CC:Tweaked.")
end

local function download(file)
  write("Скачивание " .. file.url .. "... ")
  local response, err = http.get(BASE .. file.url)
  if not response then
    print("ошибка: " .. tostring(err))
    return false
  end
  local code = response.getResponseCode and response.getResponseCode() or 200
  local body = response.readAll()
  response.close()
  if code < 200 or code >= 300 then
    print("не найдено (HTTP " .. code .. ")")
    return false
  end
  local handle = fs.open(file.name, "w")
  handle.write(body)
  handle.close()
  print("OK")
  return true
end

term.clear()
term.setCursorPos(1, 1)
print("=== NAVIGATOR INSTALLER ===")
print("Источник: GitHub")
print("")

local failed = false
for _, file in ipairs(files) do
  local ok = download(file)
  if not ok and file.required then failed = true end
end

if failed then
  error("Установка не завершена: обязательный файл не скачан")
end

print("")
print("Установка завершена!")
print("Запуск: nav")
if fs.exists("server.lua") then print("Сервер точек: server") end
