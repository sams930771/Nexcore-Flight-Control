-- Reproduce CC's program-relative package lookup (desktop Lua differs here).
for _,program in ipairs({"nexcore-ready/nexcore.lua", "ships/control/nexcore.lua", "nexcore.lua"}) do
  local folder=program:match("^(.*)/[^/]*$") or ""
  local packageMock={path="?.lua",loaded={}}
  local invoked=false
  local fsMock={getDir=function() return folder end,
    combine=function(a,b) return ((a=="" and b or a.."/"..b):gsub("^/+", ""):gsub("/+", "/")) end,
    exists=function() return false end}
  local env=setmetatable({fs=fsMock,package=packageMock,
    shell={getRunningProgram=function() return program end},
    loadfile=function(path)
      assert(path==fsMock.combine(folder,"config/default.lua"),path)
      return function() return {version="3.5.3"} end
    end,
    printError=function(e) error(e) end,
    require=function(name)
      assert(name=="nexcore.app")
      local pattern=packageMock.path:match("^[^;]+")
      local path=pattern:gsub("%?",name:gsub("%.","/"))
      if path:sub(1,1)~="/" then path=fsMock.combine(folder,path) end
      assert(path=="/"..fsMock.combine(folder,"src/nexcore/app.lua"),"Wrong CC module path: "..path)
      return {run=function(root,c) assert(root==folder and c.version=="3.5.3"); invoked=true end}
    end}, {__index=_G})
  assert(loadfile("nexcore.lua","t",env))()
  assert(invoked and packageMock.path=="?.lua")
  print("PASS launcher program-relative lookup: "..program)
end
