local harness=require("cc_mock")
local display=require("nexcore.display")
local c=dofile("config/default.lua")
local m=harness.setup()
m.time=10
local s={mode="GO",power=39,target=154.662,altitude=152.662,velocity=0,
  sampleAt=10000,changeAt=9000,ready=true,status="AUTOPILOT ENGAGED",lastError="NONE",
  samples=40,attempts=40,failures=0,loops=40,sensorStage="IDLE",burnerStage="IDLE",
  observed={left=39,right=39},heartbeats={ui=10000,sensor=10000,telemetry=10000},workerErrors={}}
local rows=display.frame(c,s)
assert(rows[1]=="NEXCORE FLIGHT CONTROL v3.5.3")
assert(rows[3]=="MODE: GO  PHASE: NAVIGATE")
assert(rows[4]=="ALTITUDE: 152.662" and rows[5]=="TARGET:   154.662")
assert(rows[6]=="ERROR:    2.000" and rows[7]=="VERT SPEED: 0.0000")
assert(rows[9]=="STOP Y:     ---")
assert(rows[14]=="T=TARGET  G=GO  H=HOLD  M=MANUAL")
assert(rows[16]=="Q=QUIT  X=BURNERS OFF" and rows[18]=="TARGET ENTRY: PRESS T")
print("PASS original screenshot row/label/value alignment")
local drawCount=0
term.getSize=function() return 51,19 end
term.setCursorPos=function(x,y) assert(x>=1 and x<=51 and y>=1 and y<=19) end
term.write=function(t) assert(#t<=51); drawCount=drawCount+1 end
-- Presentation must not consume any event or touch any peripheral.
os.pullEvent=function() error("Display attempted event pull") end
os.pullEventRaw=os.pullEvent
peripheral.call=function() error("Display touched hardware") end
for _,page in ipairs({"main","diagnostics"}) do
  s.displayPage=page
  for _,mode in ipairs({"MANUAL","GO","HOLD"}) do
    s.mode=mode
    local frame=display.frame(c,s)
    for _,row in ipairs(frame) do assert(#row<=51,"Default frame overflow: "..row) end
    display.draw(c,s)
  end
end
assert(drawCount==114)
print("PASS both pages and all modes fit 51x19 without event/peripheral calls")
m.time=14
rows=display.frame(c,s)
s.displayPage="main"
rows=display.frame(c,s)
assert(rows[11]:find("STALE") and rows[12]:find("TELEMETRY STALE"))
s.editing=true; s.input=string.rep("1",24)
rows=display.frame(c,s)
assert(#rows[18]<=51 and #rows[19]<=51 and rows[19]:find("ESC=CANCEL"))
print("PASS stale warning and maximum-length target editor remain visible")
s.editing=false; s.sampleAt=14000; s.velocity=0.2
display.frame(c,s)
m.time=14.25; s.sampleAt=14250; s.velocity=0.3
rows=display.frame(c,s)
assert(rows[8]:find("0.4000",1,true))
assert(display.frame(c,s)[8]==rows[8],"Redraw changed derived acceleration")
print("PASS display-only acceleration uses observed sample time, not redraw count")
local mock=harness.setup()
local control=require("nexcore.control").new(c,s,{event=function() end})
s.editing=true; s.input="180"; s.displayPage="main"
control.key(keys.f1); assert(s.displayPage=="diagnostics" and s.editing and s.input=="180")
control.key(keys.f1); assert(s.displayPage=="main")
print("PASS F1 toggles only presentation while target entry remains active")
-- Full app event regression: page changes do not interrupt samples/target input.
mock=harness.setup()
mock.event(.3,"key",keys.t); mock.event(.4,"paste","176.489")
mock.event(.5,"key",keys.f1); mock.event(1.5,"key",keys.f1)
mock.event(2,"key",keys.enter); mock.event(2.5,"key",keys.q)
local final=require("nexcore.app").run("mock",c)
assert(final.target==176.489 and final.samples>=9 and final.loops>=9)
assert(final.exit=="hands_off" and mock.outputs.left and mock.outputs.right)
print("PASS F1/target input under live workers retains telemetry and Q behavior")
