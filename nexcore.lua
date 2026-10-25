-- Launch with: nexcore/nexcore.lua (or nexcore.lua from this folder).
local root = fs.getDir(shell.getRunningProgram())
local originalPath = package.path
-- CC resolves relative package patterns from the program folder, not the shell.
-- Explicit leading slashes prevent the install folder being prepended twice.
package.path = "/" .. fs.combine(root,"src/?.lua"):gsub("^/+", "") .. ";/" .. fs.combine(root,"src/?/init.lua"):gsub("^/+", "") .. ";" .. package.path
local function run()
  local config = assert(loadfile(fs.combine(root,"config/default.lua")))()
  local localPath = fs.combine(root,"config/local.lua")
  if fs.exists(localPath) then
    local overrides = assert(loadfile(localPath))()
    assert(type(overrides) == "table", "config/local.lua must return a table")
    for k,v in pairs(overrides) do config[k] = v end
  end
  return require("nexcore.app").run(root,config)
end
-- Each launch gets fresh modules, including after editing code in the computer shell.
for name in pairs(package.loaded) do if name:match("^nexcore%.") then package.loaded[name] = nil end end
local ok, result = xpcall(run, function(e) return debug.traceback(tostring(e),2) end)
package.path = originalPath
if not ok then printError("NEXCORE startup/controller error (outputs preserved):\n" .. result) end
