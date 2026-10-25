-- Deterministic CC event/peripheral simulation. No Minecraft physics is simulated.
local M = {}
local unpack = table.unpack or unpack
function M.setup(options)
  options = options or {}
  local mock = {time=0, events={}, calls={}, files={}, dirs={['']=true}, logs={},
    outputs={left=true,right=true}, powers={left=43,right=43}, reads=0, drawCalls=0}
  for side,power in pairs(options.powers or {}) do mock.powers[side]=power end
  local serial = 0
  function mock.event(time, ...)
    serial=serial+1
    mock.events[#mock.events+1]={time=time, order=serial, args={...}}
  end
  os.epoch = function() return math.floor(mock.time*1000+0.5) end
  local timerID=0
  os.startTimer=function(delay)
    timerID=timerID+1; mock.event(mock.time+delay,"timer",timerID); return timerID
  end
  os.pullEventRaw=function(filter) return coroutine.yield(filter) end
  os.pullEvent=function(filter)
    local event={os.pullEventRaw(filter)}
    if event[1]=="terminate" then error("Terminated",0) end
    return unpack(event)
  end
  sleep=function(seconds)
    local timer=os.startTimer(seconds)
    while true do local _, id=os.pullEvent("timer"); if id==timer then return end end
  end
  -- Broadcast every event to every matching worker, as CC parallel does.
  parallel={waitForAny=function(...)
    local threads, filters={},{}
    for i, fn in ipairs({...}) do threads[i]=coroutine.create(fn) end
    local event={}
    while true do
      for i, thread in ipairs(threads) do
        if not filters[i] or filters[i]==event[1] or event[1]=="terminate" then
          local ok, filter=coroutine.resume(thread,unpack(event))
          if not ok then error(filter,0) end
          filters[i]=filter
          if coroutine.status(thread)=="dead" then return i end
        end
      end
      table.sort(mock.events,function(a,b) return a.time==b.time and a.order<b.order or a.time<b.time end)
      local nextEvent=table.remove(mock.events,1)
      assert(nextEvent and nextEvent.time<30,"Mock timeout: workers did not exit")
      mock.time=nextEvent.time; event=nextEvent.args
    end
  end}
  if NEXCORE_TEST_PARALLEL then
    -- Load the unmodified official API into its own environment. Only CC's
    -- argument-check/error-wrapper dependencies are replaced, not scheduling.
    local env=setmetatable({dofile=function()
      return function(name)
        if name=="cc.expect" then return {expect=function(_,value,kind) assert(type(value)==kind) end} end
        return {try_barrier=function(_,fn) return fn() end,wrap_error=function(e) return e end}
      end
    end},{__index=_G})
    assert(loadfile(NEXCORE_TEST_PARALLEL,"t",env))()
    parallel={waitForAny=function(...)
      local args={...}
      local root=coroutine.create(function() return env.waitForAny(unpack(args)) end)
      local event={}
      while true do
        local ok,err=coroutine.resume(root,unpack(event))
        assert(ok,err)
        if coroutine.status(root)=="dead" then return err end
        table.sort(mock.events,function(a,b) return a.time==b.time and a.order<b.order or a.time<b.time end)
        local nextEvent=table.remove(mock.events,1)
        assert(nextEvent and nextEvent.time<30,"Official parallel test timeout")
        mock.time=nextEvent.time; event=nextEvent.args
      end
    end}
  end
  local methods={getScrollValue=true,setScrollValue=true,getHeight=true}
  local crashed=false
  peripheral={
    getNames=function() return {"left","right","back"} end,
    getType=function(side) return side=="back" and "altitude_sensor" or "hot_air_burner" end,
    getMethods=function(side)
      if options.crashScan and not crashed then crashed=true; error("INJECTED WORKER FAILURE") end
      return side=="back" and {"getHeight"} or {"getScrollValue","setScrollValue"}
    end,
    call=function(side, method, value)
      assert(methods[method],"Unexpected method: "..method)
      mock.calls[#mock.calls+1]={time=mock.time,side=side,method=method,value=value}
      if method=="getHeight" then
        mock.reads=mock.reads+1
        if options.sensorDelay then sleep(options.sensorDelay) end
        if options.sensorError and mock.reads<=options.sensorError then error("INJECTED SENSOR ERROR") end
        return options.constantAltitude or (170+mock.time/10)
      elseif method=="getScrollValue" then return mock.powers[side]
      else
        if options.failWriteSide==side then error("INJECTED WRITE FAILURE") end
        if options.setterDelay then sleep(options.setterDelay) end
        mock.powers[side]=value
      end
    end,
  }
  redstone={setOutput=function(side,on)
    mock.calls[#mock.calls+1]={time=mock.time,side=side,method="setOutput",value=on}
    mock.outputs[side]=on
  end}
  colors={black=1,white=2,gray=3,lightGray=4}
  keys={}; for i,name in ipairs({"q","x","t","g","h","m","d","equals","minus","numPadAdd","numPadSubtract","enter","numPadEnter","backspace","escape","f1"}) do keys[name]=i end
  term={getSize=function() return 51,19 end,setBackgroundColor=function() end,
    setTextColor=function() end,setCursorBlink=function() end,clear=function() end,
    setCursorPos=function() end,clearLine=function() end,
    write=function()
      mock.drawCalls=mock.drawCalls+1
      if options.crashUI and mock.drawCalls==25 then error("INJECTED UI FAILURE") end
    end}
  local function copy(value)
    if type(value)~="table" then return value end
    local result={}; for k,v in pairs(value) do result[k]=copy(v) end; return result
  end
  textutils={serializeJSON=function(value)
    mock.logs[#mock.logs+1]=copy(value)
    return "record:"..#mock.logs
  end}
  fs={}
  fs.combine=function(a,b) return (a=="" and b or a.."/"..b):gsub("/+","/") end
  fs.makeDir=function(path) mock.dirs[path]=true end
  fs.exists=function(path) return mock.files[path]~=nil or mock.dirs[path]~=nil end
  fs.getSize=function(path) return #(mock.files[path] or "") end
  fs.delete=function(path) mock.files[path]=nil; mock.dirs[path]=nil end
  fs.move=function(a,b)
    assert(not fs.exists(b),"Move destination exists")
    mock.files[b],mock.dirs[b]=mock.files[a],mock.dirs[a]
    mock.files[a],mock.dirs[a]=nil,nil
  end
  fs.open=function(path,mode)
    if options.logFailure then error("INJECTED DISK FULL") end
    if mode=="w" then mock.files[path]="" end
    mock.files[path]=mock.files[path] or ""
    return {writeLine=function(text) mock.files[path]=mock.files[path]..text.."\n" end,
      write=function(text) mock.files[path]=mock.files[path]..text end,close=function() end}
  end
  return mock
end
return M
