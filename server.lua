-- CC:Tweaked GPS Navigator: server.lua
-- Place a modem next to the computer (a wireless modem is recommended).
-- The server stores points in /navigator_points.db

local MODEM_SIDE = "back"
local CHANNEL = 45821
local PROTOCOL = "gps_navigator_v1"
local DB = "/navigator_points.db"

if not peripheral.isPresent(MODEM_SIDE) or peripheral.getType(MODEM_SIDE) ~= "modem" then
  error("Modem not found on side " .. MODEM_SIDE .. ". Change MODEM_SIDE in server.lua")
end

local modem = peripheral.wrap(MODEM_SIDE)
modem.open(CHANNEL)

local function loadPoints()
  if not fs.exists(DB) then return {} end
  local h = fs.open(DB, "r")
  local data = textutils.unserialize(h.readAll())
  h.close()
  return type(data) == "table" and data or {}
end

local function savePoints(points)
  local h = fs.open(DB, "w")
  h.write(textutils.serialize(points))
  h.close()
end

local points = loadPoints()

local function reply(id, data)
  modem.transmit(CHANNEL, CHANNEL, data)
end

local function validName(name)
  return type(name) == "string" and #name >= 1 and #name <= 32 and name:match("^[%w_%-%s]+$") ~= nil
end

local function handle(message)
  if type(message) ~= "table" or message.protocol ~= PROTOCOL then return end
  local action = message.action
  local result = { protocol = PROTOCOL, requestId = message.requestId, ok = true }

  if action == "list" then
    result.points = points
  elseif action == "get" then
    result.point = points[message.name]
    if not result.point then result.ok = false; result.error = "Point not found" end
  elseif action == "set" then
    local p = message.point
    if not validName(message.name) or type(p) ~= "table" or type(p.x) ~= "number" or type(p.y) ~= "number" or type(p.z) ~= "number" then
      result.ok = false; result.error = "Invalid name or coordinates"
    else
      points[message.name] = { x = math.floor(p.x), y = math.floor(p.y), z = math.floor(p.z) }
      savePoints(points)
      result.points = points
    end
  elseif action == "delete" then
    if points[message.name] then
      points[message.name] = nil; savePoints(points)
    else
      result.ok = false; result.error = "Point not found"
    end
  else
    result.ok = false; result.error = "Unknown command"
  end
  reply(message.sender, result)
end

print("GPS Navigator server started")
print("Channel: " .. CHANNEL)
while true do
  local event, side, channel, replyChannel, message = os.pullEvent("modem_message")
  if channel == CHANNEL and type(message) == "table" then
    handle(message)
  end
end
