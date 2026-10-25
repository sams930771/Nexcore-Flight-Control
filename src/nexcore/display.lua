-- Screenshot restoration. Presentation only: never polls or writes hardware.
local u, cal = require("nexcore.util"), require("nexcore.calibration")
local M = {}
local history = setmetatable({}, {__mode="k"})
local function acceleration(s)
  local p = history[s]
  if not p or (s.sampleAt and p.time and s.sampleAt < p.time) then p={}; history[s]=p end
  if s.sampleAt and s.sampleAt~=p.time then
    local dt=p.time and (s.sampleAt-p.time)/1000
    p.accel=dt and dt>0 and (s.velocity-p.velocity)/dt or nil
    p.time,p.velocity=s.sampleAt,s.velocity
  end
  return p.accel
end
local function clean(text) return tostring(text or "---"):gsub("[\r\n]", " ") end
local function number(n,d) return u.finite(n) and u.fmt(n,d) or "---" end
local function age(t) local n=u.age(t); return n and number(n/1000,1).."s" or "---" end
local function value(label,text,width) return string.format("%-"..(width or 10).."s%s",label,text) end
function M.frame(c,s)
  local accel=acceleration(s)
  local rows, inks={},{}
  for i=1,19 do rows[i]=""; inks[i]=colors.lightGray end
  rows[1]="NEXCORE FLIGHT CONTROL v"..c.version
  rows[2]=string.rep("-",35); inks[2]=colors.gray
  local stale=not s.sampleAt or u.age(s.sampleAt)>c.staleMs
  local phase=s.mode=="GO" and "NAVIGATE" or (s.mode=="HOLD" and "HOLD POWER" or "IDLE")
  if s.busy or s.pending then phase="POWER UPDATE" end
  if not s.ready and not s.busy then phase="CHECK BURNERS" end
  local requested=s.pending and s.pending.power or (not s.busy and s.power or nil)
  local status=clean(s.status)
  if s.logError then status="LOG ERROR - F1 DETAILS"
  elseif s.mismatch then status="BURNER POWER MISMATCH - D SCAN"
  elseif not s.ready then status="BURNER STATE UNVERIFIED - D SCAN"
  elseif stale then status="TELEMETRY STALE - F1 DETAILS" end
  if s.displayPage=="diagnostics" then
    rows[1]="NEXCORE DIAGNOSTICS v"..c.version
    rows[3]="LOOP: "..s.loops.."  MODE: "..s.mode
    rows[4]="SAMPLES: "..s.samples.." TRY: "..s.attempts.." FAIL: "..s.failures
    rows[5]="AGE: "..age(s.sampleAt).."  UNCHANGED: "..age(s.changeAt)
    rows[6]="UI: "..age(s.heartbeats.ui).." SENSOR: "..age(s.heartbeats.sensor).." LOG: "..age(s.heartbeats.telemetry)
    rows[7]="SENSOR: "..clean(s.sensorStage)
    rows[8]="BURNER: "..clean(s.burnerStage)
    rows[9]="ACTUAL: "..clean(s.observed[c.burnerSides[1]]).." / "..clean(s.observed[c.burnerSides[2]]).."  REQ: "..clean(requested)
    rows[10]="CAL ALT: "..number(s.power and cal.altitude(c.calibration,s.power),3).." CALL: "..clean(s.sensorCallMs).."ms"
    rows[11]="RESTART UI/S/B/L: "..(s.workerErrors.ui or 0).."/"..(s.workerErrors.sensor or 0).."/"..(s.workerErrors.burner or 0).."/"..(s.workerErrors.telemetry or 0)
    rows[12]="ERR: "..clean(s.logError or s.lastError)
  else
    rows[3]="MODE: "..s.mode.."  PHASE: "..phase
    rows[4]=value("ALTITUDE:",number(s.altitude,3))
    rows[5]=value("TARGET:",number(s.target,3)); inks[5]=colors.white
    rows[6]=value("ERROR:",number(s.target and s.altitude and s.target-s.altitude,3)); inks[6]=colors.white
    rows[7]=value("VERT SPEED:",number(s.sampleAt and s.velocity,4),12); inks[7]=colors.white
    rows[8]=value("ACCEL:",number(accel,4),12); inks[8]=colors.white
    -- No braking model exists in the preserved backend. Do not pass off a
    -- calibrated equilibrium altitude as a predicted stopping position.
    rows[9]=value("STOP Y:","---",12); inks[9]=colors.white
    rows[10]="POWER: "..clean(s.power).."  REQUEST: "..clean(requested); inks[10]=colors.white
    rows[11]="SENSOR: "..(stale and "STALE" or "ONLINE").."  AGE: "..age(s.sampleAt).."  N: "..s.samples
    rows[12]="STATUS: "..status
  end
  rows[13]=string.rep("-",35); inks[13]=colors.gray
  rows[14]="T=TARGET  G=GO  H=HOLD  M=MANUAL"
  rows[15]="+/-=POWER  D=SCAN  F1="..(s.displayPage=="diagnostics" and "MAIN" or "DIAG")
  rows[16]="Q=QUIT  X=BURNERS OFF"
  rows[17]=string.rep("-",35); inks[17]=colors.gray
  rows[18]=s.editing and ("TARGET Y: "..s.input.."_") or "TARGET ENTRY: PRESS T"
  if s.logError then rows[19]="FLIGHT LOG ERROR - F1 DETAILS"
  elseif s.lastError~="NONE" then rows[19]="LAST ERROR - F1 DETAILS"
  elseif s.heartbeats.telemetry and u.age(s.heartbeats.telemetry)>2500 then rows[19]="FLIGHT LOG STALE - F1 DETAILS"
  else rows[19]=s.heartbeats.telemetry and "FLIGHT LOG ACTIVE" or "FLIGHT LOG STARTING" end
  inks[19]=colors.gray
  if s.editing then rows[19]="ENTER=SET ESC=CANCEL | F1=DIAG Q=QUIT X=OFF" end
  return rows,inks
end
function M.draw(c,s)
  local w,h=term.getSize()
  local rows,inks=M.frame(c,s)
  term.setBackgroundColor(colors.black); term.setCursorBlink(false)
  for y=1,h do
    term.setTextColor(inks[y] or colors.lightGray)
    term.setCursorPos(1,y); term.clearLine(); term.write((rows[y] or ""):sub(1,w))
  end
  s.renderAt=u.now()
end
return M
