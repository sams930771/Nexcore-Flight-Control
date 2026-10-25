local u = require("nexcore.util")
local M = {}
function M.run(root, c)
  require("nexcore.calibration").validate(c)
  local s = {mode="MANUAL", velocity=0, loops=0, attempts=0, samples=0, failures=0, changes=0,
    observed={}, heartbeats={}, workerErrors={}, sensorStage="STARTING", burnerStage="STARTING",
    status="INITIALIZING", lastError="NONE", scan=false, busy=false, ready=false}
  local log = require("nexcore.log").new(root,c,s)
  local hw = require("nexcore.hardware").new(c,s,log)
  local control = require("nexcore.control").new(c,s,log)
  local display = require("nexcore.display")
  local supervise = require("nexcore.supervisor").worker
  log.event("session_start", c.version)
  local function ui()
    local timer = os.startTimer(c.tickSeconds)
    display.draw(c,s)
    while not s.exit do
      -- Unfiltered raw events; other workers receive their own event copy through parallel.
      local event, value, held = os.pullEventRaw()
      if event == "terminate" then s.exit = "hands_off"
      elseif event == "key" and not held then control.key(value)
      elseif event == "char" or event == "paste" then control.text(value)
      elseif event == "peripheral" or event == "peripheral_detach" then s.scan = true
      elseif event == "timer" and value == timer then
        timer = os.startTimer(c.tickSeconds)
        s.loops = s.loops+1
        s.heartbeats.ui = u.now()
        control.update()
      end
      -- Avoid redraws for unrelated peripheral task-completion events.
      if event == "timer" or event == "key" or event == "char" or event == "paste" or event == "term_resize" then
        display.draw(c,s)
      end
    end
  end
  local function telemetry()
    while not s.exit do
      s.heartbeats.telemetry = u.now()
      log.sample()
      sleep(1)
    end
  end
  local ok, err = xpcall(function()
    parallel.waitForAny(
      supervise("ui",ui,s,log),
      supervise("sensor",hw.sensorWorker,s,log),
      supervise("burner",hw.burnerWorker,s,log),
      supervise("telemetry",telemetry,s,log))
  end,u.trace)
  -- A framework-level failure is visible and preserves outputs. No automatic zeroing.
  if not ok then s.exit = s.exit or "error"; s.lastError = tostring(err) end
  if s.exit == "off" then
    local offOK, offError = hw.off()
    s.offOK = offOK
    if not offOK then s.lastError = offError end
  end
  log.event("session_exit", tostring(s.exit) .. " " .. s.lastError)
  term.setCursorBlink(false); term.setBackgroundColor(colors.black); term.setTextColor(colors.white)
  term.clear(); term.setCursorPos(1,1)
  print("NEXCORE FLIGHT CONTROL OFFLINE")
  if s.exit == "off" then
    print(s.offOK and "Burner redstone outputs OFF; scroll values retained." or "OFF FAILED: " .. s.lastError)
  else print("Hands off: burner outputs and scroll values retained.") end
  print("Last mode: " .. s.mode .. " / power: " .. tostring(s.power))
  if not ok then print("CONTROLLER ERROR: " .. s.lastError) end
  return s
end
return M
