local M = {}
function M.now() return os.epoch("utc") end
function M.finite(n)
  return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end
function M.clamp(n, lo, hi) return math.max(lo, math.min(hi, n)) end
function M.age(t) return t and math.max(0, M.now() - t) or nil end
function M.fmt(n, d) return n and string.format("%." .. d .. "f", n) or "---" end
function M.trace(e) return debug and debug.traceback and debug.traceback(tostring(e), 2) or tostring(e) end
return M
