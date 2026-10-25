return {
  version = "3.5.3",
  sensorSide = "back", sensorMethod = "getHeight",
  burnerSides = { "left", "right" },
  readPowerMethod = "getScrollValue", writePowerMethod = "setScrollValue",
  tickSeconds = 0.25, staleMs = 2000,
  minPower = 0, maxPower = 500, autoMinPower = 38, autoMaxPower = 48,
  targetTolerance = 0.35,
  logMaxBytes = 262144, logBackups = 3,
  calibration = {
    { power = 39, altitude = 146.3424 },
    { power = 42, altitude = 164.8510 },
    { power = 43, altitude = 170.7356 },
    { power = 44, altitude = 176.4890 },
    { power = 46, altitude = 187.6230 },
    { power = 47, altitude = 193.0140 },
  },
}
