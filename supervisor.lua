local u = require("nexcore.util")
local M = {}
function M.worker(name, body, s, log)
  return function()
    while not s.exit do
      s.heartbeats[name] = u.now()
      local ok, err = xpcall(body, u.trace)
      if s.exit then return end
      s.workerErrors[name] = (s.workerErrors[name] or 0) + 1
      s.lastError = name .. ": " .. (ok and "unexpected worker return" or tostring(err))
      s.status = "WORKER RESTART: " .. name
      log.event("worker_restart", s.lastError)
      -- Wait using raw events so terminate is handled by the UI's explicit exit policy.
      local timer = os.startTimer(1)
      repeat
        local event, id = os.pullEventRaw()
        if event == "terminate" then s.exit = "hands_off"; return end
        if event == "key" and id == keys.q then s.exit = "hands_off"; return end
        if event == "key" and id == keys.x then s.exit = "off"; return end
        if event == "timer" and id == timer then break end
      until s.exit
    end
  end
end
return M
