local u, cal = require("nexcore.util"), require("nexcore.calibration")
local M = {}
function M.new(c, s, log)
  local control = {}
  function control.request(power)
    if not s.ready or s.busy or s.pending then s.status = "BURNER BUSY/UNAVAILABLE"; return false end
    power = u.clamp(math.floor(power+0.5), c.minPower, c.maxPower)
    s.pending = {power=power}
    log.event("power_requested", power)
    return true
  end
  function control.key(key)
    -- These two bindings always work, including while entering a target.
    if key == keys.q then s.exit = "hands_off"; return end
    if key == keys.x then s.exit = "off"; return end
    if s.editing then
      if key == keys.enter or key == keys.numPadEnter then
        local value = tonumber(s.input)
        if u.finite(value) then s.target = value; s.status = "TARGET SET"
        else s.status = "INVALID TARGET" end
        s.editing = false
      elseif key == keys.backspace then s.input = s.input:sub(1,-2)
      elseif key == keys.escape then s.editing = false; s.status = "TARGET CANCELLED" end
      return
    end
    if key == keys.t then s.input = ""; s.editing = true
    elseif key == keys.m then s.mode = "MANUAL"; s.status = "MANUAL CONTROL"
    elseif key == keys.h then s.mode = "HOLD"; s.status = "HOLDING POWER"
    elseif key == keys.d then s.scan = true; log.event("scan_requested", "Read only; no scroll writes")
    elseif key == keys.g then
      if not s.target then s.status = "SET TARGET FIRST"
      elseif not s.sampleAt or u.age(s.sampleAt) > c.staleMs then s.status = "GO BLOCKED: SENSOR STALE"
      elseif control.request(cal.power(c, s.target)) then s.mode = "GO"; s.status = "GO POWER QUEUED" end
    elseif s.mode == "MANUAL" and s.power then
      if key == keys.equals or key == keys.numPadAdd then control.request(s.power+1)
      elseif key == keys.minus or key == keys.numPadSubtract then control.request(s.power-1) end
    end
  end
  function control.text(value)
    if s.editing then s.input = (s.input .. value:gsub("[^%d%.%-]", "")):sub(1,24) end
  end
  function control.update()
    if s.mode == "GO" and not s.busy and not s.pending and s.target and s.altitude
      and u.age(s.sampleAt) <= c.staleMs
      and math.abs(s.target-s.altitude) <= c.targetTolerance and math.abs(s.velocity) < 0.05 then
      s.mode, s.status = "HOLD", "TARGET REGION REACHED"
      log.event("arrival", s.altitude)
    end
  end
  return control
end
return M
