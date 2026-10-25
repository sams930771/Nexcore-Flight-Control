-- Copy to config/local.lua only when overrides are needed. Installer preserves local.lua.
return {
  sensorSide = "back", sensorMethod = "getHeight",
  burnerSides = {"left", "right"},
  -- Keep the original six calibration points unless this ship is recalibrated.
}
