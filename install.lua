-- CC:Tweaked GPS-only Navigator installer
-- Run this file in CC:Tweaked with: install

local BASE = "https://raw.githubusercontent.com/tikhonneoplayneoplaydev/navigator-cc/refs/heads/main/"
local files = {
  { url = "navigator.lua", name = "navigator.lua", required = true },
  { url = "nav.lua",       name = "nav.lua",       required = false },
}

if not http then
  error("HTTP API is disabled. Enable HTTP in the CC:Tweaked settings.")
end

local function download(file)
  write("Downloading " .. file.url .. "... ")
  local response, err = http.get(BASE .. file.url)
  if not response then print("error: " .. tostring(err)); return false end
  local code = response.getResponseCode and response.getResponseCode() or 200
  local body = response.readAll(); response.close()
  if code < 200 or code >= 300 then print("not found (HTTP " .. code .. ")"); return false end
  local handle = fs.open(file.name, "w"); handle.write(body); handle.close()
  print("OK"); return true
end

term.clear(); term.setCursorPos(1, 1)
print("=== GPS NAVIGATOR INSTALLER ===")
print("Source: GitHub\n")
local failed = false
for _, file in ipairs(files) do
  if not download(file) and file.required then failed = true end
end
if failed then error("Installation failed: a required file could not be downloaded") end
print("\nInstallation complete!")
print("Run: navigator")
