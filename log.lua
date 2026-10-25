local M = {}
function M.new(root, c, state)
  local directory = fs.combine(root, "logs")
  local logger = {}
  local function write(name, message)
    local ok, err = pcall(function()
      fs.makeDir(directory)
      local path = fs.combine(directory, name)
      if fs.exists(path) and fs.getSize(path) >= c.logMaxBytes then
        local oldest = path .. "." .. c.logBackups
        if fs.exists(oldest) then fs.delete(oldest) end
        for i = c.logBackups - 1, 1, -1 do
          if fs.exists(path .. "." .. i) then fs.move(path .. "." .. i, path .. "." .. (i+1)) end
        end
        fs.move(path, path .. ".1")
      end
      local file, reason = fs.open(path, "a")
      assert(file, reason or "Cannot open log")
      local written, failure = pcall(function() file.writeLine(message) end)
      file.close()
      assert(written, failure)
    end)
    if not ok then state.logError = tostring(err) end
  end
  function logger.event(kind, detail)
    -- One flushed line per boundary survives a later blocked peripheral call.
    write("events.jsonl", textutils.serializeJSON({time=os.epoch("utc"), kind=kind, detail=tostring(detail or "")}))
  end
  function logger.sample()
    local u = require("nexcore.util")
    write("telemetry.jsonl", textutils.serializeJSON({time=u.now(), mode=state.mode,
      altitude=state.altitude, velocity=state.velocity, target=state.target, power=state.power,
      observed=state.observed,
      loops=state.loops, attempts=state.attempts, samples=state.samples, failures=state.failures,
      sensorAge=u.age(state.sampleAt), unchangedAge=u.age(state.changeAt),
      sensorStage=state.sensorStage, burnerStage=state.burnerStage,
      sensorCallMs=state.sensorCallMs, renderAt=state.renderAt, heartbeats=state.heartbeats,
      workerErrors=state.workerErrors, pending=state.pending and state.pending.power,
      status=state.status, error=state.lastError, logError=state.logError}))
  end
  return logger
end
return M
