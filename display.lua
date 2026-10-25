local u, cal = require("nexcore.util"), require("nexcore.calibration")
local M = {}
function M.draw(c, s)
  local w, h = term.getSize()
  term.setBackgroundColor(colors.black); term.setTextColor(colors.white)
  term.setCursorBlink(false)
  local rows = {
    "NEXCORE FLIGHT CONTROL " .. c.version,
    "MODE: " .. s.mode .. "  POWER: " .. tostring(s.power or "---"),
    "ALTITUDE: " .. u.fmt(s.altitude,4) .. "  V/S: " .. u.fmt(s.velocity,4),
    "TARGET: " .. u.fmt(s.target,2),
    "PREDICTED: " .. u.fmt(s.power and cal.altitude(c.calibration,s.power),2),
    "LOOP: " .. s.loops .. "  SAMPLES: " .. s.samples,
    "ATTEMPTS: " .. s.attempts .. "  FAILURES: " .. s.failures,
    "SENSOR AGE: " .. u.fmt((u.age(s.sampleAt) or -1000)/1000,1) .. "s",
    "UNCHANGED: " .. u.fmt((u.age(s.changeAt) or -1000)/1000,1) .. "s",
    "SENSOR: " .. s.sensorStage,
    "BURNER: " .. s.burnerStage,
    "STATUS: " .. s.status,
  }
  if not s.ready then rows[2] = rows[2] .. " UNVERIFIED" end
  if not s.sampleAt or u.age(s.sampleAt) > c.staleMs then rows[8] = rows[8] .. " STALE" end
  if s.mismatch then rows[11] = "POWER MISMATCH: D scan, +/- sync" end
  if s.lastError ~= "NONE" then rows[12] = "ERR: " .. s.lastError:gsub("[\r\n]", " ") end
  if s.logError then rows[12] = "LOG ERROR: " .. s.logError end
  -- Footer is anchored to keep bindings visible on the standard 51x19 computer.
  for y = 1, h do
    local text = y <= h-3 and (rows[y] or "") or ""
    if y == h-2 then text = "T Target G Go H Hold M Manual" end
    if y == h-1 then text = "+/- Power D Scan Q Exit X Burners OFF" end
    if y == h then text = s.editing and ("Target Y: " .. s.input .. "_") or ("SENSOR " .. tostring(s.samples) .. " | " .. s.status) end
    term.setCursorPos(1,y); term.clearLine(); term.write(text:sub(1,w))
  end
  s.renderAt = u.now()
end
return M
