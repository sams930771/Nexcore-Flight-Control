-- wget bootstrap. Downloads only; never starts the flight controller or changes outputs.
local owner, repo, ref, destination = ...
ref, destination = ref or "main", destination or "nexcore"
assert(owner and repo, "Usage: install OWNER REPO [REF] [DESTINATION]")
assert(owner:match("^[%w_-]+$") and repo:match("^[%w_.-]+$"), "Invalid GitHub owner/repository")
assert(ref:match("^[%w_./-]+$") and not ref:find("..",1,true), "Invalid Git ref")
destination = fs.combine("", destination)
assert(destination ~= "" and destination ~= "/" and destination ~= "rom" and not destination:match("^rom/"), "Choose a dedicated install folder")
local stage, backup = destination .. ".stage", destination .. ".backup"
assert(not fs.exists(stage), "Staging folder exists: " .. stage .. ". Inspect/remove it before retrying.")
assert(not fs.exists(backup), "Backup exists: " .. backup .. ". Archive/rename it before updating.")
if fs.exists(destination) then
  assert(fs.exists(fs.combine(destination,"nexcore.lua")) and fs.exists(fs.combine(destination,"config/default.lua")), "Destination is not a NEXCORE installation")
end
local base = "https://raw.githubusercontent.com/" .. owner .. "/" .. repo .. "/" .. ref .. "/"
local function download(path)
  local response, err = http.get(base .. path)
  assert(response, "Download failed: " .. path .. ": " .. tostring(err))
  local ok, data = pcall(response.readAll)
  response.close()
  assert(ok and data, "Read failed: " .. path)
  return data
end
local manifest = textutils.unserializeJSON(download("manifest.json"))
assert(type(manifest) == "table" and manifest.version == "3.5.2" and type(manifest.files) == "table", "Invalid/version-mismatched manifest")
fs.makeDir(stage)
for _, entry in ipairs(manifest.files) do
  local path = entry.path
  assert(type(path) == "string" and path:match("^[%w_./-]+$") and not path:find("..",1,true) and not path:match("^/"), "Unsafe manifest path")
  assert(path ~= "config/local.lua" and not path:match("^logs/"), "Manifest cannot replace user data")
  local data = download(path)
  assert(#data == entry.bytes, "Size mismatch: " .. path)
  local target = fs.combine(stage,path)
  fs.makeDir(fs.getDir(target))
  local file = assert(fs.open(target,"w")); file.write(data); file.close()
  if path:match("%.lua$") then assert(loadfile(target)) end
  print("Downloaded " .. path)
end
assert(fs.exists(fs.combine(stage,"nexcore.lua")) and fs.exists(fs.combine(stage,"config/default.lua")), "Incomplete install")
if fs.exists(destination) then
  for _, path in ipairs({"config/local.lua", "logs"}) do
    local source = fs.combine(destination,path)
    if fs.exists(source) then
      local target = fs.combine(stage,path)
      fs.makeDir(fs.getDir(target)); fs.copy(source,target)
    end
  end
  fs.move(destination,backup)
end
local ok, err = pcall(fs.move, stage, destination)
if not ok then
  if fs.exists(backup) and not fs.exists(destination) then fs.move(backup,destination) end
  error("Install failed; previous installation restored if available: " .. tostring(err))
end
print("Installed NEXCORE 3.5.2. Run: " .. fs.combine(destination,"nexcore.lua"))
print("No burner outputs changed. Existing installation, if any, is in " .. backup)
