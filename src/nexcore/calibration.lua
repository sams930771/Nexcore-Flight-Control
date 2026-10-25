local M = {}
function M.altitude(points, power)
  if #points < 2 then return nil end
  local a, b = points[1], points[2]
  if power >= points[#points].power then
    a, b = points[#points - 1], points[#points]
  elseif power > points[1].power then
    for i = 1, #points - 1 do
      if power >= points[i].power and power <= points[i+1].power then
        a, b = points[i], points[i+1]; break
      end
    end
  end
  return a.altitude + (power - a.power) / (b.power - a.power) * (b.altitude - a.altitude)
end
function M.power(c, target)
  local best, distance = c.autoMinPower, math.huge
  for p = c.autoMinPower, c.autoMaxPower do
    local delta = math.abs(M.altitude(c.calibration, p) - target)
    if delta < distance then best, distance = p, delta end
  end
  return best
end
function M.validate(c)
  assert(c.tickSeconds > 0 and c.staleMs > 0, "Invalid timing")
  assert(c.minPower == math.floor(c.minPower) and c.maxPower == math.floor(c.maxPower), "Integer bounds required")
  assert(c.minPower <= c.autoMinPower and c.autoMinPower <= c.autoMaxPower and c.autoMaxPower <= c.maxPower, "Invalid power bounds")
  assert(#c.burnerSides == 2 and c.burnerSides[1] ~= c.burnerSides[2], "Two distinct burners required")
  assert(#c.calibration >= 2, "At least two calibration points required")
  for i, point in ipairs(c.calibration) do
    local u = require("nexcore.util")
    assert(u.finite(point.power) and u.finite(point.altitude), "Invalid calibration number")
    if i > 1 then assert(point.power > c.calibration[i-1].power, "Calibration power must increase") end
  end
end
return M
