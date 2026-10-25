-- Read-only peripheral inventory: does not invoke getters or setters.
local root = fs.getDir(shell.getRunningProgram())
local report = {time=os.epoch("utc"), peripherals={}}
for _, name in ipairs(peripheral.getNames()) do
  report.peripherals[#report.peripherals+1] = {name=name, type=peripheral.getType(name), methods=peripheral.getMethods(name)}
end
fs.makeDir(fs.combine(root,"logs"))
local file = assert(fs.open(fs.combine(root,"logs/inventory.json"),"w"))
file.write(textutils.serializeJSON(report)); file.close()
print("Inventory written to " .. fs.combine(root,"logs/inventory.json"))
for _, device in ipairs(report.peripherals) do print(device.name .. ": " .. table.concat(device.methods or {}, ", ")) end
