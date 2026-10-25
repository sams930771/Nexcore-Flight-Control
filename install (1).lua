-- Installer staging/update/rollback tests, independent of HTTP and the real disk.
local function scenario(kind)
  local files, dirs={}, {['']=true}
  local payload='return {}\n'
  if kind~="fresh" then
    dirs.nexcore=true; dirs['nexcore/config']=true; dirs['nexcore/logs']=true
    files['nexcore/nexcore.lua']='old controller'
    files['nexcore/config/default.lua']='old defaults'
    files['nexcore/config/local.lua']='local calibration override'
    files['nexcore/logs/events.jsonl']='existing telemetry'
  end
  local function contains(path,root) return path==root or path:sub(1,#root+1)==root..'/' end
  local fs={}
  fs.combine=function(a,b)
    return ((a=='' and b or a..'/'..b):gsub('/+','/'))
  end
  fs.getDir=function(p) return p:match('^(.*)/[^/]*$') or '' end
  fs.exists=function(p) return files[p]~=nil or dirs[p]~=nil end
  fs.makeDir=function(p) dirs[p]=true end
  local function transfer(a,b,move)
    if kind=="rollback" and a=="nexcore.stage" and b=="nexcore" then error("injected final move failure") end
    assert(not fs.exists(b),"destination exists")
    for _,storage in ipairs({files,dirs}) do
      local entries={}
      for path,v in pairs(storage) do if contains(path,a) then entries[path]=v end end
      for path,v in pairs(entries) do storage[b..path:sub(#a+1)]=v; if move then storage[path]=nil end end
    end
  end
  fs.move=function(a,b) transfer(a,b,true) end
  fs.copy=function(a,b) transfer(a,b,false) end
  fs.open=function(path)
    files[path]=''
    return {write=function(data) files[path]=files[path]..data end,close=function() end}
  end
  local manifest={version="3.5.2",files={{path="nexcore.lua",bytes=#payload},{path="config/default.lua",bytes=#payload}}}
  if kind=="badsize" then manifest.files[2].bytes=99 end
  if kind=="traversal" then manifest.files[1].path="../escape.lua" end
  local fakeHTTP={get=function(url)
    if kind=="download" and url:match('default.lua$') then return nil,"injected network failure" end
    return {readAll=function() return url:match('manifest.json$') and 'manifest' or payload end,close=function() end}
  end}
  local env=setmetatable({fs=fs,http=fakeHTTP,print=function() end,
    textutils={unserializeJSON=function() return manifest end},
    loadfile=function(path)
      if files[path] then return load(files[path],path) end
      return nil,"missing mock file"
    end}, {__index=_G})
  local installer=assert(loadfile('install.lua','t',env))
  local ok=pcall(installer,"OWNER","REPO","main","nexcore")
  if kind=="fresh" or kind=="update" then
    assert(ok and files['nexcore/nexcore.lua']==payload)
    if kind=="update" then
      assert(files['nexcore/config/local.lua']=='local calibration override')
      assert(files['nexcore/logs/events.jsonl']=='existing telemetry')
      assert(files['nexcore.backup/nexcore.lua']=='old controller')
    end
  else
    assert(not ok and files['nexcore/nexcore.lua']=='old controller')
    assert(files['nexcore/logs/events.jsonl']=='existing telemetry')
  end
end
for _,kind in ipairs({'fresh','update','badsize','download','traversal','rollback'}) do
  scenario(kind); print('PASS installer '..kind)
end
