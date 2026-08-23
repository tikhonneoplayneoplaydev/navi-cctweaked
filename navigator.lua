-- CC:Tweaked GPS Navigator
-- This program uses only gps.locate(). No server or modem is required.

local DB = "/navigator_points.db"

local function loadPoints()
  if not fs.exists(DB) then return {} end
  local file = fs.open(DB, "r")
  local data = textutils.unserialize(file.readAll())
  file.close()
  return type(data) == "table" and data or {}
end

local function savePoints(points)
  local file = fs.open(DB, "w")
  file.write(textutils.serialize(points))
  file.close()
end

local points = loadPoints()

local function locate()
  local x, y, z = gps.locate(5)
  if not x then return nil, "GPS signal not found. Check your GPS satellites." end
  return { x = math.floor(x), y = math.floor(y), z = math.floor(z) }
end

local function distance(a, b)
  return math.floor(math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2) + 0.5)
end

local function direction(a, b)
  local dx, dz = b.x-a.x, b.z-a.z
  if math.abs(dx) > math.abs(dz) then return dx > 0 and "east (+X)" or "west (-X)" end
  if dz == 0 then return "here" end
  return dz > 0 and "south (+Z)" or "north (-Z)"
end

local function showPoints()
  print("Saved points:")
  local count = 0
  for name, p in pairs(points) do
    print("- " .. name .. ": " .. p.x .. ", " .. p.y .. ", " .. p.z)
    count = count + 1
  end
  if count == 0 then print("(none)") end
end

local function addPoint()
  local p, err = locate()
  if not p then printError(err); return end
  write("Point name: "); local name = read()
  if name == "" or #name > 32 then printError("Name must be 1-32 characters."); return end
  points[name] = p
  savePoints(points)
  print("Saved " .. name .. " at " .. p.x .. ", " .. p.y .. ", " .. p.z)
end

local function goTo()
  write("Point name: "); local name = read()
  local target = points[name]
  if not target then printError("Point not found."); return end
  while true do
    local p, err = locate()
    if not p then printError(err); return end
    term.clear(); term.setCursorPos(1, 1)
    print("=== GPS NAVIGATION ===")
    print("Target: " .. name .. " (" .. target.x .. ", " .. target.y .. ", " .. target.z .. ")")
    print("Current: " .. p.x .. ", " .. p.y .. ", " .. p.z)
    print("Distance: " .. distance(p, target) .. " blocks")
    print("Direction: " .. direction(p, target))
    if distance(p, target) == 0 then print("You have reached the target!") end
    print("Press any key to update, Q to exit.")
    local _, key = os.pullEvent("key")
    if key == keys.q then return end
  end
end

local function findModem()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then return side end
  end
  return nil
end

local function configureHost()
  local side = findModem()
  if not side then printError("No modem found. A wireless modem is required."); return end
  print("\n=== GPS HOST SETUP ===")
  print("1 - Detect coordinates using GPS")
  print("2 - Enter coordinates manually")
  write("> "); local mode = read()
  local x, y, z
  if mode == "1" then
    x, y, z = gps.locate(5)
    if not x then printError("Could not detect coordinates. Enter them manually or check GPS coverage."); return end
  elseif mode == "2" then
    write("Host X: "); x = tonumber(read())
    write("Host Y: "); y = tonumber(read())
    write("Host Z: "); z = tonumber(read())
    if not x or not y or not z then printError("Coordinates must be numbers."); return end
  else return end
  x, y, z = math.floor(x), math.floor(y), math.floor(z)

  local file = fs.open("startup.lua", "w")
  file.write("local modem = " .. textutils.serialize(side) .. "\n")
  file.write("if peripheral.getType(modem) ~= 'modem' then error('Wireless modem not found on ' .. modem) end\n")
  file.write("rednet.open(modem)\n")
  file.write("shell.run('gps', 'host', " .. x .. ", " .. y .. ", " .. z .. ")\n")
  file.close()
  print("Startup configured at " .. x .. ", " .. y .. ", " .. z .. ".")
  print("rednet.open and gps host will run automatically after reboot.")
  print("Starting GPS host now...")
  rednet.open(side)
  shell.run("gps", "host", x, y, z)
end

while true do
  print("\n=== GPS NAVIGATOR ===")
  print("1 - Show saved points")
  print("2 - Save current GPS position")
  print("3 - Navigate to a point")
  print("4 - Delete a point")
  print("5 - Show current GPS coordinates")
  print("6 - Configure GPS host startup")
  print("Q - Exit")
  write("> "); local choice = read():lower()
  if choice == "1" then showPoints()
  elseif choice == "2" then addPoint()
  elseif choice == "3" then goTo()
  elseif choice == "4" then
    write("Point name: "); local name = read()
    if points[name] then points[name] = nil; savePoints(points); print("Deleted.") else printError("Point not found.") end
  elseif choice == "5" then
    local p, err = locate(); if p then print(p.x .. ", " .. p.y .. ", " .. p.z) else printError(err) end
  elseif choice == "6" then configureHost()
  elseif choice == "q" then break end
end
