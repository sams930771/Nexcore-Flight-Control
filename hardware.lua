local u = require("nexcore.util")
local M = {}
function M.new(c, s, log)
  local hw = {}
  local function call(side, method, ...)
    log.event("call_begin", side .. "." .. method)
    local started = u.now()
    local result = {pcall(peripheral.call, side, method, ...)}
    log.event("call_end", side .. "." .. method .. " ms=" .. (u.now()-started) .. " ok=" .. tostring(result[1]))
    return result[1], result[2]
  end
  local function supports(side, method)
    local methods = peripheral.getMethods(side) or {}
    for _, name in ipairs(methods) do if name == method then return true end end
    return false
  end
  function hw.scan()
    s.ready = false
    for _, side in ipairs(c.burnerSides) do
      assert(supports(side, c.readPowerMethod) and supports(side, c.writePowerMethod), "Missing burner methods on " .. side)
      s.burnerStage = "READ " .. side
      local ok, power = call(side, c.readPowerMethod)
      assert(ok and u.finite(power) and power >= c.minPower and power <= c.maxPower, "Invalid power read on " .. side .. ": " .. tostring(power))
      s.observed[side] = power
    end
    s.power = s.observed[c.burnerSides[1]]
    s.mismatch = s.power ~= s.observed[c.burnerSides[2]]
    s.ready = true
    s.burnerStage = "IDLE"
    s.status = s.mismatch and "POWER MISMATCH: manual +/- synchronizes" or "SYSTEM ONLINE"
  end
  function hw.enable()
    -- Preserve v3.5.1 activation policy, without setting either scroll value.
    for _, side in ipairs(c.burnerSides) do redstone.setOutput(side, true) end
    log.event("burners_enabled", "Existing scroll values retained")
  end
  function hw.off()
    local failures = {}
    for _, side in ipairs(c.burnerSides) do
      local ok, err = pcall(redstone.setOutput, side, false)
      if not ok then failures[#failures+1] = side .. ": " .. tostring(err) end
    end
    return #failures == 0, table.concat(failures, "; ")
  end
  function hw.apply(power)
    s.ready = false
    for _, side in ipairs(c.burnerSides) do
      s.burnerStage = "WRITE " .. side
      local ok, err = call(side, c.writePowerMethod, power)
      assert(ok, "Write failed on " .. side .. ": " .. tostring(err))
      s.burnerStage = "VERIFY " .. side
      local readOK, actual = call(side, c.readPowerMethod)
      if readOK and u.finite(actual) then s.observed[side] = actual end
      assert(readOK and actual == power, "Readback mismatch on " .. side .. ": " .. tostring(actual))
    end
    s.power, s.mismatch, s.ready = power, false, true
    s.burnerStage = "IDLE"
    s.status = "POWER UPDATED"
  end
  function hw.sensorWorker()
    while not s.exit do
      s.heartbeats.sensor = u.now()
      s.attempts = s.attempts + 1
      s.sensorStage = "CALL " .. c.sensorSide .. "." .. c.sensorMethod
      s.sensorBegin = u.now()
      local ok, altitude = call(c.sensorSide, c.sensorMethod)
      local time = u.now()
      s.sensorCallMs = time - s.sensorBegin
      s.sensorStage = "IDLE"
      if ok and u.finite(altitude) then
        s.samples = s.samples + 1
        if s.altitude then
          local delta, dt = altitude - s.altitude, (time - s.sampleAt)/1000
          s.velocity = dt > 0 and delta/dt or 0
          if math.abs(delta) > 0.000001 then s.changeAt = time; s.changes = s.changes+1 end
        else s.changeAt = time; s.velocity = 0 end
        s.altitude, s.sampleAt = altitude, time
      else
        s.failures = s.failures + 1
        s.lastError = "SENSOR: " .. tostring(altitude)
        log.event("sensor_error", s.lastError)
      end
      sleep(c.tickSeconds)
    end
  end
  function hw.burnerWorker()
    -- No retry of an ambiguous partial write; scan/readback only after a failure.
    if not s.initialized then
      hw.scan(); hw.enable(); s.initialized = true
    end
    while not s.exit do
      s.heartbeats.burner = u.now()
      if s.scan then s.scan = false; hw.scan() end
      if s.pending then
        local command = s.pending
        s.pending = nil; s.busy = true
        local ok, err = xpcall(function() hw.apply(command.power) end, u.trace)
        s.busy = false
        if not ok then
          s.ready, s.pending, s.mode = false, nil, "MANUAL"
          s.lastError, s.status = tostring(err), "BURNER ERROR: D to rescan"
          log.event("burner_error", err)
        end
      end
      sleep(0.05)
    end
  end
  return hw
end
return M
